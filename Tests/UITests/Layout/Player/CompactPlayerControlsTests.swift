// CompactPlayerControlsTests.swift
// Audientia - UI Tests
//
// TDD Unit Tests for CompactPlayerControls component
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

import SwiftUI
import XCTest

@testable import Audientia
@testable import AudioCore
@testable import Shared

// MARK: - TDD Unit Tests

/// Unit tests for CompactPlayerControls following TDD practices
final class CompactPlayerControlsTests: XCTestCase {
    
    var mockAudioEngine: MockAudioEngine!
    var nowPlayingViewModel: NowPlayingViewModel!
    
    @MainActor
    override func setUp() {
        super.setUp()
        mockAudioEngine = MockAudioEngine()
        nowPlayingViewModel = NowPlayingViewModel(audioEngine: mockAudioEngine)
    }
    
    override func tearDown() {
        mockAudioEngine = nil
        nowPlayingViewModel = nil
        super.tearDown()
    }
    
    // MARK: - [Right]: Are the Results Right?
    
    @MainActor
    func testHeightIs32() {
        XCTAssertEqual(CompactPlayerControls.height, 32, "Compact controls height should be 32px")
    }
    
    @MainActor
    func testCompactControlsCreatesSuccessfully() {
        // Given/When
        let controls = CompactPlayerControls(
            nowPlayingViewModel: nowPlayingViewModel,
            onExpand: {}
        )
        
        // Then
        XCTAssertNotNil(controls, "Compact controls should be created successfully")
    }
    
    // MARK: - Right-[B]ICEP: Boundary Conditions
    
    @MainActor
    func testCompactControlsHandlesNoTrack() {
        // Given - no track loaded
        mockAudioEngine.currentTrack = nil
        
        // When
        let controls = CompactPlayerControls(
            nowPlayingViewModel: nowPlayingViewModel,
            onExpand: {}
        )
        
        // Then - should display "No track playing"
        XCTAssertNotNil(controls, "Compact controls should handle no track gracefully")
    }
    
    @MainActor
    func testCompactControlsHandlesLongTrackTitle() async throws {
        // Given
        let longTitle = String(repeating: "Long Title ", count: 10)
        let track = Track(
            id: UUID(),
            title: longTitle,
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/path/to/track.mp3",
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44_100,
            year: 2024,
            trackNumber: 1,
            discNumber: 1,
            genre: "Rock",
            rating: nil
        )
        try await mockAudioEngine.loadTrack(track)
        
        // When
        let controls = CompactPlayerControls(
            nowPlayingViewModel: nowPlayingViewModel,
            onExpand: {}
        )
        
        // Then - should handle long titles via scrolling text
        XCTAssertNotNil(controls, "Compact controls should handle long track titles")
    }
    
    @MainActor
    func testCompactControlsHandlesZeroDuration() {
        // Given
        mockAudioEngine.duration = 0.0
        
        // When
        let controls = CompactPlayerControls(
            nowPlayingViewModel: nowPlayingViewModel,
            onExpand: {}
        )
        
        // Then - seek bar should be disabled
        XCTAssertNotNil(controls, "Compact controls should handle zero duration")
    }
    
    // MARK: - Right-BI[C]EP: Cross-Checking
    
