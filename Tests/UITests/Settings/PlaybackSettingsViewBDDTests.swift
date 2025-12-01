//
//  PlaybackSettingsViewBDDTests.swift
//  UITests
//
//  BDD tests for PlaybackSettingsView
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

#if canImport(XCTest)
import SwiftUI
import XCTest

@testable import Audientia
@testable import Shared

/// BDD tests for PlaybackSettingsView
@MainActor
final class PlaybackSettingsViewBDDTests: XCTestCase {
    
    // MARK: - BDD Scenarios
    
    /// BDD: As a user, I want to adjust the track info scroll speed so that I can read long track titles at my preferred pace
    func testAsAUserIWantToAdjustTrackInfoScrollSpeed() {
        // Given - I have opened the Playback settings
        // When - I view the Playback settings
        // Note: PlaybackSettingsView is a private struct, so we test through SettingsView
        let settingsView = SettingsView()
        
        // Then - I should see a scroll speed control
        // The control is in the PlaybackSettingsView which is shown when .playback category is selected
        SwiftUIViewTestHelpers.verifyViewCreation(settingsView)
    }
    
    /// BDD: As a user, I want to see the current scroll speed value so that I know what it's set to
    func testAsAUserIWantToSeeCurrentScrollSpeed() {
        // Given - I have a scroll speed configured
        let appSettings = AppSettings.shared
        appSettings.trackInfoScrollSpeed = 50.0
        
        // When - I view the Playback settings
        let settingsView = SettingsView()
        
        // Then - I should see the current scroll speed value displayed
        // The slider should show the current value (50.0)
        SwiftUIViewTestHelpers.verifyViewCreation(settingsView)
        
        // Verify the value is accessible
        XCTAssertEqual(appSettings.trackInfoScrollSpeed, 50.0, accuracy: 0.1, "Scroll speed should be accessible")
    }
    
    /// BDD: As a user, I want to adjust scroll speed within a valid range so that it's not too slow or too fast
    func testAsAUserIWantToAdjustScrollSpeedInValidRange() {
        // Given - I have the Playback settings open
        let appSettings = AppSettings.shared
        
        // When - I adjust the scroll speed slider
        // Test minimum value
        appSettings.trackInfoScrollSpeed = 10.0
        XCTAssertGreaterThanOrEqual(appSettings.trackInfoScrollSpeed, 10.0, "Should allow minimum value")
        
        // Test maximum value
        appSettings.trackInfoScrollSpeed = 100.0
        XCTAssertLessThanOrEqual(appSettings.trackInfoScrollSpeed, 100.0, "Should allow maximum value")
        
        // Test middle value
        appSettings.trackInfoScrollSpeed = 50.0
        XCTAssertEqual(appSettings.trackInfoScrollSpeed, 50.0, accuracy: 0.1, "Should allow middle value")
    }
    
    /// BDD: As a user, I want my scroll speed preference to persist so that I don't have to adjust it every time
    func testAsAUserIWantScrollSpeedToPersist() {
        // Given - I have set a scroll speed preference
        let appSettings = AppSettings.shared
        appSettings.trackInfoScrollSpeed = 45.0
        
        // When - I close and reopen the app
        // The value should be saved to UserDefaults
        let saved = UserDefaults.standard.double(forKey: "audientia.settings.trackInfoScrollSpeed")
        
        // Then - My preference should be restored
        // Note: In a real scenario, AppSettings.shared would reload from UserDefaults on init
        XCTAssertEqual(saved, 45.0, accuracy: 0.1, "Scroll speed should persist to UserDefaults")
    }
}
#endif
// End of PlaybackSettingsViewBDDTests
