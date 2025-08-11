//
//  ClipboardItem.swift
//  Clipo
//
//  Created by Devin on 10.08.25.
//

import Foundation
import SwiftUI
import AppKit

enum ClipboardItemType: String, CaseIterable, Codable {
    case text = "text"
    case image = "image"
    case file = "file"
    case url = "url"
    
    var icon: String {
        switch self {
        case .text: return "doc.text"
        case .image: return "photo"
        case .file: return "doc"
        case .url: return "link"
        }
    }
    
    var color: Color {
        switch self {
        case .text: return .blue
        case .image: return .green
        case .file: return .orange
        case .url: return .purple
        }
    }
}

struct ClipboardItem: Identifiable, Codable, Hashable {
    let id: UUID
    var content: String // Make content mutable for editing
    let type: ClipboardItemType
    let timestamp: Date
    var isFavorite: Bool = false
    var category: String = "General"
    var preview: String // Make preview mutable to update with content
    let applicationName: String?
    
    init(content: String, type: ClipboardItemType, applicationName: String? = nil) {
        self.id = UUID()
        self.content = content
        self.type = type
        self.timestamp = Date()
        self.applicationName = applicationName
        
        // Generate preview based on type
        switch type {
        case .text:
            self.preview = String(content.prefix(100))
        case .image:
            self.preview = "Image copied from \(applicationName ?? "Unknown")"
        case .file:
            self.preview = content.components(separatedBy: "/").last ?? "File"
        case .url:
            self.preview = content
        }
    }
    
    var displayTitle: String {
        switch type {
        case .text:
            let lines = content.components(separatedBy: .newlines)
            return lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Empty"
        case .image:
            return "Image"
        case .file:
            return URL(string: content)?.lastPathComponent ?? "File"
        case .url:
            return URL(string: content)?.host ?? content
        }
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    mutating func updateContent(_ newContent: String) {
        content = newContent
        // Update preview based on type
        switch type {
        case .text:
            preview = String(newContent.prefix(100))
        case .image:
            preview = "Image copied from \(applicationName ?? "Unknown")"
        case .file:
            preview = newContent.components(separatedBy: "/").last ?? "File"
        case .url:
            preview = newContent
        }
    }
}
