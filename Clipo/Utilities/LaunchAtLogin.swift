//
//  LaunchAtLogin.swift
//  Clipo
//
//  Created by Velyzo on 10.08.25.
//

import Foundation
import ServiceManagement

struct LaunchAtLogin {
    private static let identifier = "com.velyzo.Clipo.LaunchHelper"
    
    static var isEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "LaunchAtLogin")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "LaunchAtLogin")
            
            if newValue {
                enableLaunchAtLogin()
            } else {
                disableLaunchAtLogin()
            }
        }
    }
    
    private static func enableLaunchAtLogin() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }
        
        // For macOS 13+ using modern ServiceManagement
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.register()
                print("✅ Launch at login enabled")
            } catch {
                print("❌ Failed to enable launch at login: \(error)")
            }
        } else {
            // Legacy method for older macOS versions
            let success = SMLoginItemSetEnabled(bundleIdentifier as CFString, true)
            if success {
                print("✅ Launch at login enabled (legacy)")
            } else {
                print("❌ Failed to enable launch at login (legacy)")
            }
        }
    }
    
    private static func disableLaunchAtLogin() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }
        
        // For macOS 13+ using modern ServiceManagement
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.unregister()
                print("✅ Launch at login disabled")
            } catch {
                print("❌ Failed to disable launch at login: \(error)")
            }
        } else {
            // Legacy method for older macOS versions
            let success = SMLoginItemSetEnabled(bundleIdentifier as CFString, false)
            if success {
                print("✅ Launch at login disabled (legacy)")
            } else {
                print("❌ Failed to disable launch at login (legacy)")
            }
        }
    }
}
