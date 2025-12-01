//
//  LibraryScanCoordinator.swift
//  Audientia
//
//  Coordinates library scanning with progress tracking and notifications
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import DataLayer
import Foundation
import os.log
import Shared
import SwiftUI
import UserNotifications

/// Scan results similar to MediaMonkey's scan results dialog
public struct ScanResults {
    public let duration: TimeInterval
    public let newFiles: Int
    public let updatedFiles: Int
    public let failedFiles: Int
    public let skippedFiles: Int
    
    public init(duration: TimeInterval, newFiles: Int, updatedFiles: Int, failedFiles: Int, skippedFiles: Int) {
        self.duration = duration
        self.newFiles = newFiles
        self.updatedFiles = updatedFiles
        self.failedFiles = failedFiles
        self.skippedFiles = skippedFiles
    }
    
    public var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

/// Coordinator for library scanning operations
@MainActor
public final class LibraryScanCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var isScanning = false
    @Published public private(set) var progress: Double = 0.0
    @Published public private(set) var currentStatus: String = ""
    @Published public private(set) var scanResults: ScanResults?
    @Published public var showResults = false
    @Published public var dontShowResultsAgain = false
    
    // MARK: - Private Properties
    
    private let scanner: LibraryScannerProtocol
    private let indexer: LibraryIndexerProtocol
    private let libraryLocations: [URL]
    private let isFirstRun: Bool
    private var existingTracks: Set<String> = [] // Track file paths for comparison
    
    // MARK: - Initialisation
    
    public init(
        scanner: LibraryScannerProtocol = LibraryScanner(),
        indexer: LibraryIndexerProtocol = LibraryIndexer(),
        libraryLocations: [URL],
        isFirstRun: Bool
    ) {
        self.scanner = scanner
        self.indexer = indexer
        self.libraryLocations = libraryLocations
        self.isFirstRun = isFirstRun
    }
    
    // MARK: - Public Methods
    
    /// Start scanning all library locations
    public func startScan() async {
        guard !isScanning else { return }
        
        isScanning = true
        progress = 0.0
        currentStatus = "Preparing scan..."
        await loadExistingTracks()
        
        let startTime = Date()
        var scanStats = ScanStats()
        
        guard !libraryLocations.isEmpty else {
            currentStatus = "No library locations configured"
            isScanning = false
            return
        }
        
        await performScan(stats: &scanStats)
        let results = createResults(startTime: startTime, stats: scanStats)
        await handleScanCompletion(results: results)
        
        isScanning = false
        progress = 1.0
    }
    
    private func performScan(stats: inout ScanStats) async {
        let totalLocations = libraryLocations.count
        for (index, location) in libraryLocations.enumerated() {
            currentStatus = "Scanning: \(location.lastPathComponent)..."
            progress = Double(index) / Double(totalLocations)
            await scanLocation(location, stats: &stats)
            progress = Double(index + 1) / Double(totalLocations)
        }
    }
    
    private func createResults(startTime: Date, stats: ScanStats) -> ScanResults {
        let duration = Date().timeIntervalSince(startTime)
        return ScanResults(
            duration: duration,
            newFiles: stats.newFiles,
            updatedFiles: stats.updatedFiles,
            failedFiles: stats.failedFiles,
            skippedFiles: stats.skippedFiles
        )
    }
    
    private func handleScanCompletion(results: ScanResults) async {
        scanResults = results
        currentStatus = "Scan completed"
        if isFirstRun {
            showResults = true
        } else {
            await sendNotification(results: results)
        }
    }
    
    private func scanLocation(_ location: URL, stats: inout ScanStats) async {
        do {
            let tracks = try await scanner.scan(directory: location)
            stats.totalScanned += tracks.count
            
            // Process tracks
            for track in tracks {
                if existingTracks.contains(track.filePath) {
                    stats.updatedFiles += 1
                } else {
                    stats.newFiles += 1
                }
            }
            
            // Index the tracks
            try await indexer.index(tracks: tracks)
            
            // Update existing tracks set
            for track in tracks {
                existingTracks.insert(track.filePath)
            }
            
        } catch {
            Logger.dataLayer.error("Failed to scan location \(location.path): \(error.localizedDescription)")
            stats.failedFiles += 1
        }
    }
    
    // MARK: - Private Methods
    
    private func loadExistingTracks() async {
        let tracks = await indexer.getAllTracks()
        existingTracks = Set(tracks.map { $0.filePath })
    }
    
    @MainActor
    private func sendNotification(results: ScanResults) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        switch settings.authorizationStatus {
        case .notDetermined:
            let granted = try? await center.requestAuthorization(options: [.alert, .sound])
            if granted == true {
                await scheduleNotification(results: results, center: center)
            } else {
                Logger.userInterface.warning("Notification permission denied by user.")
                deliverFallbackNotification(results: results)
            }
        case .denied:
            Logger.userInterface.warning("Notification permission denied in system settings.")
            deliverFallbackNotification(results: results)
        case .authorized, .provisional, .ephemeral:
            await scheduleNotification(results: results, center: center)
        @unknown default:
            deliverFallbackNotification(results: results)
        }
    }
    
    @MainActor
    private func scheduleNotification(results: ScanResults, center: UNUserNotificationCenter) async {
        let content = UNMutableNotificationContent()
        content.title = "Library Scan Completed"
        // Format with line breaks for better readability
        let filesText: String
        if results.updatedFiles > 0 {
            filesText = "Added \(results.newFiles) new files, updated \(results.updatedFiles)."
        } else {
            filesText = "Added \(results.newFiles) new files."
        }
        content.body = "\(filesText)\nDuration: \(results.formattedDuration)."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        do {
            try await center.add(request)
            Logger.userInterface.info("macOS notification scheduled for scan completion.")
        } catch {
            Logger.userInterface.error("Failed to schedule notification: \(error.localizedDescription)")
            deliverFallbackNotification(results: results)
        }
    }
    
    @MainActor
    private func deliverFallbackNotification(results: ScanResults) {
        let alert = NSAlert()
        alert.messageText = "Library Scan Completed"
        // Format with line breaks for better readability
        let filesText: String
        if results.updatedFiles > 0 {
            filesText = "Added \(results.newFiles) new files, updated \(results.updatedFiles)."
        } else {
            filesText = "Added \(results.newFiles) new files."
        }
        alert.informativeText = "\(filesText)\nDuration: \(results.formattedDuration)."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        
        if let mainWindow = NSApp.mainWindow {
            alert.beginSheetModal(for: mainWindow) { _ in }
        } else {
            alert.runModal()
        }
        
        NSApp.requestUserAttention(.informationalRequest)
    }
}

/// Helper struct for tracking scan statistics
private struct ScanStats {
    var newFiles = 0
    var updatedFiles = 0
    var failedFiles = 0
    var skippedFiles = 0
    var totalScanned = 0
}
