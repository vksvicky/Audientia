//
//  NotificationPermissionManager.swift
//  Audientia
//
//  Handles notification permission requests and status tracking.
//

import AppKit
import Foundation
import os.log
import UserNotifications

@MainActor
public final class NotificationPermissionManager: ObservableObject {
    public static let shared = NotificationPermissionManager()
    
    @Published public private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private let center = UNUserNotificationCenter.current()
    private let hasPromptedKey = "audientia.notifications.hasPrompted"
    private let logger = Logger.userInterface
    
    private init() {
        Task {
            await refreshAuthorizationStatus()
        }
    }
    
    public func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }
    
    /// Called on app launch to request permission once with rationale.
    public func ensureInitialPromptIfNeeded() async {
        guard !UserDefaults.standard.bool(forKey: hasPromptedKey) else {
            await refreshAuthorizationStatus()
            return
        }
        
        let shouldProceed = presentRationaleAlert()
        UserDefaults.standard.set(true, forKey: hasPromptedKey)
        guard shouldProceed else { return }
        
        await requestAuthorization()
    }
    
    /// Explicit request from Settings UI.
    public func requestPermissionFromSettings() async {
        await requestAuthorization(showRationale: true)
    }
    
    private func requestAuthorization(showRationale: Bool = false) async {
        if showRationale {
            let proceed = presentRationaleAlert()
            guard proceed else { return }
        }
        
        let granted = try? await center.requestAuthorization(options: [.alert, .sound])
        await refreshAuthorizationStatus()
        if granted == true {
            logger.info("Notification permission granted by user.")
        } else {
            logger.warning("Notification permission denied.")
        }
    }
    
    private func presentRationaleAlert() -> Bool {
        let alert = NSAlert()
        alert.messageText = "Allow Notifications?"
        alert.informativeText = """
        Audientia alerts you when background library scans finish so you can review newly added music right away.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Allow Notifications")
        alert.addButton(withTitle: "Not Now")
        return alert.runModal() == .alertFirstButtonReturn
    }
    
    public var statusDescription: String {
        NotificationPermissionStatusFormatter.description(for: authorizationStatus)
    }
    
    public func openSystemSettings() {
        guard let bundleID = Bundle.main.bundleIdentifier,
              let url = URL(
                string: "x-apple.systempreferences:com.apple.preference.notifications?AppID=\(bundleID)"
              ) else {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                NSWorkspace.shared.open(url)
            }
            return
        }
        NSWorkspace.shared.open(url)
    }
}

/// Helper used to turn `UNAuthorizationStatus` into a user-facing string.
public enum NotificationPermissionStatusFormatter {
    public static func description(for status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "Not requested yet"
        case .denied:
            return "Denied in System Settings"
        case .authorized:
            return "Allowed"
        case .provisional:
            return "Provisional (temporary)"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }
}
