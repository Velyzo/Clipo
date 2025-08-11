//
//  MenuBarManager.swift
//  Clipo
//
//  Created by Devin on 10.08.25.
//

import SwiftUI
import AppKit
import Carbon
import Combine

class MenuBarManager: NSObject, ObservableObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var globalClickMonitor: Any?
    private var globalShortcutMonitor: Any?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isPopoverShown = false
    
    override init() {
        super.init()
        setupMenuBar()
        setupEventMonitor()
        setupGlobalShortcuts()
        
        // Close popover when clicking outside
        NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)
            .sink { [weak self] _ in
                self?.closePopover()
            }
            .store(in: &cancellables)
    }
    
    deinit {
        if let monitor = globalShortcutMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Set up the menu bar icon
            if let image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipo") {
                image.size = NSSize(width: 16, height: 16)
                button.image = image
            } else {
                button.title = "📋"
            }
            
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "Clipo - Clipboard Manager"
            
            setupPopover()
        }
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 400, height: 500)
        popover?.behavior = .transient
        popover?.delegate = self
        
        let contentView = MenuBarContentView()
        popover?.contentViewController = NSHostingController(rootView: contentView)
    }
    
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            // Right-click shows context menu
            showContextMenu()
        } else {
            // Left-click toggles popover
            togglePopover()
        }
    }
    
    private func showContextMenu() {
        let menu = NSMenu()
        
        menu.addItem(withTitle: "Open Clipo Window", action: #selector(openMainWindow), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Clear History", action: #selector(clearHistory), keyEquivalent: "")
        menu.addItem(withTitle: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit Clipo", action: #selector(quit), keyEquivalent: "q")
        
        // Set targets
        for item in menu.items {
            if item.action != nil {
                item.target = self
            }
        }
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }
    
    @objc private func openMainWindow() {
        // Close popover first if it's open
        closePopover()
        
        // Use AppState to trigger main window opening (same as settings)
        AppState.shared.openSettingsFromPopover = true
    }
    
    @objc private func clearHistory() {
        ClipboardManager.shared.clearHistory()
    }
    
    @objc private func openSettings() {
        // Close popover first if it's open
        closePopover()
        
        // Set the settings flag
        AppState.shared.openSettingsFromPopover = true
        
        // Activate the app and set it to regular policy to show in dock
        NSApp.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        // Find and show the main window
        if let window = NSApplication.shared.windows.first(where: { 
            $0.title.contains("Clipo") && !String(describing: type(of: $0)).contains("NSPopover")
        }) {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        } else {
            // If no main window exists, create one by triggering app focus
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let window = NSApplication.shared.windows.first(where: { 
                    !String(describing: type(of: $0)).contains("NSPopover") 
                }) {
                    window.makeKeyAndOrderFront(nil)
                    window.orderFrontRegardless()
                }
            }
        }
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    private func togglePopover() {
        guard let popover = popover else { return }
        
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }
    
    private func showPopover() {
        guard let button = statusItem?.button,
              let popover = popover else { return }
        
        isPopoverShown = true
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        
        // Start monitoring for clicks outside the popover with a simple global monitor
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.closePopover()
        }
        
        // Make the popover key window and ensure it receives events
        DispatchQueue.main.async {
            if let window = popover.contentViewController?.view.window {
                window.makeKey()
            }
        }
        
        // Activate app to ensure popover is interactive
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    private func closePopover() {
        popover?.performClose(nil)
        isPopoverShown = false
        
        // Stop monitoring for clicks when popover is closed
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
            globalClickMonitor = nil
        }
    }
    
    // Public method to close popover when needed
    func closePopoverIfNeeded() {
        if isPopoverShown {
            closePopover()
        }
    }
    
    private func setupEventMonitor() {
        // We'll use a simple global monitor that only closes when clicking outside
        // The EventMonitor class includes local monitoring which interferes with popover clicks
    }
    
    private func setupGlobalShortcuts() {
        // Only set up global shortcuts if we have accessibility permissions
        guard AXIsProcessTrusted() else {
            print("⚠️ No accessibility permissions for global shortcuts")
            return
        }
        
        // Set up global shortcut for Command+Shift+V
        let keyCode = kVK_ANSI_V
        
        globalShortcutMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let eventModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let expectedModifiers: NSEvent.ModifierFlags = [.command, .shift]
            
            if event.keyCode == keyCode && eventModifiers == expectedModifiers {
                DispatchQueue.main.async {
                    self?.togglePopover()
                }
            }
        }
        
        print("✅ Global shortcuts set up successfully")
    }
    
    // Public API to enable shortcuts when permissions are granted
    func enableGlobalShortcuts() {
        // Remove existing monitor
        if let monitor = globalShortcutMonitor {
            NSEvent.removeMonitor(monitor)
            globalShortcutMonitor = nil
        }
        
        // Set up new monitor
        setupGlobalShortcuts()
    }
}

extension MenuBarManager: NSPopoverDelegate {
    func popoverDidClose(_ notification: Notification) {
        isPopoverShown = false
    }
}


