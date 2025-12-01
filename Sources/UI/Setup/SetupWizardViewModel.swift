//
//  SetupWizardViewModel.swift
//  Audientia
//
//  ViewModel for the setup wizard
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import DataLayer
import Foundation
import os.log
import Shared
import SwiftUI

/// ViewModel for managing setup wizard state and navigation
@MainActor
public final class SetupWizardViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var currentStep: SetupWizardStep = .welcome
    @Published public var libraryLocations: [URL] = []
    @Published public var enableAutoScan: Bool = true
    @Published public var scanSchedule: ScanSchedule = .manual
    @Published public var scanCoordinator: LibraryScanCoordinator?
    
    // MARK: - Private Properties
    
    private static let hasCompletedWizardKey = "audientia.setup.hasCompletedWizard"
    private static let libraryLocationsKey = "audientia.setup.libraryLocations"
    private var previousLocations: [URL] = []
    private var backgroundScanTask: Task<Void, Never>?
    private let logger = Logger.userInterface
    
    // MARK: - Computed Properties
    
    public var canGoBack: Bool {
        currentStep != SetupWizardStep.allCases.first
    }
    
    public var canGoNext: Bool {
        currentStep != SetupWizardStep.allCases.last
    }
    
    public var hasCompletedWizard: Bool {
        UserDefaults.standard.bool(forKey: Self.hasCompletedWizardKey)
    }
    
    // MARK: - Initialisation
    
    public init() {
        loadLibraryLocations()
        previousLocations = libraryLocations
    }
    
    // MARK: - Public Methods
    
    /// Check if the wizard should be shown (first launch only)
    public static func shouldShowWizard() -> Bool {
        !UserDefaults.standard.bool(forKey: hasCompletedWizardKey)
    }
    
    /// Navigate to the next step
    public func nextStep() {
        guard let currentIndex = SetupWizardStep.allCases.firstIndex(of: currentStep),
              currentIndex < SetupWizardStep.allCases.count - 1 else {
            return
        }
        currentStep = SetupWizardStep.allCases[currentIndex + 1]
    }
    
    /// Navigate to the previous step
    public func previousStep() {
        guard let currentIndex = SetupWizardStep.allCases.firstIndex(of: currentStep),
              currentIndex > 0 else {
            return
        }
        currentStep = SetupWizardStep.allCases[currentIndex - 1]
    }
    
    /// Jump to a specific step
    public func goToStep(_ step: SetupWizardStep) {
        currentStep = step
    }
    
    /// Complete the wizard and mark as completed
    public func completeWizard() {
        let isFirstRun = !hasCompletedWizard
        let locationsChanged = libraryLocations != previousLocations
        saveLibraryLocations()
        UserDefaults.standard.set(true, forKey: Self.hasCompletedWizardKey)
        
        // Only trigger scan if locations changed or it's the first run
        if isFirstRun || locationsChanged {
            let coordinator = LibraryScanCoordinator(
                libraryLocations: libraryLocations,
                isFirstRun: isFirstRun
            )
            
            if isFirstRun {
                scanCoordinator = coordinator
                Task { await coordinator.startScan() }
            } else {
                // Cancel any pending scan from triggerScanIfNeeded
                backgroundScanTask?.cancel()
                backgroundScanTask = Task { await coordinator.startScan() }
            }
        }
        
        previousLocations = libraryLocations
    }
    
    /// Add a library location
    public func addLibraryLocation(_ url: URL) {
        guard !libraryLocations.contains(url) else { return }
        libraryLocations.append(url)
        // Don't trigger scan during wizard - will be triggered on completion
        if hasCompletedWizard {
            triggerScanIfNeeded()
        }
    }
    
    /// Remove a library location
    public func removeLibraryLocation(_ url: URL) {
        libraryLocations.removeAll { $0 == url }
        // Update previous locations to prevent scan on next add
        // Don't trigger scan when removing - only when adding locations
        if hasCompletedWizard {
            previousLocations = libraryLocations
        }
    }
    
    /// Trigger scan if folders changed (for subsequent runs)
    /// Only scans when locations are added, not when they're removed
    private func triggerScanIfNeeded() {
        guard hasCompletedWizard else { return }
        guard libraryLocations != previousLocations else { return }
        
        // Only trigger scan if locations were added (not removed)
        // Check if current locations contain all previous locations plus new ones
        let previousSet = Set(previousLocations)
        let currentSet = Set(libraryLocations)
        let addedLocations = currentSet.subtracting(previousSet)
        
        // Only scan if there are new locations added
        guard !addedLocations.isEmpty else {
            // Locations were removed, just update previousLocations without scanning
            previousLocations = libraryLocations
            return
        }
        
        logger.info("Library locations changed. Scheduling background scan.")
        previousLocations = libraryLocations
        backgroundScanTask?.cancel()
        let locationsSnapshot = libraryLocations
        backgroundScanTask = Task { [logger] in
            let coordinator = LibraryScanCoordinator(
                libraryLocations: locationsSnapshot,
                isFirstRun: false
            )
            await coordinator.startScan()
            logger.info("Background scan finished.")
        }
    }
    
    // MARK: - Private Methods
    
    private func loadLibraryLocations() {
        guard let data = UserDefaults.standard.data(forKey: Self.libraryLocationsKey),
              let urlStrings = try? JSONDecoder().decode([String].self, from: data) else {
            // Set default locations
            setDefaultLocations()
            return
        }
        libraryLocations = urlStrings.compactMap { URL(string: $0) }
    }
    
    private func saveLibraryLocations() {
        let urlStrings = libraryLocations.map { $0.absoluteString }
        if let data = try? JSONEncoder().encode(urlStrings) {
            UserDefaults.standard.set(data, forKey: Self.libraryLocationsKey)
        }
    }
    
    private func setDefaultLocations() {
        var defaults: [URL] = []
        
        // Add macOS Music directory
        if let music = FileManager.default.urls(for: .musicDirectory, in: .userDomainMask).first {
            defaults.append(music)
        }
        
        libraryLocations = defaults
    }
}

/// Scan schedule options for library scanning
public enum ScanSchedule: String, CaseIterable {
    case manual
    case onStartup
    case daily
    case weekly
    
    public var displayName: String {
        switch self {
        case .manual:
            return "Manual"
        case .onStartup:
            return "On Startup"
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        }
    }
}
