//
//  AudioVisualiserViewModelModePersistenceBDDTests.swift
//  UITests
//
//  BDD tests for AudioVisualiserViewModel mode persistence
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AudioCore
import Foundation
import Shared
import XCTest

@testable import Audientia

/// BDD tests for AudioVisualiserViewModel mode persistence
/// Tests that the last used visualizer mode is saved and restored
@MainActor
final class AudioVisualiserViewModelModePersistenceBDDTests: XCTestCase {
    private let visualisationModeKey = "audientia.settings.lastVisualisationMode"
    
    override func setUp() {
        super.setUp()
        // Clear saved visualisation mode to ensure clean test state
        UserDefaults.standard.removeObject(forKey: visualisationModeKey)
        UserDefaults.standard.synchronize()
        // Reset AppSettings singleton's cached value
        AppSettings.shared.lastVisualisationMode = nil
    }
    
    override func tearDown() {
        // Clean up after each test
        UserDefaults.standard.removeObject(forKey: visualisationModeKey)
        UserDefaults.standard.synchronize()
        AppSettings.shared.lastVisualisationMode = nil
        super.tearDown()
    }
    
    // MARK: - BDD Scenario 1: Default Mode on First Launch
    
    /// BDD: As a new user, when I first launch the app, 
    /// then the visualizer should default to "Discrete Frequencies" mode
    func testNewUserGetsDiscreteFrequenciesAsDefault() {
        // Given - I am a new user with no saved visualisation mode
        UserDefaults.standard.removeObject(forKey: visualisationModeKey)
        UserDefaults.standard.synchronize()
        AppSettings.shared.lastVisualisationMode = nil
        
        // When - I launch the app and the visualizer is initialized
        let viewModel = AudioVisualiserViewModel()
        
        // Then - The visualizer should default to "Discrete Frequencies"
        XCTAssertEqual(
            viewModel.visualisationMode,
            .discreteFrequencies,
            "New user should get Discrete Frequencies as default mode"
        )
    }
    
    // MARK: - BDD Scenario 2: Save Mode When Changed
    
    /// BDD: As a user, when I change the visualizer mode to "Radial Spectrum",
    /// then it should be saved for future launches
    func testUserChangesModeGetsSaved() async {
        // Given - I have the visualizer open with default mode
        let viewModel = AudioVisualiserViewModel()
        XCTAssertEqual(viewModel.visualisationMode, .discreteFrequencies)
        
        // When - I change the mode to "Radial Spectrum"
        viewModel.visualisationMode = .radialSpectrum
        
        // Then - The mode should be saved in AppSettings (synchronously)
        XCTAssertEqual(
            AppSettings.shared.lastVisualisationMode,
            VisualisationMode.radialSpectrum.rawValue,
            "Mode should be saved to AppSettings"
        )
        
        // And - The mode should be saved in UserDefaults
        let savedMode = UserDefaults.standard.string(forKey: visualisationModeKey)
        XCTAssertEqual(
            savedMode,
            VisualisationMode.radialSpectrum.rawValue,
            "Mode should be persisted to UserDefaults"
        )
    }
    
    /// BDD: As a user, when I change the visualizer mode multiple times,
    /// then the last selected mode should be saved
    func testLastSelectedModeIsSaved() async {
        // Given - I have the visualizer open
        let viewModel = AudioVisualiserViewModel()
        
        // When - I change modes multiple times
        viewModel.visualisationMode = .ledBars
        viewModel.visualisationMode = .lumiBars
        viewModel.visualisationMode = .roundBarsReflex
        
        // Then - The last selected mode should be saved (synchronously)
        XCTAssertEqual(
            AppSettings.shared.lastVisualisationMode,
            VisualisationMode.roundBarsReflex.rawValue,
            "Last selected mode should be saved"
        )
    }
    
    // MARK: - BDD Scenario 3: Restore Mode on App Launch
    
    /// BDD: As a user, when I previously selected "LED Bars" mode and close the app,
    /// then on next launch the visualizer should restore to "LED Bars" mode
    func testSavedModeIsRestoredOnLaunch() {
        // Given - I previously selected "LED Bars" mode
        let savedMode = VisualisationMode.ledBars.rawValue
        AppSettings.shared.lastVisualisationMode = savedMode
        UserDefaults.standard.set(savedMode, forKey: visualisationModeKey)
        UserDefaults.standard.synchronize()
        
        // When - I launch the app and the visualizer is initialized
        let viewModel = AudioVisualiserViewModel()
        
        // Then - The visualizer should restore to "LED Bars" mode
        XCTAssertEqual(
            viewModel.visualisationMode,
            .ledBars,
            "Saved mode should be restored on app launch"
        )
    }
    
