//
//  ContentView.swift
//  Clipo
//
//  Created by Devin on 10.08.25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var clipboardManager = ClipboardManager.shared
    @State private var selectedItems = Set<ClipboardItem.ID>()
    @State private var searchText = ""
    @ObservedObject private var appState = AppState.shared
    @State private var showSettingsSheet = false
    @State private var showAddCategorySheet = false
    @State private var showEditSheet = false
    @State private var itemToEdit: ClipboardItem?
    @State private var editText = ""
    @State private var newCategoryName = ""
    @State private var sidebarWidth: CGFloat = 280
    
    var body: some View {
        HSplitView {
            // Modern Sidebar
            modernSidebar
                .frame(minWidth: 240, idealWidth: sidebarWidth, maxWidth: 320)
            
            // Enhanced Main Content
            modernMainContent
                .frame(minWidth: 500)
        }
        .frame(minWidth: 900, minHeight: 650)
        .background(
            LinearGradient(
                colors: [Color(NSColor.windowBackgroundColor), Color(NSColor.controlBackgroundColor).opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onReceive(appState.$openSettingsFromPopover) { open in
            if open {
                showSettingsSheet = true
                appState.openSettingsFromPopover = false
            }
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsView()
        }
        .sheet(isPresented: $showAddCategorySheet) {
            modernAddCategorySheet
        }
        .sheet(isPresented: $showEditSheet) {
            editItemSheet
        }
    }
    
    private var modernSidebar: some View {
        VStack(spacing: 0) {
            // Enhanced Header
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.on.clipboard.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 24, weight: .semibold))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Clipo")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        Text("Clipboard Manager")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Quick Stats Cards
                HStack(spacing: 8) {
                    quickStatCard(
                        title: "Items",
                        value: "\(clipboardManager.items.count)",
                        icon: "doc.on.doc",
                        color: .blue
                    )
                    
                    quickStatCard(
                        title: "Favorites",
                        value: "\(clipboardManager.favoriteItems.count)",
                        icon: "star.fill",
                        color: .yellow
                    )
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color(NSColor.windowBackgroundColor), Color(NSColor.controlBackgroundColor).opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Enhanced Categories Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Categories")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: { showAddCategorySheet = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(width: 20, height: 20)
                            .background(
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Add Category")
                }
                
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(clipboardManager.categories, id: \.self) { category in
                            modernCategoryRow(category: category)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .padding(20)
            
            // Enhanced Monitoring Status
            VStack(spacing: 12) {
                Divider()
                
                HStack(spacing: 12) {
                    Circle()
                        .fill(clipboardManager.isMonitoringEnabled ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                        .shadow(color: clipboardManager.isMonitoringEnabled ? .green.opacity(0.5) : .red.opacity(0.5), radius: 2, x: 0, y: 0)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(clipboardManager.isMonitoringEnabled ? "Monitoring Active" : "Monitoring Paused")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("Clipboard tracking is \(clipboardManager.isMonitoringEnabled ? "enabled" : "disabled")")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
    }
                    
    private var modernMainContent: some View {
        VStack(spacing: 0) {
            // Enhanced Header Bar
            HStack(spacing: 16) {
                // Advanced Search
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                    
                    TextField("Search your clipboard history...", text: $clipboardManager.searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 14))
                    
                    if !clipboardManager.searchText.isEmpty {
                        Button(action: { clipboardManager.searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                )
                
                Spacer()
                
                // Modern Action Buttons
                HStack(spacing: 8) {
                    modernActionButton(
                        icon: clipboardManager.isMonitoringEnabled ? "pause.circle.fill" : "play.circle.fill",
                        color: clipboardManager.isMonitoringEnabled ? .orange : .green,
                        help: clipboardManager.isMonitoringEnabled ? "Pause monitoring" : "Resume monitoring"
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            clipboardManager.isMonitoringEnabled.toggle()
                        }
                    }
                    
                    modernActionButton(
                        icon: "plus.circle.fill",
                        color: .blue,
                        help: "Add item"
                    ) {
                        clipboardManager.addTextItem("")
                    }
                    
                    modernActionButton(
                        icon: "trash.circle.fill",
                        color: .red,
                        help: "Clear all history"
                    ) {
                        clipboardManager.clearHistory()
                    }
                    
                    modernActionButton(
                        icon: "gearshape.fill",
                        color: .secondary,
                        help: "Settings"
                    ) {
                        showSettingsSheet = true
                    }
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color(NSColor.windowBackgroundColor), Color(NSColor.controlBackgroundColor).opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Enhanced Content Area
            if clipboardManager.filteredItems.isEmpty {
                modernEmptyState
            } else {
                modernItemsList
            }
        }
    }
    
    private var modernEmptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(.secondary.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(clipboardManager.searchText.isEmpty ? "Your Clipboard is Empty" : "No Results Found")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(clipboardManager.searchText.isEmpty ? 
                     "Copy something to see it appear here instantly" : 
                     "Try adjusting your search terms or check your filters")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if clipboardManager.searchText.isEmpty {
                HStack(spacing: 16) {
                    Button("Enable Monitoring") {
                        clipboardManager.isMonitoringEnabled = true
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(clipboardManager.isMonitoringEnabled)
                    
                    Button("Open Settings") {
                        showSettingsSheet = true
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }
    
    private var modernItemsList: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 8) {
                ForEach(clipboardManager.filteredItems) { item in
                    EnhancedClipboardItemRow(
                        item: item,
                        isSelected: selectedItems.contains(item.id),
                        onEdit: { item in
                            showEditSheet = true
                            itemToEdit = item
                        }
                    )
                    .onTapGesture {
                        if selectedItems.contains(item.id) {
                            selectedItems.remove(item.id)
                        } else {
                            selectedItems.insert(item.id)
                        }
                    }
                    .onTapGesture(count: 2) {
                        clipboardManager.copyItem(item)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
    }
    
    private var modernAddCategorySheet: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                
                Text("Create New Category")
                    .font(.system(size: 18, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Category Name")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("Enter category name...", text: $newCategoryName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 300)
            }
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    showAddCategorySheet = false
                    newCategoryName = ""
                }
                .buttonStyle(.bordered)
                
                Button("Create Category") {
                    clipboardManager.addCategory(newCategoryName)
                    newCategoryName = ""
                    showAddCategorySheet = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(30)
        .frame(minWidth: 400)
    }
    
    private var editItemSheet: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "pencil.circle")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                
                Text("Edit Clipboard Item")
                    .font(.system(size: 18, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Content")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                if itemToEdit?.type == .text {
                    TextEditor(text: $editText)
                        .frame(width: 450, height: 200)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                        )
                } else {
                    TextField("Content", text: $editText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 450)
                }
            }
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    showEditSheet = false
                    editText = ""
                    itemToEdit = nil
                }
                .buttonStyle(.bordered)
                
                Button("Save Changes") {
                    if let item = itemToEdit, !editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        clipboardManager.updateItem(item, newContent: editText)
                    }
                    showEditSheet = false
                    editText = ""
                    itemToEdit = nil
                }
                .buttonStyle(.borderedProminent)
                .disabled(editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(30)
        .frame(minWidth: 500)
        .onAppear {
            editText = itemToEdit?.content ?? ""
        }
    }
    
    // MARK: - Helper Functions
    
    private func quickStatCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func modernCategoryRow(category: String) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                clipboardManager.selectedCategory = category
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: category == "All" ? "tray.full" : category == "Favorites" ? "star.fill" : "folder.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(clipboardManager.selectedCategory == category ? .white : .secondary)
                    .frame(width: 20)
                
                Text(category)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(clipboardManager.selectedCategory == category ? .white : .primary)
                
                Spacer()
                
                let count = category == "All" ? clipboardManager.items.count : 
                           category == "Favorites" ? clipboardManager.favoriteItems.count :
                           clipboardManager.items.filter { $0.category == category }.count
                
                Text("\(count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(clipboardManager.selectedCategory == category ? .white.opacity(0.8) : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(clipboardManager.selectedCategory == category ? 
                                  Color.white.opacity(0.2) : 
                                  Color.secondary.opacity(0.15))
                    )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(clipboardManager.selectedCategory == category ? 
                          LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                          LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom))
                    .shadow(color: clipboardManager.selectedCategory == category ? .blue.opacity(0.3) : .clear, radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            if clipboardManager.userCategories.contains(category) {
                Button("Delete Category", role: .destructive) {
                    clipboardManager.removeCategory(category)
                }
            }
        }
        .scaleEffect(clipboardManager.selectedCategory == category ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: clipboardManager.selectedCategory)
    }
    
    private func modernActionButton(icon: String, color: Color, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                        .overlay(
                            Circle()
                                .stroke(color.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .help(help)
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: color)
    }
}

struct EnhancedClipboardItemRow: View {
    let item: ClipboardItem
    let isSelected: Bool
    let onEdit: (ClipboardItem) -> Void
    @ObservedObject private var clipboardManager = ClipboardManager.shared
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Enhanced Type Indicator
            VStack(spacing: 4) {
                Image(systemName: item.type.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(item.type.color)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(item.type.color.opacity(0.1))
                            .overlay(
                                Circle()
                                    .stroke(item.type.color.opacity(0.3), lineWidth: 1.5)
                            )
                    )
                
                Text(item.type.displayName)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            // Enhanced Content
            VStack(alignment: .leading, spacing: 8) {
                // Header Row
                HStack {
                    Text(item.displayTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        if item.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.yellow)
                        }
                        
                        Text(item.timeAgo)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.secondary.opacity(0.1))
                            )
                    }
                }
                
                // Content Preview
                Group {
                    if item.type == .image {
                        // Show image thumbnail if available
                        if let nsImage = loadImage(from: item.content) {
                            HStack {
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 70)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Image")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    if let size = getImageSize(from: item.content) {
                                        Text("\(Int(size.width)) × \(Int(size.height)) pixels")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                            }
                        } else {
                            Text(item.preview)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                        }
                    } else {
                        Text(item.preview)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                // Footer Row
                HStack {
                    // Category Tag
                    if item.category != "General" {
                        Text(item.category)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .blue.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                    }
                    
                    // App Name
                    if let appName = item.applicationName {
                        HStack(spacing: 4) {
                            Image(systemName: "app")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                            
                            Text(appName)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.secondary.opacity(0.1))
                        )
                    }
                    
                    Spacer()
                    
                    // Quick Actions (visible on hover)
                    if isHovered {
                        HStack(spacing: 6) {
                            quickActionButton(
                                icon: "doc.on.doc",
                                color: .blue,
                                help: "Copy to clipboard"
                            ) {
                                clipboardManager.copyItem(item)
                            }
                            
                            quickActionButton(
                                icon: item.isFavorite ? "star.fill" : "star",
                                color: .yellow,
                                help: item.isFavorite ? "Remove from favorites" : "Add to favorites"
                            ) {
                                clipboardManager.toggleFavorite(item)
                            }
                            
                            quickActionButton(
                                icon: "pencil",
                                color: .blue,
                                help: "Edit item"
                            ) {
                                onEdit(item)
                            }
                            
                            quickActionButton(
                                icon: "trash",
                                color: .red,
                                help: "Delete item"
                            ) {
                                clipboardManager.deleteItem(item)
                            }
                        }
                        .transition(.opacity.combined(with: .scale))
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isSelected ? 
                    LinearGradient(colors: [.blue.opacity(0.1), .blue.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                    LinearGradient(colors: [Color(NSColor.controlBackgroundColor), Color(NSColor.controlBackgroundColor).opacity(0.7)], startPoint: .top, endPoint: .bottom)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected ? .blue.opacity(0.3) : .secondary.opacity(0.2),
                            lineWidth: isSelected ? 1.5 : 1
                        )
                )
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            contextMenuItems
        }
    }
    
    private func quickActionButton(icon: String, color: Color, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                        .overlay(
                            Circle()
                                .stroke(color.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .help(help)
    }
    
    private var contextMenuItems: some View {
        Group {
            Button("Copy") {
                clipboardManager.copyItem(item)
            }
            
            Divider()
            
            Menu("Move to Category") {
                ForEach(clipboardManager.categories.filter { $0 != "All" && $0 != "Favorites" }, id: \.self) { category in
                    Button(category) {
                        clipboardManager.updateItemCategory(item, category: category)
                    }
                }
            }
            
            Divider()
            
            Button(item.isFavorite ? "Remove from Favorites" : "Add to Favorites") {
                clipboardManager.toggleFavorite(item)
            }
            
            Button("Delete", role: .destructive) {
                clipboardManager.deleteItem(item)
            }
        }
    }
    
    private func loadImage(from content: String) -> NSImage? {
        guard let data = Data(base64Encoded: content) else { return nil }
        return NSImage(data: data)
    }
    
    private func getImageSize(from content: String) -> NSSize? {
        guard let nsImage = loadImage(from: content) else { return nil }
        return nsImage.size
    }
}

// MARK: - ClipboardItem Type Extensions

extension ClipboardItemType {
    var displayName: String {
        switch self {
        case .text: return "Text"
        case .image: return "Image"
        case .url: return "Link"
        case .file: return "File"
        }
    }
}

struct ClipboardItemRowView: View {
    let item: ClipboardItem
    @ObservedObject private var clipboardManager = ClipboardManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Type indicator
            Image(systemName: item.type.icon)
                .foregroundColor(item.type.color)
                .font(.title3)
                .frame(width: 24, height: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.displayTitle)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if item.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                    
                    Text(item.timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(item.preview)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                HStack {
                    if item.category != "General" {
                        Text(item.category)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    if let appName = item.applicationName {
                        Text(appName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 8)
        .contextMenu {
            Button("Copy") {
                clipboardManager.copyItem(item)
            }
            
            Divider()
            
            Menu("Move to Category") {
                ForEach(clipboardManager.categories.filter { $0 != "All" }, id: \.self) { cat in
                    Button(cat) {
                        clipboardManager.updateItemCategory(item, category: cat)
                    }
                }
            }
            
            Divider()
            
            Button(item.isFavorite ? "Remove from Favorites" : "Add to Favorites") {
                clipboardManager.toggleFavorite(item)
            }
            
            Button("Delete", role: .destructive) {
                clipboardManager.deleteItem(item)
            }
        }
        .onTapGesture(count: 2) {
            clipboardManager.copyItem(item)
        }
    }
}

#Preview {
    ContentView()
}
