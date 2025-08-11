//
//  ClipboardManager.swift
//  Clipo
//
//  Created by Devin on 10.08.25.
//

import Foundation
import AppKit
import SwiftUI
import Combine
import UserNotifications

class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    
    @Published var items: [ClipboardItem] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: String = "All"
    
    // User-defined categories (in addition to implicit categories on items)
    @Published var userCategories: [String] = []
    
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let pasteboard = NSPasteboard.general
    
    // Settings
    @Published var isMonitoringEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isMonitoringEnabled, forKey: "isMonitoringEnabled")
            if isMonitoringEnabled {
                startMonitoring()
            } else {
                stopMonitoring()
            }
        }
    }
    
    @Published var playSound: Bool = false {
        didSet {
            UserDefaults.standard.set(playSound, forKey: "playSound")
        }
    }
    
    @Published var showNotifications: Bool = true {
        didSet {
            UserDefaults.standard.set(showNotifications, forKey: "showNotifications")
        }
    }
    
    var categories: [String] {
        // Merge built-ins, user categories, and categories inferred from items
        var set = Set<String>()
        set.insert("General")
        set.insert("Favorites") // Add Favorites as a built-in category
        userCategories.forEach { set.insert($0) }
        items.map { $0.category }.forEach { set.insert($0) }
        let list = Array(set).sorted()
        return ["All"] + list
    }
    
    var filteredItems: [ClipboardItem] {
        var filtered = items
        
        // Filter by category
        if selectedCategory != "All" {
            if selectedCategory == "Favorites" {
                filtered = filtered.filter { $0.isFavorite }
            } else {
                filtered = filtered.filter { $0.category == selectedCategory }
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.content.localizedCaseInsensitiveContains(searchText) ||
                item.preview.localizedCaseInsensitiveContains(searchText) ||
                item.displayTitle.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    var favoriteItems: [ClipboardItem] {
        return items.filter { $0.isFavorite }
    }
    
    private let thumbnailsFolder: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Clipo", isDirectory: true)
            .appendingPathComponent("Images", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()
    
    private init() {
        print("ClipboardManager: Initializing...")
        loadSettings()
        loadPersistedItems()
        
        // Add some test data if no items exist
        if items.isEmpty {
            print("ClipboardManager: Adding test data...")
            let testItem1 = ClipboardItem(content: "Welcome to Clipo! This is a test clipboard item.", type: .text)
            let testItem2 = ClipboardItem(content: "Copy something and it will appear here automatically", type: .text)
            items = [testItem1, testItem2]
            print("ClipboardManager: Added \(items.count) test items")
        }
        
        if isMonitoringEnabled {
            startMonitoring()
        }
        print("ClipboardManager: Initialization complete with \(items.count) items")
    }
    
    private func loadSettings() {
        isMonitoringEnabled = UserDefaults.standard.object(forKey: "isMonitoringEnabled") as? Bool ?? true
        playSound = UserDefaults.standard.object(forKey: "playSound") as? Bool ?? false
        showNotifications = UserDefaults.standard.object(forKey: "showNotifications") as? Bool ?? true
        // Load user categories
        if let data = UserDefaults.standard.array(forKey: "userCategories") as? [String] {
            userCategories = data
        }
    }
    
    func startMonitoring() {
        guard isMonitoringEnabled else { return }
        
        lastChangeCount = pasteboard.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForClipboardChanges()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkForClipboardChanges() {
        // Do not process clipboard at all while paused
        guard isMonitoringEnabled else { return }
        guard pasteboard.changeCount != lastChangeCount else { return }
        
        lastChangeCount = pasteboard.changeCount
        processClipboardContent()
    }
    
    private func processClipboardContent() {
        // Extra safety: ignore processing if paused
        guard isMonitoringEnabled else { return }
        
        let runningApp = NSWorkspace.shared.frontmostApplication
        let appName = runningApp?.localizedName
        
        // Check for different types of content
        if let string = pasteboard.string(forType: .string), !string.isEmpty {
            let type: ClipboardItemType
            
            if string.hasPrefix("http://") || string.hasPrefix("https://") || string.contains("://") {
                type = .url
            } else if string.contains("/") && FileManager.default.fileExists(atPath: string) {
                type = .file
            } else {
                type = .text
            }
            
            addItem(ClipboardItem(content: string, type: type, applicationName: appName))
            
        } else if pasteboard.types?.contains(.tiff) == true || pasteboard.types?.contains(.png) == true {
            // Handle images: persist to disk and store file URL
            if let data = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff) {
                let id = UUID().uuidString
                let ext = pasteboard.data(forType: .png) != nil ? "png" : "tiff"
                let fileURL = thumbnailsFolder.appendingPathComponent("\(id).\(ext)")
                do {
                    try data.write(to: fileURL, options: .atomic)
                    addItem(ClipboardItem(content: fileURL.path, type: .image, applicationName: appName))
                } catch {
                    print("Failed to write image: \(error)")
                }
            }
        } else if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            // Handle file URLs
            let filePaths = fileURLs.map { $0.path }.joined(separator: "\n")
            addItem(ClipboardItem(content: filePaths, type: .file, applicationName: appName))
        }
    }
    
    private func addItem(_ item: ClipboardItem) {
        // Avoid duplicates of the most recent item
        if let lastItem = items.first, lastItem.content == item.content && lastItem.type == item.type {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.items.insert(item, at: 0)
            
            // Play sound if enabled
            if self.playSound {
                NSSound.beep()
            }
            
            // Show notification if enabled
            if self.showNotifications {
                self.showNotification(for: item)
            }
            
            // Persist items
            self.persistItems()
        }
    }
    
    func addTextItem(_ text: String, category: String = "General") {
        var item = ClipboardItem(content: text, type: .text, applicationName: "Clipo")
        item.category = category
        addItem(item)
    }
    
    // MARK: - Categories API
    func addCategory(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !userCategories.contains(trimmed) && trimmed != "All" && trimmed != "General" else { return }
        userCategories.append(trimmed)
        userCategories.sort()
        UserDefaults.standard.set(userCategories, forKey: "userCategories")
        
        // If currently filtering by a category that was removed elsewhere, ensure it's valid
        if selectedCategory == "All" { return }
        if !categories.contains(selectedCategory) {
            selectedCategory = "All"
        }
    }
    
    func removeCategory(_ name: String) {
        userCategories.removeAll { $0 == name }
        UserDefaults.standard.set(userCategories, forKey: "userCategories")
        
        // Reassign items with this category back to General
        for idx in items.indices {
            if items[idx].category == name {
                items[idx].category = "General"
            }
        }
        persistItems()
        
        if selectedCategory == name { selectedCategory = "All" }
    }
    
    private func showNotification(for item: ClipboardItem) {
        let content = UNMutableNotificationContent()
        content.title = "Clipboard Item Copied"
        content.body = item.preview
        content.sound = nil // We handle sound separately
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error delivering notification: \(error)")
            }
        }
    }
    
    func copyItem(_ item: ClipboardItem) {
        switch item.type {
        case .text, .url, .file:
            pasteboard.clearContents()
            pasteboard.setString(item.content, forType: .string)
        case .image:
            pasteboard.clearContents()
            let url = URL(fileURLWithPath: item.content)
            if let data = try? Data(contentsOf: url) {
                if url.pathExtension.lowercased() == "png" {
                    pasteboard.setData(data, forType: .png)
                } else {
                    pasteboard.setData(data, forType: .tiff)
                }
            }
        }
    }
    
    func toggleFavorite(_ item: ClipboardItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isFavorite.toggle()
            persistItems()
        }
    }
    
    func deleteItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        persistItems()
    }
    
    func updateItemCategory(_ item: ClipboardItem, category: String) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].category = category
            persistItems()
        }
    }
    
    func updateItem(_ item: ClipboardItem, newContent: String) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].updateContent(newContent)
            persistItems()
        }
    }
    
    func clearHistory() {
        items.removeAll()
        persistItems()
    }
    
    func clearOldItems() {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        items.removeAll { $0.timestamp < thirtyDaysAgo && !$0.isFavorite }
        persistItems()
    }
    
    // MARK: - Persistence
    
    private func persistItems() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: "clipboardItems")
        } catch {
            print("Failed to persist clipboard items: \(error)")
        }
    }
    
    private func loadPersistedItems() {
        guard let data = UserDefaults.standard.data(forKey: "clipboardItems") else { return }
        
        do {
            items = try JSONDecoder().decode([ClipboardItem].self, from: data)
        } catch {
            print("Failed to load persisted clipboard items: \(error)")
        }
    }
    
    func refreshItems() {
        print("🔄 Refreshing clipboard items...")
        checkForClipboardChanges() // Force a clipboard check
        print("📊 Current items count: \(items.count)")
        for (index, item) in items.enumerated() {
            print("  \(index + 1). \(item.preview.prefix(50))")
        }
    }
}