    /// BDD: As a user, when I previously selected "Dual Channel Graph" mode,
    /// then on next launch it should be restored correctly
    func testDualChannelGraphModeIsRestored() {
        // Given - I previously selected "Dual Channel Graph" mode
        let savedMode = VisualisationMode.dualChannelGraph.rawValue
        AppSettings.shared.lastVisualisationMode = savedMode
        UserDefaults.standard.set(savedMode, forKey: visualisationModeKey)
        UserDefaults.standard.synchronize()
        
        // When - I launch the app
        let viewModel = AudioVisualiserViewModel()
        
        // Then - The visualizer should restore to "Dual Channel Graph" mode
        XCTAssertEqual(
            viewModel.visualisationMode,
            .dualChannelGraph,
            "Dual Channel Graph mode should be restored correctly"
        )
    }
    
    // MARK: - BDD Scenario 4: Invalid Saved Mode
    
    /// BDD: As a user, when I have an invalid saved mode in UserDefaults,
    /// then the visualizer should default to "Discrete Frequencies"
    func testInvalidSavedModeDefaultsToDiscreteFrequencies() {
        // Given - I have an invalid mode saved (e.g., from a future version)
        let invalidMode = "invalidMode"
        UserDefaults.standard.set(invalidMode, forKey: visualisationModeKey)
        UserDefaults.standard.synchronize()
        AppSettings.shared.lastVisualisationMode = invalidMode
        
        // When - I launch the app
        let viewModel = AudioVisualiserViewModel()
        
        // Then - The visualizer should default to "Discrete Frequencies"
        XCTAssertEqual(
            viewModel.visualisationMode,
            .discreteFrequencies,
            "Invalid saved mode should default to Discrete Frequencies"
        )
    }
    
    // MARK: - BDD Scenario 5: All Modes Can Be Saved and Restored
    
    /// BDD: As a user, when I select any visualizer mode,
    /// then it should be saved and restored correctly
    func testAllModesCanBeSavedAndRestored() {
        // Given - All available visualizer modes
        let allModes: [VisualisationMode] = [
            .discreteFrequencies,
            .radialSpectrum,
            .dualChannelGraph,
            .ledBars,
            .lumiBars,
            .roundBarsReflex
        ]
        
        // When & Then - Each mode can be saved and restored
        for mode in allModes {
            // Save the mode
            AppSettings.shared.lastVisualisationMode = mode.rawValue
            UserDefaults.standard.set(mode.rawValue, forKey: visualisationModeKey)
            UserDefaults.standard.synchronize()
            
            // Create a new view model (simulating app restart)
            let viewModel = AudioVisualiserViewModel()
            
            // Verify it's restored
            XCTAssertEqual(
                viewModel.visualisationMode,
                mode,
                "Mode \(mode.displayName) should be saved and restored correctly"
            )
        }
    }
    
    // MARK: - BDD Scenario 6: Mode Persistence Across Multiple Launches
    
    /// BDD: As a user, when I select a mode and launch the app multiple times,
    /// then the mode should persist across all launches
    func testModePersistsAcrossMultipleLaunches() {
        // Given - I select "LumiBars" mode
        let selectedMode = VisualisationMode.lumiBars
        AppSettings.shared.lastVisualisationMode = selectedMode.rawValue
        UserDefaults.standard.set(selectedMode.rawValue, forKey: visualisationModeKey)
        UserDefaults.standard.synchronize()
        
        // When - I launch the app multiple times (simulated by creating multiple view models)
        let viewModel1 = AudioVisualiserViewModel()
        let viewModel2 = AudioVisualiserViewModel()
        let viewModel3 = AudioVisualiserViewModel()
        
        // Then - The mode should persist across all launches
        XCTAssertEqual(viewModel1.visualisationMode, selectedMode, "First launch should restore mode")
        XCTAssertEqual(viewModel2.visualisationMode, selectedMode, "Second launch should restore mode")
        XCTAssertEqual(viewModel3.visualisationMode, selectedMode, "Third launch should restore mode")
    }
}
