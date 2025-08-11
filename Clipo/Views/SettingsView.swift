//
//  SettingsView.swift
//  Clipo
//
//  Created by Velyzo on 10.08.25.
//

import SwiftUI
import ServiceManagement
import ApplicationServices
import UserNotifications

struct SettingsView: View {
    @ObservedObject private var clipboardManager = ClipboardManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: SettingsTab = .general
    @State private var launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
    @State private var accessibilityGranted = AXIsProcessTrusted()
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    
    enum SettingsTab: String, CaseIterable { 
        case general, permissions, shortcuts, about
        
        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .permissions: return "lock.shield"
            case .shortcuts: return "keyboard"
            case .about: return "info.circle"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            // Sidebar
            List(SettingsTab.allCases, id: \.self, selection: $selectedTab) { tab in
                Label(tab.rawValue.capitalized, systemImage: tab.icon)
                    .tag(tab)
            }
            .navigationTitle("Settings")
            .frame(minWidth: 180)
            
            // Detail view
            Group {
                switch selectedTab {
                case .general: GeneralSettingsView()
                case .permissions: PermissionsSettingsView(accessibilityGranted: $accessibilityGranted, notificationStatus: $notificationStatus)
                case .shortcuts: ShortcutsSettingsView()
                case .about: AboutSettingsView()
                }
            }
            .frame(minWidth: 400)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(minWidth: 650, minHeight: 500)
        .onAppear {
            refreshPermissionStates()
        }
    }
    
    private func refreshPermissionStates() {
        accessibilityGranted = AXIsProcessTrusted()
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationStatus = settings.authorizationStatus
            }
        }
    }
}

// MARK: - General Settings
private struct GeneralSettingsView: View {
    @ObservedObject private var clipboardManager = ClipboardManager.shared
    @State private var launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Application Section
                SettingsSection("Application", icon: "app.badge") {
                    VStack(alignment: .leading, spacing: 16) {
                        SettingsToggle(
                            "Launch Clipo at startup",
                            subtitle: "Start monitoring clipboard when you log in",
                            isOn: $launchAtLogin
                        ) { enabled in
                            // Use UserDefaults for now - proper launch at login would require more setup
                            UserDefaults.standard.set(enabled, forKey: "launchAtLogin")
                            launchAtLogin = enabled
                        }
                        
                        SettingsToggle(
                            "Enable clipboard monitoring",
                            subtitle: "Automatically save copied items",
                            isOn: $clipboardManager.isMonitoringEnabled
                        )
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Maximum items to store")
                                    .font(.headline)
                                Text("Older items are automatically removed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("No limit - storing unlimited items")
                                .foregroundColor(.secondary)
                            .frame(width: 120)
                        }
                    }
                }
                
                // Notifications Section
                SettingsSection("Notifications", icon: "bell") {
                    VStack(alignment: .leading, spacing: 16) {
                        SettingsToggle(
                            "Show notifications",
                            subtitle: "Get notified when items are copied",
                            isOn: $clipboardManager.showNotifications
                        )
                    }
                }
                
                // Data Management Section
                SettingsSection("Data Management", icon: "internaldrive") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Current storage: \(clipboardManager.items.count) items")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                            Button("Clear All History") {
                                clipboardManager.clearHistory()
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.red)
                            
                            Button("Clear Items > 30 Days") {
                                clipboardManager.clearOldItems()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("General")
    }
}

// MARK: - Permissions Settings
private struct PermissionsSettingsView: View {
    @Binding var accessibilityGranted: Bool
    @Binding var notificationStatus: UNAuthorizationStatus
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SettingsSection("Required Permissions", icon: "lock.shield") {
                    VStack(alignment: .leading, spacing: 20) {
                        // Accessibility Permission
                        PermissionCard(
                            title: "Accessibility Access",
                            description: "Required for global keyboard shortcuts (⌘⇧V)",
                            status: accessibilityGranted ? .granted : .denied,
                            primaryAction: {
                                openAccessibilitySettings()
                            },
                            secondaryAction: {
                                refreshAccessibility()
                            }
                        )
                        
                        // Notification Permission
                        PermissionCard(
                            title: "Notifications",
                            description: "Optional: Show alerts when items are copied",
                            status: notificationPermissionStatus,
                            primaryAction: {
                                if notificationStatus == .notDetermined {
                                    requestNotifications()
                                } else {
                                    openNotificationSettings()
                                }
                            },
                            secondaryAction: {
                                refreshNotificationStatus()
                            }
                        )
                    }
                }
                
            }
            .padding()
        }
        .navigationTitle("Permissions")
    }
    
    private var notificationPermissionStatus: PermissionStatus {
        switch notificationStatus {
        case .authorized: return .granted
        case .denied: return .denied
        case .notDetermined: return .notRequested
        default: return .denied
        }
    }
    
    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func openNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                refreshNotificationStatus()
            }
        }
    }
    
    private func refreshAccessibility() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            accessibilityGranted = AXIsProcessTrusted()
            
            // Try to enable shortcuts if permission was granted
            if accessibilityGranted {
                NotificationCenter.default.post(name: Notification.Name("ClipoEnableShortcuts"), object: nil)
            }
        }
    }
    
    private func refreshNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationStatus = settings.authorizationStatus
            }
        }
    }
}

