//
//  ClipboardItemView.swift
//  Clipo
//
//  Created by Devin on 10.08.25.
//

import SwiftUI

struct ClipboardItemView: View {
    let item: ClipboardItem
    @ObservedObject var clipboardManager = ClipboardManager.shared
    @State private var isHovered = false
    @State private var showingCategoryPicker = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            Image(systemName: item.type.icon)
                .foregroundColor(item.type.color)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 20, height: 20)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.displayTitle)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if item.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 10))
                    }
                }
                
                // Show image thumbnail for image items
                if item.type == .image {
                    HStack {
                        if let nsImage = loadImage(from: item.content) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 80, maxHeight: 60)
                                .cornerRadius(4)
                                .clipped()
                        } else {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.3))
                                .frame(width: 80, height: 60)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.secondary)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.preview)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                    }
                } else {
                    Text(item.preview)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                HStack {
                    Text(item.timeAgo)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    
                    if let appName = item.applicationName {
                        Text("• \(appName)")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    
                    if item.category != "General" {
                        Text("• \(item.category)")
                            .font(.system(size: 9))
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                }
            }
            
            // Action buttons (shown on hover)
            if isHovered {
                HStack(spacing: 8) {
                    Button(action: { clipboardManager.toggleFavorite(item) }) {
                        Image(systemName: item.isFavorite ? "star.fill" : "star")
                            .foregroundColor(item.isFavorite ? .yellow : .secondary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help(item.isFavorite ? "Remove from favorites" : "Add to favorites")
                    
                    Button(action: { showingCategoryPicker.toggle() }) {
                        Image(systemName: "tag")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Change category")
                    .popover(isPresented: $showingCategoryPicker) {
                        CategoryPickerView(item: item)
                    }
                    
                    Button(action: { clipboardManager.deleteItem(item) }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Delete item")
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color(NSColor.selectedContentBackgroundColor) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onTapGesture(count: 2) {
            clipboardManager.copyItem(item)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                if let popover = NSApp.windows.first(where: { $0.className.contains("Popover") }) {
                    popover.close()
                }
            }
        }
        .onTapGesture {
            clipboardManager.copyItem(item)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                if let popover = NSApp.windows.first(where: { $0.className.contains("Popover") }) {
                    popover.close()
                }
            }
        }
        .contextMenu {
            Button("Copy") {
                clipboardManager.copyItem(item)
            }
            
            Divider()
            
            Button(item.isFavorite ? "Remove from Favorites" : "Add to Favorites") {
                clipboardManager.toggleFavorite(item)
            }
            
            Menu("Set Category") {
                ForEach(["General", "Code", "URLs", "Images", "Files", "Notes"], id: \.self) { category in
                    Button(category) {
                        clipboardManager.updateItemCategory(item, category: category)
                    }
                }
            }
            
            Divider()
            
            Button("Delete", role: .destructive) {
                clipboardManager.deleteItem(item)
            }
        }
    }
    
    // Helper function to load images from disk
    private func loadImage(from path: String) -> NSImage? {
        guard FileManager.default.fileExists(atPath: path),
              let nsImage = NSImage(contentsOfFile: path) else {
            return nil
        }
        return nsImage
    }
}

struct CategoryPickerView: View {
    let item: ClipboardItem
    @ObservedObject var clipboardManager = ClipboardManager.shared
    @State private var customCategory = ""
    
    let predefinedCategories = ["General", "Code", "URLs", "Images", "Files", "Notes", "Passwords", "Temporary"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Category")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(predefinedCategories, id: \.self) { category in
                        Button(action: {
                            clipboardManager.updateItemCategory(item, category: category)
                        }) {
                            HStack {
                                Text(category)
                                Spacer()
                                if item.category == category {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            item.category == category ? Color.blue.opacity(0.1) : Color.clear
                        )
                    }
                }
            }
            .frame(maxHeight: 200)
            
            Divider()
            
            HStack {
                TextField("Custom category", text: $customCategory)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Set") {
                    if !customCategory.isEmpty {
                        clipboardManager.updateItemCategory(item, category: customCategory)
                        customCategory = ""
                    }
                }
                .disabled(customCategory.isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(width: 200)
    }
}
