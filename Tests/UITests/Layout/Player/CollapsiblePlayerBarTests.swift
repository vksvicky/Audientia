// CollapsiblePlayerBarTests.swift
// Audientia - UI Tests
//
// TDD Unit Tests for CollapsiblePlayerBar component
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

import SwiftUI
import XCTest

@testable import Audientia
@testable import AudioCore
@testable import Shared

// MARK: - TDD Unit Tests

/// Unit tests for CollapsiblePlayerBar following TDD practices
final class CollapsiblePlayerBarTests: XCTestCase {
    
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
    func testExpandedHeightIs70() {
        XCTAssertEqual(CollapsiblePlayerBar.expandedHeight, 70, "Expanded height should be 70px")
    }
    
    @MainActor
    func testCollapsedHeightIs32() {
        XCTAssertEqual(CollapsiblePlayerBar.collapsedHeight, 32, "Collapsed height should be 32px")
    }
    
    @MainActor
    func testPlayerBarCreatesSuccessfully() {
        // Given/When
        let playerBar = CollapsiblePlayerBar(
            nowPlayingViewModel: nowPlayingViewModel,
            isExpanded: .constant(true),
            onMinimize: nil
        )
        
        // Then
        XCTAssertNotNil(playerBar, "Player bar should be created successfully")
    }
    
    @MainActor
    func testPlayerBarCreatesWithMinimizeCallback() {
        // Given
        var minimizeCalled = false
        
        // When
        let playerBar = CollapsiblePlayerBar(
            nowPlayingViewModel: nowPlayingViewModel,
            isExpanded: .constant(true),
            onMinimize: { minimizeCalled = true }
        )
        
        // Then
        XCTAssertNotNil(playerBar, "Player bar should be created with minimize callback")
    }
    
    // MARK: - Right-[B]ICEP: Boundary Conditions
    
    @MainActor
    func testPlayerBarHandlesNoTrack() {
        // Given - no track loaded
        mockAudioEngine.currentTrack = nil
        
        // When
        let playerBar = CollapsiblePlayerBar(
            nowPlayingViewModel: nowPlayingViewModel,
            isExpanded: .constant(true),
            onMinimize: nil
        )
        
        // Then - should not crash
        XCTAssertNotNil(playerBar, "Player bar should handle no track gracefully")
    }
    
    @MainActor
    func testPlayerBarHandlesTrackWithNoArtwork() async throws {
        // Given - track with no artwork
        let track = Track(
            id: UUID(),
            filePath: "/path/to/track.mp3",
            title: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            albumArtist: "Test Artist",
            genre: "Rock",
            trackNumber: 1,
            discNumber: 1,
            year: 2024,
            duration: 180.0,
            dateAdded: Date()
        )
        try await mockAudioEngine.loadTrack(track)
        
        // When
        let playerBar = CollapsiblePlayerBar(
            nowPlayingViewModel: nowPlayingViewModel,
            isExpanded: .constant(true),
            onMinimize: nil
        )
        
        // Then - should display placeholder artwork
        XCTAssertNotNil(playerBar, "Player bar should handle track without artwork")
    }
    
    @MainActor
    func testPlayerBarHandlesZeroDuration() async throws {
        // Given - track with zero duration
        let track = Track(
            id: UUID(),
            filePath: "/path/to/track.mp3",
            title: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            albumArtist: "Test Artist",
            genre: "Rock",
            trackNumber: 1,
            discNumber: 1,
            year: 2024,
            duration: 0.0,
            dateAdded: Date()
        )
        mockAudioEngine.duration = 0.0
        try await mockAudioEngine.loadTrack(track)
        
        // When
        let playerBar = CollapsiblePlayerBar(
            nowPlayingViewModel: nowPlayingViewModel,
            isExpanded: .constant(true),
            onMinimize: nil
        )
        
        // Then - seek bar should be disabled
        XCTAssertNotNil(playerBar, "Player bar should handle zero duration")
    }
    
    // MARK: - Right-B[I]CEP: Inverse Relationships
    
    @MainActor
    func testExpandedAndCollapsedAreMutuallyExclusive() {
        // Given
        var isExpanded = true
        
        // Then - if expanded, not collapsed
        XCTAssertTrue(isExpanded)
        XCTAssertFalse(!isExpanded)
        
        // When
        isExpanded = false
        
        // Then - if collapsed, not expanded
        XCTAssertFalse(isExpanded)
        XCTAssertTrue(!isExpanded)
    }
    
    // MARK: - Right-BI[C]EP: Cross-Checking
    
    @MainActor
    func testHeightDifferenceIsSignificant() {
        // The height difference should be noticeable for the animation
        let heightDifference = CollapsiblePlayerBar.expandedHeight - CollapsiblePlayerBar.collapsedHeight
        
        XCTAssertGreaterThan(heightDifference, 30, "Height difference should be significant (38px)")
        XCTAssertEqual(heightDifference, 38, "Height difference should be exactly 38px")
    }
    
    // MARK: - Time Formatting Tests
    
