//
//  SetupWizardViewModel.swift
//  Audientia
//
//  ViewModel for the setup wizard
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
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
    
    // MARK: - Private Properties
    
    private static let hasCompletedWizardKey = "audientia.setup.hasCompletedWizard"
    private static let libraryLocationsKey = "audientia.setup.libraryLocations"
    
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
    
    // MARK: - Initialization
    
    public init() {
        loadLibraryLocations()
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
    
    /// Complete the wizard and mark as completed
    public func completeWizard() {
        saveLibraryLocations()
        UserDefaults.standard.set(true, forKey: Self.hasCompletedWizardKey)
    }
    
    /// Add a library location
    public func addLibraryLocation(_ url: URL) {
        guard !libraryLocations.contains(url) else { return }
        libraryLocations.append(url)
    }
    
    /// Remove a library location
    public func removeLibraryLocation(_ url: URL) {
        libraryLocations.removeAll { $0 == url }
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
