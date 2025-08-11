//
//  MenuBarContentView.swift
//  Clipo
//
//  Created by Devin on 10.08.25.
//

import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject private var clipboardManager = ClipboardManager.shared
    @State private var selectedTab: Tab = .history
    @State private var showingSettings = false
    @ObservedObject private var appState = AppState.shared
    
    enum Tab: String, CaseIterable {
        case history = "History"
        case favorites = "Favorites"
        case categories = "Categories"
        
        var icon: String {
            switch self {
            case .history: return "clock"
            case .favorites: return "star"
            case .categories: return "folder"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            // Tab bar
            tabBar
            
            // Content
            content
            
            // Footer
            footer
        }
        .frame(width: 400, height: 600)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .focusable()
        .onAppear {
            // Ensure the window becomes key and first responder for proper event handling
            DispatchQueue.main.async {
                if let window = NSApplication.shared.windows.first(where: { String(describing: type(of: $0)).contains("NSPopover") }) {
                    window.makeKey()
                    window.makeFirstResponder(window.contentView)
                }
            }
        }
        .onKeyPress(.escape) {
            // Close popover on Escape
            if let popoverWindow = NSApplication.shared.windows.first(where: { String(describing: type(of: $0)).contains("NSPopover") }) {
                popoverWindow.orderOut(nil)
            } else if let firstVisible = NSApplication.shared.windows.first(where: { $0.isVisible }) {
                firstVisible.orderOut(nil)
            }
            return .handled
        }
    }
    
    private var header: some View {
        HStack(spacing: 12) {
            // App icon and title
            HStack(spacing: 10) {
                Image(systemName: "doc.on.clipboard")
                    .foregroundColor(.blue)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Clipo")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("by Velyzo")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 6) {
                // Main window button
                Button(action: {
                    // Signal the app to show the main window
                    appState.openSettingsFromPopover = true
                }) {
                    Image(systemName: "macwindow")
                        .foregroundColor(.blue)
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .help("Open Main Window")
                
                // Settings button
                Button(action: {
                    // Signal the app to show settings in the main window
                    appState.openSettingsFromPopover = true
                }) {
                    Image(systemName: "gearshape")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.secondary.opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .help("Settings")
                
                // Close button
                Button(action: {
                    // Close the popover explicitly
                    if let popoverWindow = NSApplication.shared.windows.first(where: { String(describing: type(of: $0)).contains("NSPopover") }) {
                        popoverWindow.orderOut(nil)
                    }
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.secondary.opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .help("Close")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color(NSColor.windowBackgroundColor), Color(NSColor.controlBackgroundColor)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 12, weight: .medium))
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(selectedTab == tab ? .white : .secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedTab == tab ? 
                                LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .top, endPoint: .bottom) :
                                LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom)
                            )
                            .shadow(color: selectedTab == tab ? .blue.opacity(0.3) : .clear, radius: 2, x: 0, y: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(selectedTab == tab ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: selectedTab)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
    
    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .history:
            historyView
        case .favorites:
            favoritesView
        case .categories:
            categoriesView
        }
    }
    
    private var historyView: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
                
                TextField("Search clipboard history...", text: $clipboardManager.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !clipboardManager.searchText.isEmpty {
                    Button(action: { clipboardManager.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Items list
            if clipboardManager.filteredItems.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(clipboardManager.filteredItems) { item in
                            ClipboardItemView(item: item)
                            
                            if item.id != clipboardManager.filteredItems.last?.id {
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var favoritesView: some View {
        VStack {
            if clipboardManager.favoriteItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "star.slash")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No Favorite Items")
                        .font(.headline)
                    Text("Mark items as favorites by clicking the star icon")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(clipboardManager.favoriteItems) { item in
                            ClipboardItemView(item: item)
                            
                            if item.id != clipboardManager.favoriteItems.last?.id {
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var categoriesView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(clipboardManager.categories, id: \.self) { category in
                        Button(action: { clipboardManager.selectedCategory = category }) {
                            HStack(spacing: 4) {
                                Text(category)
                                    .font(.system(size: 11, weight: .medium))
                                
                                let count = category == "All" ? clipboardManager.items.count : clipboardManager.items.filter { $0.category == category }.count
                                if count > 0 {
                                    Text("\(count)")
                                        .font(.system(size: 10))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(clipboardManager.selectedCategory == category ? Color.white.opacity(0.3) : Color.secondary.opacity(0.2))
                                        )
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(clipboardManager.selectedCategory == category ? Color.blue : Color.secondary.opacity(0.1))
                            )
                            .foregroundColor(clipboardManager.selectedCategory == category ? .white : .primary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 10)
            
            Divider()
            
            // Filtered items
            if clipboardManager.filteredItems.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(clipboardManager.filteredItems) { item in
                            ClipboardItemView(item: item)
                            
                            if item.id != clipboardManager.filteredItems.last?.id {
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text("No Items Found")
                .font(.headline)
            
            if clipboardManager.searchText.isEmpty {
                Text("Copy something to see it here")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Try a different search term")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var footer: some View {
        HStack(spacing: 12) {
            // Items count
            HStack(spacing: 4) {
                Image(systemName: "doc.on.clipboard.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                Text("\(clipboardManager.items.count)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Monitoring status
            HStack(spacing: 6) {
                Circle()
                    .fill(clipboardManager.isMonitoringEnabled ? Color.green : Color.red)
                    .frame(width: 7, height: 7)
                    .shadow(color: clipboardManager.isMonitoringEnabled ? .green.opacity(0.4) : .red.opacity(0.4), radius: 1, x: 0, y: 0)
                
                Text(clipboardManager.isMonitoringEnabled ? "Monitoring" : "Paused")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Keyboard shortcut
            HStack(spacing: 2) {
                ForEach(["⌘", "⇧", "V"], id: \.self) { key in
                    Text(key)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.secondary.opacity(0.1))
                        )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [Color(NSColor.controlBackgroundColor), Color(NSColor.windowBackgroundColor)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