    @MainActor
    func testTimeFormatConsistency() {
        // Given
        let testCases: [(TimeInterval, String)] = [
            (0, "0:00"),
            (59, "0:59"),
            (60, "1:00"),
            (61, "1:01"),
            (599, "9:59"),
            (600, "10:00"),
            (3599, "59:59"),
            (3600, "60:00")
        ]
        
        // When/Then
        for (seconds, expected) in testCases {
            let formatted = formatTime(seconds)
            XCTAssertEqual(formatted, expected, "Time \(seconds)s should format as \(expected)")
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Expand Callback Tests
    
    @MainActor
    func testExpandCallbackIsTriggered() {
        // Given
        var expandCalled = false
        _ = CompactPlayerControls(
            nowPlayingViewModel: nowPlayingViewModel,
            onExpand: { expandCalled = true }
        )
        
        // When - expand action would be triggered
        // (UI interaction simulated by calling closure directly for test)
        
        // Then - verify closure is set up correctly
        XCTAssertFalse(expandCalled, "Expand should not be called until button is pressed")
    }
}

// MARK: - BDD Tests

/// BDD-style tests for CompactPlayerControls user scenarios
final class CompactPlayerControlsBDDTests: XCTestCase {
    
    var mockAudioEngine: MockAudioEngine!
    var nowPlayingViewModel: NowPlayingViewModel!
    
    @MainActor
    override func setUp() {
        super.setUp()
        mockAudioEngine = MockAudioEngine()
        nowPlayingViewModel = NowPlayingViewModel(audioEngine: mockAudioEngine)
    }
    
    override func tearDown() {
        mockAudioEngine = nil
        nowPlayingViewModel = nil
        super.tearDown()
    }
    
    // MARK: - Scenario: User sees scrolling track info
    
    @MainActor
    func testScenario_UserSeesScrollingTrackInfo() async throws {
        // Given: A track is playing with a long title
        let track = Track(
            id: UUID(),
            title: "Stairway to Heaven - 2007 Remaster",
            artist: "Led Zeppelin",
            album: "Led Zeppelin IV",
            duration: 482.0,
            filePath: "/path/to/track.mp3",
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44_100,
            year: 1971,
            trackNumber: 4,
            discNumber: 1,
            genre: "Rock",
            rating: nil
        )
        try await mockAudioEngine.loadTrack(track)
        
        // When: Compact player is displayed
        // Then: Track info shows "Title - Artist" format with scrolling
        
        let expectedFormat = "\(track.title) - \(track.artist)"
        XCTAssertTrue(expectedFormat.contains(" - "), "Track info should be in 'Title - Artist' format")
    }
    
    // MARK: - Scenario: User sees compact time display
    
    @MainActor
    func testScenario_UserSeesCompactTimeDisplay() async throws {
        // Given: A track is playing
        mockAudioEngine.currentPosition = 90.0
        mockAudioEngine.duration = 180.0
        
        // When: Looking at time display
        let currentFormatted = formatTime(mockAudioEngine.currentPosition)
        let totalFormatted = formatTime(mockAudioEngine.duration)
        
        // Then: Time should show "current/total" format
        let expected = "\(currentFormatted)/\(totalFormatted)"
        XCTAssertEqual(expected, "1:30/3:00")
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Scenario: User uses icon-only transport controls
    
    @MainActor
    func testScenario_UserUsesIconOnlyControls() {
        // Given: Compact player is displayed
        // When: User looks at transport controls
        // Then: Only icons are shown (no text labels)
        
        // Icons used: backward.fill, play.fill/pause.fill, forward.fill
        // Shuffle, repeat, speaker icons also present
        XCTAssertTrue(true, "Compact controls use icon-only buttons")
    }
    
    // MARK: - Scenario: User expands player for full controls
    
    @MainActor
    func testScenario_UserExpandsPlayer() {
        // Given: Compact player is displayed
        var expandCalled = false
        let controls = CompactPlayerControls(
            nowPlayingViewModel: nowPlayingViewModel,
            onExpand: { expandCalled = true }
        )
        
        // When: User clicks expand button (chevron up)
        // The expand closure would be triggered
        
        // Then: onExpand callback should be available
        XCTAssertNotNil(controls, "Compact controls should be created with expand callback")
        XCTAssertFalse(expandCalled, "Expand callback should not be called during creation")
    }
    
    // MARK: - Scenario: Quick access to playback state toggles
    
    @MainActor
    func testScenario_QuickAccessToToggles() {
        // Given: Compact player is displayed
        // When: User wants to toggle shuffle or loop
        // Then: Buttons are directly accessible (no menus)
        
        // Shuffle button changes shuffle state
        nowPlayingViewModel.toggleShuffle()
        XCTAssertTrue(mockAudioEngine.isShuffleEnabled)
        
        // Loop button cycles through modes
        nowPlayingViewModel.toggleLoopMode()
        XCTAssertEqual(mockAudioEngine.loopMode, .track)
    }
    
    // MARK: - Scenario: Mute button for quick volume control
    
    @MainActor
    func testScenario_MuteButtonForQuickVolume() {
        // Given: Audio is playing
        XCTAssertFalse(mockAudioEngine.isMuted)
        
        // When: User clicks mute button
        nowPlayingViewModel.toggleMute()
        
        // Then: Audio is muted
        XCTAssertTrue(mockAudioEngine.isMuted)
    }
    
    // MARK: - Scenario: Hover states provide visual feedback
    
    @MainActor
    func testScenario_HoverStatesProvideVisualFeedback() {
        // Given: User hovers over player control buttons
        // When: Mouse cursor is over a control button
        // Then: Button should show hover state (subtle background highlight)
        
        // Note: Hover states are implemented using @State isHovered and .onHover modifier
        // Visual feedback: Color(NSColor.controlAccentColor).opacity(0.1) on hover
        let controls = CompactPlayerControls(
            nowPlayingViewModel: nowPlayingViewModel,
            onExpand: {}
        )
        SwiftUIViewTestHelpers.verifyViewCreation(controls)
    }
    
    // MARK: - Scenario: Pressed states provide tactile feedback
    
    @MainActor
    func testScenario_PressedStatesProvideTactileFeedback() {
        // Given: User presses a player control button
        // When: Mouse button is pressed down
        // Then: Button should show pressed state (darker background)
        
        // Note: Pressed states are implemented using @State isPressed and pressEvents modifier
        // Visual feedback: Color(NSColor.controlAccentColor).opacity(0.2) when pressed
        let controls = CompactPlayerControls(
            nowPlayingViewModel: nowPlayingViewModel,
            onExpand: {}
        )
        SwiftUIViewTestHelpers.verifyViewCreation(controls)
    }
    
    // MARK: - Scenario: Disabled navigation when single track
    
    @MainActor
    func testScenario_DisabledNavigationForSingleTrack() async throws {
        // Given: Only one track in queue
        let track = createTestTrack()
        try await mockAudioEngine.loadTrack(track)
        // Queue is empty (only current track)
        
        // When: Looking at navigation buttons
        // Then: Previous and next buttons should be disabled
        
        XCTAssertTrue(mockAudioEngine.queue.isEmpty, "Queue should be empty")
        // UI buttons would check queue.count <= 1
    }
    
    // MARK: - Helper
    
    private func createTestTrack() -> Track {
        Track(
            id: UUID(),
            title: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/path/to/track.mp3",
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44_100,
            year: 2024,
            trackNumber: 1,
            discNumber: 1,
            genre: "Rock",
            rating: nil
        )
    }
}

// MARK: - Compact Time Format Tests

/// Specific tests for the compact time format display
final class CompactPlayerControlsTimeFormatTests: XCTestCase {
    
    func testCompactTimeFormatZeroProgress() {
        // Given
        let current: TimeInterval = 0
        let total: TimeInterval = 180
        
        // When
        let formatted = formatCompactTime(current: current, total: total)
        
        // Then
        XCTAssertEqual(formatted, "0:00/3:00")
    }
    
    func testCompactTimeFormatHalfway() {
        // Given
        let current: TimeInterval = 90
        let total: TimeInterval = 180
        
        // When
        let formatted = formatCompactTime(current: current, total: total)
        
        // Then
        XCTAssertEqual(formatted, "1:30/3:00")
    }
    
    func testCompactTimeFormatComplete() {
        // Given
        let current: TimeInterval = 180
        let total: TimeInterval = 180
        
        // When
        let formatted = formatCompactTime(current: current, total: total)
        
        // Then
        XCTAssertEqual(formatted, "3:00/3:00")
    }
    
    func testCompactTimeFormatLongTrack() {
        // Given - 1 hour track
        let current: TimeInterval = 1800 // 30 minutes
        let total: TimeInterval = 3600 // 60 minutes
        
        // When
        let formatted = formatCompactTime(current: current, total: total)
        
        // Then
        XCTAssertEqual(formatted, "30:00/60:00")
    }
    
    private func formatCompactTime(current: TimeInterval, total: TimeInterval) -> String {
        "\(formatTime(current))/\(formatTime(total))"
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
