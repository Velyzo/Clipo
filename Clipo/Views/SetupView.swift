//
//  SetupView.swift
//  Clipo
//
//  Created by Velyzo on 11.08.25.
//

import SwiftUI
import AppKit
import UserNotifications
import ApplicationServices

struct SetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep: SetupStep = .welcome
    @State private var accessibilityGranted = AXIsProcessTrusted()
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isWorking = false
    @State private var animateGradient = false

    enum SetupStep: Int, CaseIterable {
        case welcome = 0
        case accessibility
        case notifications
        case finish

        var title: String {
            switch self {
            case .welcome: return "Welcome to Clipo"
            case .accessibility: return "Enable Global Shortcuts"
            case .notifications: return "Notifications (Optional)"
            case .finish: return "You're All Set!"
            }
        }

        var subtitle: String {
            switch self {
            case .welcome: return "The Extremely Good Clipboard Manager"
            case .accessibility: return "Press ⌘⇧V from anywhere"
            case .notifications: return "Get notified about clipboard activity"
            case .finish: return "Clipo is ready to use"
            }
        }

        var icon: String {
            switch self {
            case .welcome: return "doc.on.clipboard"
            case .accessibility: return "keyboard"
            case .notifications: return "bell.badge"
            case .finish: return "checkmark.circle"
            }
        }
        
        var gradient: LinearGradient {
            switch self {
            case .welcome: return LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .accessibility: return LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .notifications: return LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .finish: return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
    }

    var body: some View {
        ZStack {
            // Background gradient
            currentStep.gradient
                .opacity(0.1)
                .ignoresSafeArea()
                .scaleEffect(animateGradient ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateGradient)
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                Divider()
                    .padding(.horizontal)
                
                // Content
                contentView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Divider()
                    .padding(.horizontal)
                
                // Navigation
                navigationView
            }
        }
        .frame(width: 600, height: 550)
        .onAppear {
            animateGradient = true
            refreshPermissionStates()
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 16) {
            // Icon and Title
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(currentStep.gradient)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: currentStep.icon)
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.white)
                }
                .scaleEffect(isWorking ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isWorking)
                
                VStack(spacing: 4) {
                    Text(currentStep.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text(currentStep.subtitle)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress Bar
            progressBar
        }
        .padding(.top, 24)
        .padding(.horizontal, 32)
        .padding(.bottom, 20)
    }
    
    private var progressBar: some View {
        HStack(spacing: 8) {
            ForEach(SetupStep.allCases, id: \.self) { step in
                Capsule()
                    .fill(step.rawValue <= currentStep.rawValue ? AnyShapeStyle(currentStep.gradient) : AnyShapeStyle(Color.secondary.opacity(0.3)))
                    .frame(height: 6)
                    .frame(maxWidth: .infinity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: currentStep)
    }
    
    // MARK: - Content
    private var contentView: some View {
        Group {
            switch currentStep {
            case .welcome: welcomeView
            case .accessibility: accessibilityView
            case .notifications: notificationsView
            case .finish: finishView
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }
    
    private var welcomeView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("Meet Your New Clipboard Superpowers")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("Clipo automatically saves everything you copy and makes it instantly accessible with global shortcuts.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                FeatureCard(
                    icon: "keyboard",
                    title: "Global Access",
                    description: "Press ⌘⇧V from any app",
                    color: .blue
                )
                FeatureCard(
                    icon: "photo.stack",
                    title: "Smart History",
                    description: "Text, images, files & URLs",
                    color: .green
                )
                FeatureCard(
                    icon: "heart.circle",
                    title: "Favorites",
                    description: "Save important items",
                    color: .pink
                )
                FeatureCard(
                    icon: "folder",
                    title: "Categories",
                    description: "Organize your clips",
                    color: .orange
                )
            }
            
            VStack(spacing: 8) {
                Text("Created by Velyzo")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Link("velyzo.de", destination: URL(string: "https://velyzo.de")!)
                    .font(.caption)
            }
        }
    }
    
    private var accessibilityView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: accessibilityGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.title)
                        .foregroundColor(accessibilityGranted ? .green : .orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(accessibilityGranted ? "Accessibility Enabled" : "Accessibility Required")
                            .font(.headline)
                        Text(accessibilityGranted ? "Global shortcuts are working!" : "Required for global keyboard shortcuts")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill((accessibilityGranted ? Color.green : Color.orange).opacity(0.1))
                )
                
                if !accessibilityGranted {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Steps to Enable:")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            StepRow(number: 1, text: "Click 'Open System Settings' below")
                            StepRow(number: 2, text: "Find Clipo in the list and enable it")
                            StepRow(number: 3, text: "Return here and click 'Check Again'")
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            HStack(spacing: 16) {
                if !accessibilityGranted {
                    Button("Open System Settings") {
                        openAccessibilitySettings()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                
                Button(accessibilityGranted ? "Continue" : "Check Again") {
                    if accessibilityGranted {
                        nextStep()
                    } else {
                        checkAccessibility()
                    }
                }
                .buttonStyle(BorderedProminentButtonStyle())
                .controlSize(.large)
                .disabled(isWorking)
            }
        }
    }
    
    private var notificationsView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: notificationIcon)
                        .font(.title)
                        .foregroundColor(notificationColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(notificationTitle)
                            .font(.headline)
                        Text("Get a subtle notification when items are copied to your clipboard")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(notificationColor.opacity(0.1))
                )
                
                VStack(spacing: 12) {
                    Text("This is completely optional but recommended for the best experience.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    if notificationStatus == .denied {
                        Text("You can always enable notifications later in System Settings.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            
            HStack(spacing: 16) {
                if notificationStatus == .notDetermined {
                    Button("Allow Notifications") {
                        requestNotifications()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isWorking)
                }
                
                if notificationStatus != .authorized {
                    Button("Open Settings") {
                        openNotificationSettings()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                
                Button("Continue") {
                    nextStep()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }
    
    private var finishView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Image(systemName: "party.popper.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(currentStep.gradient)
                
                Text("Clipo is Ready!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("You can now access your clipboard history from anywhere using ⌘⇧V")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                Text("Quick Tips:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 12) {
                    TipRow(icon: "keyboard", text: "Press ⌘⇧V to open Clipo anywhere")
                    TipRow(icon: "doc.on.clipboard", text: "Click the menu bar icon for quick access")
                    TipRow(icon: "gearshape", text: "Visit Settings to customize your experience")
                    TipRow(icon: "globe", text: "Check out velyzo.de for more apps")
                }
            }
            
            Button("Start Using Clipo") {
                complete()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
    
    // MARK: - Navigation
    private var navigationView: some View {
        HStack {
            if currentStep != .welcome {
                Button("Back") {
                    previousStep()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            
            Spacer()
            
            if currentStep != .finish {
                Button(nextButtonTitle) {
                    nextStep()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isWorking)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
    }
    
    // MARK: - Computed Properties
    private var nextButtonTitle: String {
        switch currentStep {
        case .welcome: return "Get Started"
        case .accessibility: return accessibilityGranted ? "Continue" : "Skip for Now"
        case .notifications: return "Continue"
        case .finish: return "Finish"
        }
    }
    
    private var notificationIcon: String {
        switch notificationStatus {
        case .authorized: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        case .notDetermined: return "questionmark.circle.fill"
        default: return "bell.badge"
        }
    }
    
    private var notificationColor: Color {
        switch notificationStatus {
        case .authorized: return .green
        case .denied: return .red
        case .notDetermined: return .orange
        default: return .orange
        }
    }
    
    private var notificationTitle: String {
        switch notificationStatus {
        case .authorized: return "Notifications Enabled"
        case .denied: return "Notifications Denied"
        case .notDetermined: return "Allow Notifications?"
        default: return "Notifications"
        }
    }
    
    // MARK: - Actions
    private func nextStep() {
        guard let currentIndex = SetupStep.allCases.firstIndex(of: currentStep),
              currentIndex < SetupStep.allCases.count - 1 else {
            complete()
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = SetupStep.allCases[currentIndex + 1]
        }
    }
    
    private func previousStep() {
        guard let currentIndex = SetupStep.allCases.firstIndex(of: currentStep),
              currentIndex > 0 else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = SetupStep.allCases[currentIndex - 1]
        }
    }
    
    private func checkAccessibility() {
        isWorking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            accessibilityGranted = AXIsProcessTrusted()
            isWorking = false
            
            if accessibilityGranted {
                // Auto-advance with a small delay for better UX
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    nextStep()
                }
                
                // Try to enable shortcuts immediately
                NotificationCenter.default.post(name: Notification.Name("ClipoEnableShortcuts"), object: nil)
            }
        }
    }
    
    private func requestNotifications() {
        isWorking = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                self.refreshPermissionStates()
                self.isWorking = false
                
                if granted {
                    // Auto-advance with a small delay for better UX
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.nextStep()
                    }
                }
            }
        }
    }
    
    private func refreshPermissionStates() {
        accessibilityGranted = AXIsProcessTrusted()
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationStatus = settings.authorizationStatus
                
                // Auto-advance if both permissions are granted
                if self.currentStep == .welcome && self.accessibilityGranted && self.notificationStatus == .authorized {
                    self.currentStep = .finish
                }
            }
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
    
    private func complete() {
        UserDefaults.standard.set(true, forKey: "hasCompletedSetup")
        NotificationCenter.default.post(name: Notification.Name("ClipoSetupCompleted"), object: nil)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            dismiss()
        }
    }
}

// MARK: - Helper Views
private struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct StepRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 24, height: 24)
                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

private struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

#Preview {
    SetupView()
}
