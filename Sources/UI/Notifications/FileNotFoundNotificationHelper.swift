//
//  FileNotFoundNotificationHelper.swift
//  Audientia
//
//  Helper for displaying notifications when audio files are not found
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import Foundation
import os.log
import Shared
import UserNotifications

/// Helper for displaying notifications when audio files are not found
@MainActor
public enum FileNotFoundNotificationHelper {
    private static let logger = Logger.userInterface
    
    /// Check if running in Xcode test agent environment
    /// `UNUserNotificationCenter.current()` asserts when called from the Xcode
    /// test agent host bundle (e.g. SwiftUI previews / some UI test hosts).
    private static var isRunningInXcodeAgent: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
    
    /// Show a notification when a track file is not found
    /// - Parameters:
    ///   - trackTitle: The title of the track that was not found
    ///   - filePath: The file path that was not found
    public static func showFileNotFoundNotification(trackTitle: String, filePath: String) async {
        // In test environment, skip notification center and use alert directly
        guard !isRunningInXcodeAgent else {
            logger.debug("Notification center unavailable in test environment; using alert fallback")
            deliverFallbackAlert(trackTitle: trackTitle, filePath: filePath)
            return
        }
        
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            await scheduleNotification(trackTitle: trackTitle, filePath: filePath, center: center)
        case .notDetermined:
            // Request permission first
            let granted = try? await center.requestAuthorization(options: [.alert, .sound])
            if granted == true {
                await scheduleNotification(trackTitle: trackTitle, filePath: filePath, center: center)
            } else {
                deliverFallbackAlert(trackTitle: trackTitle, filePath: filePath)
            }
        case .denied:
            deliverFallbackAlert(trackTitle: trackTitle, filePath: filePath)
        @unknown default:
            deliverFallbackAlert(trackTitle: trackTitle, filePath: filePath)
        }
    }
    
    private static func scheduleNotification(
        trackTitle: String,
        filePath: String,
        center: UNUserNotificationCenter
    ) async {
        let content = UNMutableNotificationContent()
        content.title = "File Not Found"
        content.body = "The track \"\(trackTitle)\" could not be found at:\n\(filePath)"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        do {
            try await center.add(request)
            let trackTitlePublic = trackTitle
            logger.info(
                "File not found notification scheduled for track: \(trackTitlePublic)"
            )
        } catch {
            logger.error(
                "Failed to schedule file not found notification: \(error.localizedDescription)"
            )
            deliverFallbackAlert(trackTitle: trackTitle, filePath: filePath)
        }
    }
    
    private static func deliverFallbackAlert(trackTitle: String, filePath: String) {
        let trackTitlePublic = trackTitle
        
        // In test environment, skip showing alert (would block test execution)
        if isRunningInXcodeAgent {
            logger.debug(
                "File not found alert skipped in test environment for track: \(trackTitlePublic)"
            )
            return
        }
        
        let alert = NSAlert()
        alert.messageText = "File Not Found"
        alert.informativeText = """
        The track "\(trackTitle)" could not be found.
        
        File path: \(filePath)
        
        The file may have been moved or deleted. Please check the file location.
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
        
        logger.info(
            "File not found alert shown for track: \(trackTitlePublic)"
        )
    }
}