// MARK: - Shortcuts Settings
private struct ShortcutsSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SettingsSection("Global Shortcuts", icon: "keyboard") {
                    VStack(alignment: .leading, spacing: 16) {
                        ShortcutRow(description: "Toggle Clipo popover", keys: ["⌘", "⇧", "V"])
                        ShortcutRow(description: "Show main window", keys: ["⌘", "N"])
                    }
                }
                
                SettingsSection("Popover Shortcuts", icon: "rectangle.on.rectangle") {
                    VStack(alignment: .leading, spacing: 16) {
                        ShortcutRow(description: "Clear all history", keys: ["⌘", "⇧", "C"])
                        ShortcutRow(description: "Close popover", keys: ["⎋"])
                        ShortcutRow(description: "Search", keys: ["⌘", "F"])
                    }
                }
                
                SettingsSection("Notes", icon: "info.circle") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Global shortcuts work from any application")
                            .foregroundColor(.secondary)
                        Text("• Requires Accessibility permission")
                            .foregroundColor(.secondary)
                        Text("• Shortcuts cannot be customized yet")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Shortcuts")
    }
}

// MARK: - About Settings
private struct AboutSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // App Icon and Info
                HStack(spacing: 20) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Clipo")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("The Extremely Good Clipboard Manager")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Version 1.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                SettingsSection("Created by Velyzo", icon: "person.circle") {
                    VStack(alignment: .leading, spacing: 16) {
                        Link(destination: URL(string: "https://velyzo.de")!) {
                            HStack {
                                Image(systemName: "globe")
                                Text("velyzo.de")
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption)
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        Text("Built with ❤️ using SwiftUI and AppKit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                SettingsSection("Features", icon: "star.circle") {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        FeatureBadge("Global Shortcuts", "keyboard")
                        FeatureBadge("Menu Bar Interface", "menubar.rectangle")
                        FeatureBadge("Image Support", "photo")
                        FeatureBadge("Launch at Login", "power")
                        FeatureBadge("Clipboard History", "clock.arrow.circlepath")
                        FeatureBadge("Notifications", "bell")
                    }
                }
            }
            .padding()
        }
        .navigationTitle("About")
    }
}

// MARK: - Helper Views
private struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    init(_ title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            content
                .padding(.leading, 24)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct SettingsToggle: View {
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    let onChange: ((Bool) -> Void)?
    
    init(_ title: String, subtitle: String? = nil, isOn: Binding<Bool>, onChange: ((Bool) -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
        self.onChange = onChange
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: subtitle != nil ? 4 : 0) {
                Text(title)
                    .font(.headline)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .onChange(of: isOn) { _, newValue in
                    onChange?(newValue)
                }
        }
    }
}

private enum PermissionStatus {
    case granted, denied, notRequested
    
    var color: Color {
        switch self {
        case .granted: return .green
        case .denied: return .red
        case .notRequested: return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .granted: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        case .notRequested: return "questionmark.circle.fill"
        }
    }
    
    var text: String {
        switch self {
        case .granted: return "Granted"
        case .denied: return "Denied"
        case .notRequested: return "Not Requested"
        }
    }
}

private struct PermissionCard: View {
    let title: String
    let description: String
    let status: PermissionStatus
    let primaryAction: () -> Void
    let secondaryAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: status.icon)
                        .foregroundColor(status.color)
                    Text(status.text)
                        .foregroundColor(status.color)
                        .fontWeight(.semibold)
                }
            }
            
            HStack(spacing: 12) {
                Button(status == .granted ? "Open Settings" : (status == .notRequested ? "Allow" : "Open Settings")) {
                    primaryAction()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Refresh") {
                    secondaryAction()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(status.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct ShortcutRow: View {
    let description: String
    let keys: [String]
    
    var body: some View {
        HStack {
            Text(description)
                .font(.headline)
            Spacer()
            HStack(spacing: 4) {
                ForEach(keys, id: \.self) { key in
                    Text(key)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
    }
}

private struct FeatureBadge: View {
    let title: String
    let icon: String
    
    init(_ title: String, _ icon: String) {
        self.title = title
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .clipShape(Capsule())
    }
}