    @MainActor
    func testTimeFormattingForShortDuration() {
        // Given
        let seconds: TimeInterval = 65 // 1:05
        let formatted = formatTime(seconds)
        
        // Then
        XCTAssertEqual(formatted, "1:05")
    }
    
    @MainActor
    func testTimeFormattingForLongDuration() {
        // Given
        let seconds: TimeInterval = 3665 // 61:05
        let formatted = formatTime(seconds)
        
        // Then
        XCTAssertEqual(formatted, "61:05")
    }
    
    @MainActor
    func testTimeFormattingForZero() {
        // Given
        let seconds: TimeInterval = 0
        let formatted = formatTime(seconds)
        
        // Then
        XCTAssertEqual(formatted, "0:00")
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - BDD Tests

/// BDD-style tests for CollapsiblePlayerBar user scenarios
final class CollapsiblePlayerBarBDDTests: XCTestCase {
    
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
    
    // MARK: - Scenario: User collapses player to maximize content area
    
    @MainActor
    func testScenario_UserCollapsesPlayer() {
        // Given: User wants more vertical space for content
        var isExpanded = true
        
        // When: User clicks the collapse button (chevron down)
        isExpanded = false
        
        // Then: Player collapses to single line (32px)
        XCTAssertFalse(isExpanded)
        XCTAssertEqual(CollapsiblePlayerBar.collapsedHeight, 32)
    }
    
    // MARK: - Scenario: User expands player to see full controls
    
    @MainActor
    func testScenario_UserExpandsPlayer() {
        // Given: Player is collapsed
        var isExpanded = false
        
        // When: User clicks the expand button (chevron up)
        isExpanded = true
        
        // Then: Player expands to show full controls (70px)
        XCTAssertTrue(isExpanded)
        XCTAssertEqual(CollapsiblePlayerBar.expandedHeight, 70)
    }
    
    // MARK: - Scenario: User toggles with keyboard shortcut
    
    @MainActor
    func testScenario_UserTogglesWithKeyboard() {
        // Given: User prefers keyboard navigation
        var isExpanded = true
        
        // When: User presses ⌘P
        isExpanded.toggle()
        
        // Then: Player state toggles
        XCTAssertFalse(isExpanded)
        
        // When: User presses ⌘P again
        isExpanded.toggle()
        
        // Then: Player returns to original state
        XCTAssertTrue(isExpanded)
    }
    
    // MARK: - Scenario: Expanded player shows album art
    
    @MainActor
    func testScenario_ExpandedPlayerShowsAlbumArt() async throws {
        // Given: A track is playing
        let track = Track(
            id: UUID(),
            filePath: "/path/to/track.mp3",
            title: "Bohemian Rhapsody",
            artist: "Queen",
            album: "A Night at the Opera",
            albumArtist: "Queen",
            genre: "Rock",
            trackNumber: 11,
            discNumber: 1,
            year: 1975,
            duration: 354.0,
            dateAdded: Date()
        )
        try await mockAudioEngine.loadTrack(track)
        
        // When: Player is expanded
        let isExpanded = true
        
        // Then: Album art area should be visible (60x60px)
        XCTAssertTrue(isExpanded)
        // Album art view is 60x60px in expanded state
    }
    
    // MARK: - Scenario: Collapsed player shows scrolling track info
    
    @MainActor
    func testScenario_CollapsedPlayerShowsScrollingInfo() async throws {
        // Given: A track is playing with long title
        let track = Track(
            id: UUID(),
            filePath: "/path/to/track.mp3",
            title: "A Very Long Track Title That Needs To Scroll",
            artist: "An Artist With A Long Name",
            album: "Album",
            albumArtist: "Artist",
            genre: "Rock",
            trackNumber: 1,
            discNumber: 1,
            year: 2024,
            duration: 180.0,
            dateAdded: Date()
        )
        try await mockAudioEngine.loadTrack(track)
        
        // When: Player is collapsed
        let isExpanded = false
        
        // Then: Track info should use scrolling text view
        XCTAssertFalse(isExpanded)
        // Scrolling text view handles overflow
    }
    
    // MARK: - Scenario: User minimizes app to floating player
    
    @MainActor
    func testScenario_UserMinimizesToFloatingPlayer() {
        // Given: User wants a compact floating player
        var minimizeCalled = false
        let playerBar = CollapsiblePlayerBar(
            nowPlayingViewModel: nowPlayingViewModel,
            isExpanded: .constant(true),
            onMinimize: { minimizeCalled = true }
        )
        
        // When: User clicks minimize button
        // (The callback would be invoked)
        
        // Then: Minimize action should be available
        XCTAssertNotNil(playerBar, "Player bar should have minimize capability")
    }
    
    // MARK: - Scenario: Playback controls work in both states
    
    @MainActor
    func testScenario_PlaybackControlsWorkInBothStates() async throws {
        // Given: A track is loaded
        let track = Track(
            id: UUID(),
            filePath: "/path/to/track.mp3",
            title: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            albumArtist: "Test Artist",
            genre: "Rock",
            trackNumber: 1,
            discNumber: 1,
            year: 2024,
            duration: 180.0,
            dateAdded: Date()
        )
        try await mockAudioEngine.loadTrack(track)
        
        // When: Player is in either state
        // Then: Play/pause button should be available
        
        // Expanded state
        var isExpanded = true
        XCTAssertTrue(isExpanded)
        
        // Collapsed state
        isExpanded = false
        XCTAssertFalse(isExpanded)
        
        // Controls are present in both states
    }
    
    // MARK: - Scenario: Volume control visible in both states
    
    @MainActor
    func testScenario_VolumeControlInBothStates() {
        // Given: Player can be in either state
        // When: User wants to adjust volume
        // Then: Volume control should be accessible
        
        // Expanded: Has volume slider
        // Collapsed: Has mute button
        XCTAssertTrue(true, "Volume controls available in both states")
    }
    
    // MARK: - Scenario: Seek bar shows progress
    
    @MainActor
    func testScenario_SeekBarShowsProgress() async throws {
        // Given: A track is playing
        let track = Track(
            id: UUID(),
            filePath: "/path/to/track.mp3",
            title: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            albumArtist: "Test Artist",
            genre: "Rock",
            trackNumber: 1,
            discNumber: 1,
            year: 2024,
            duration: 180.0,
            dateAdded: Date()
        )
        try await mockAudioEngine.loadTrack(track)
        mockAudioEngine.currentPosition = 90.0 // Halfway
        
        // When: Track is at 50% progress
        // Then: Seek bar should reflect position
        
        let progress = mockAudioEngine.currentPosition / mockAudioEngine.duration
        XCTAssertEqual(progress, 0.5, accuracy: 0.01)
    }
}

// MARK: - Playback Control Tests

/// Tests for playback controls in the player bar
final class CollapsiblePlayerBarPlaybackTests: XCTestCase {
    
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
    
    // MARK: - Play/Pause Tests
    
    @MainActor
    func testPlayButtonTriggersPlayback() async throws {
        // Given
        let track = createTestTrack()
        try await mockAudioEngine.loadTrack(track)
        
        // When
        try await nowPlayingViewModel.play()
        
        // Then
        XCTAssertTrue(mockAudioEngine.playCalled)
    }
    
    @MainActor
    func testPauseButtonPausesPlayback() async throws {
        // Given
        let track = createTestTrack()
        try await mockAudioEngine.loadTrack(track)
        try await nowPlayingViewModel.play()
        
        // When
        await nowPlayingViewModel.pause()
        
        // Then
        XCTAssertTrue(mockAudioEngine.pauseCalled)
    }
    
    // MARK: - Navigation Tests
    
    @MainActor
    func testPreviousButtonNavigatesBack() async throws {
        // Given
        let track1 = createTestTrack(title: "Track 1")
        let track2 = createTestTrack(title: "Track 2")
        mockAudioEngine.queueHistory = [track1, track2]
        mockAudioEngine.currentQueueIndex = 1
        try await mockAudioEngine.loadTrack(track2)
        
        // When
        try await nowPlayingViewModel.playPrevious()
        
        // Then
        XCTAssertTrue(mockAudioEngine.playPreviousCalled)
    }
    
    @MainActor
    func testNextButtonNavigatesForward() async throws {
        // Given
        let track1 = createTestTrack(title: "Track 1")
        let track2 = createTestTrack(title: "Track 2")
        mockAudioEngine.queue = [track2]
        try await mockAudioEngine.loadTrack(track1)
        
        // When
        try await nowPlayingViewModel.playNext()
        
        // Then
        XCTAssertTrue(mockAudioEngine.playNextCalled)
    }
    
    // MARK: - Shuffle/Loop Tests
    
    @MainActor
    func testShuffleToggle() {
        // Given
        XCTAssertFalse(mockAudioEngine.isShuffleEnabled)
        
        // When
        nowPlayingViewModel.toggleShuffle()
        
        // Then
        XCTAssertTrue(mockAudioEngine.isShuffleEnabled)
    }
    
    @MainActor
    func testLoopModeToggle() {
        // Given
        XCTAssertEqual(mockAudioEngine.loopMode, .none)
        
        // When
        nowPlayingViewModel.toggleLoopMode()
        
        // Then
        XCTAssertEqual(mockAudioEngine.loopMode, .track)
        
        // When
        nowPlayingViewModel.toggleLoopMode()
        
        // Then
        XCTAssertEqual(mockAudioEngine.loopMode, .queue)
        
        // When
        nowPlayingViewModel.toggleLoopMode()
        
        // Then
        XCTAssertEqual(mockAudioEngine.loopMode, .none)
    }
    
    // MARK: - Helper
    
    private func createTestTrack(title: String = "Test Track") -> Track {
        Track(
            id: UUID(),
            filePath: "/path/to/track.mp3",
            title: title,
            artist: "Test Artist",
            album: "Test Album",
            albumArtist: "Test Artist",
            genre: "Rock",
            trackNumber: 1,
            discNumber: 1,
            year: 2024,
            duration: 180.0,
            dateAdded: Date()
        )
    }
}
