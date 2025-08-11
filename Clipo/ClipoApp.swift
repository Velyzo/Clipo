//
//  ClipoApp.swift
//  Clipo
//
//  Created by Devin on 10.08.25.
//

import SwiftUI
import AppKit
import UserNotifications
import ApplicationServices
import ServiceManagement
import CoreServices

// MARK: - Window Configuration Extension
extension NSWindow {
    func configureForMenuBarApp() {
        self.level = .normal
        self.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        // Make the window properly visible and interactive
        self.hasShadow = true
        self.isOpaque = true
        self.backgroundColor = NSColor.windowBackgroundColor
        
        // Force the window to be able to become key by setting appropriate style mask
        if !self.styleMask.contains(.titled) {
            self.styleMask.insert(.titled)
        }
        if !self.styleMask.contains(.closable) {
            self.styleMask.insert(.closable)
        }
        if !self.styleMask.contains(.miniaturizable) {
            self.styleMask.insert(.miniaturizable)
        }
        if !self.styleMask.contains(.resizable) {
            self.styleMask.insert(.resizable)
        }
        
        // Ensure window can receive events and focus
        self.acceptsMouseMovedEvents = true
        self.ignoresMouseEvents = false
    }
}

// MARK: - Helper Functions
func findMainWindow() -> NSWindow? {
    // First try to find a window with "Clipo" in the title
    if let window = NSApplication.shared.windows.first(where: { 
        $0.title.contains("Clipo") && $0.contentViewController != nil 
    }) {
        return window
    }
    
    // Then look for any window that has content and is not a panel or popover
    if let window = NSApplication.shared.windows.first(where: { window in
        return window.contentViewController != nil && 
               window.isVisible == false && // Main window might not be visible yet
               !window.className.contains("Panel") &&
               !window.className.contains("Popover") &&
               window.styleMask.contains(.titled)
    }) {
        return window
    }
    
    // Finally, look for the first window with content
    return NSApplication.shared.windows.first(where: { $0.contentViewController != nil })
}

@main
struct ClipoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var appState = AppState.shared
    
    var body: some Scene {
        // Menu bar app with main window
        WindowGroup("Clipo") {
            ContentView()
                .onAppear {
                    DispatchQueue.main.async {
                        // When the main window shows, make the app regular so it appears in Dock
                        NSApp.setActivationPolicy(.regular)
                        NSApplication.shared.activate(ignoringOtherApps: true)
                        
                        // Find and configure the window with a slight delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            // Find the main content window more reliably
                            if let window = findMainWindow() {
                                window.configureForMenuBarApp()
                                window.makeKeyAndOrderFront(nil)
                                window.center() // Center the window on screen
                            }
                        }
                    }
                }
                .onDisappear {
                    DispatchQueue.main.async {
                        // When window closes, revert to accessory (menu bar only)
                        NSApp.setActivationPolicy(.accessory)
                    }
                }
                .onReceive(appState.$openSettingsFromPopover) { open in
                    if open {
                        DispatchQueue.main.async {
                            // Reset the flag immediately to prevent multiple triggers
                            appState.openSettingsFromPopover = false
                            
                            // Close any popovers first
                            if let menuBarManager = appDelegate.menuBarManager {
                                menuBarManager.closePopoverIfNeeded()
                            }
                            
                            NSApp.setActivationPolicy(.regular)
                            NSApplication.shared.activate(ignoringOtherApps: true)
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                if let window = findMainWindow() {
                                    window.configureForMenuBarApp()
                                    window.makeKeyAndOrderFront(nil)
                                    window.center() // Center the window on screen
                                }
                            }
                        }
                    }
                }
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Show Main Window") {
                    DispatchQueue.main.async {
                        NSApp.setActivationPolicy(.regular)
                        NSApplication.shared.activate(ignoringOtherApps: true)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            if let window = findMainWindow() {
                                window.configureForMenuBarApp()
                                window.makeKeyAndOrderFront(nil)
                                window.center() // Center the window on screen
                            }
                        }
                    }
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) var menuBarManager: MenuBarManager!
    private var clipboardManager: ClipboardManager!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App launching...")
        
        // Hide the main window and dock icon initially
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize clipboard manager first
        clipboardManager = ClipboardManager.shared
        print("ClipboardManager initialized")
        
        // Start clipboard monitoring
        clipboardManager.startMonitoring()
        print("Clipboard monitoring started")
        
        // Initialize menu bar manager
        menuBarManager = MenuBarManager()
        print("MenuBarManager initialized")
        
        // Check and request necessary permissions
        requestPermissionsIfNeeded()
        
        // Enable launch at login if previously set
        configureLaunchAtLogin()
        
        print("App launch complete")
    }
    
    private func requestPermissionsIfNeeded() {
        // Request accessibility permissions if not already granted
        if !AXIsProcessTrusted() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.requestAccessibilityPermissions()
            }
        } else {
            // If already granted, enable shortcuts
            menuBarManager?.enableGlobalShortcuts()
        }
        
        // Request notification permissions
        requestNotificationPermissions()
    }
    
    private func configureLaunchAtLogin() {
        let launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
        if launchAtLogin {
            setLaunchAtLogin(enabled: true)
        }
    }
    
    func setLaunchAtLogin(enabled: Bool) {
        // Use UserDefaults for now - proper implementation would use ServiceManagement
        UserDefaults.standard.set(enabled, forKey: "launchAtLogin")
        print("Launch at login \(enabled ? "enabled" : "disabled")")
        
        // TODO: Implement proper launch at login using ServiceManagement framework
        // when app is properly sandboxed and ready for distribution
    }
    
    private func requestAccessibilityPermissions() {
        let trusted = AXIsProcessTrusted()
        print("Accessibility permissions trusted: \(trusted)")
        
        if !trusted {
            // Create prompt with dictionary to request permissions
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
            
            if accessEnabled {
                // Enable shortcuts if permissions were just granted
                menuBarManager?.enableGlobalShortcuts()
            }
        }
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            DispatchQueue.main.async {
                print("Notification permissions granted: \(granted)")
                if let error = error {
                    print("Error requesting notification permissions: \(error)")
                }
            }
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Bring the main window to front when clicking Dock icon
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)
            NSApplication.shared.activate(ignoringOtherApps: true)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let window = findMainWindow() {
                    window.configureForMenuBarApp()
                    window.makeKeyAndOrderFront(nil)
                    window.center() // Center the window on screen
                }
            }
        }
        return true
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        // Keep windows as-is on activation; popovers are managed by MenuBarManager
    }
}
