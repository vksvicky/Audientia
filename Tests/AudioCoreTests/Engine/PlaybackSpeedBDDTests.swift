//
//  PlaybackSpeedBDDTests.swift
//  AudioCoreTests
//
//  BDD tests for playback speed scenarios
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

#if canImport(XCTest)
@testable import AudioCore
@testable import Shared
import XCTest

/// BDD-style test suite for playback speed functionality
/// BDD: As a user, I want to control playback speed from 0.5x to 4x
@MainActor
final class PlaybackSpeedBDDTests: XCTestCase {
    
    // MARK: - Scenario: User Changes Playback Speed
    
    /// BDD: Given audio is playing, when I change playback speed to 2x, then audio should play at double speed
    func testChangePlaybackSpeedToDouble() async throws {
        // Given: Audio engine with a loaded track
        let mockEngine = MockNativeAudioEngine()
        let engine = AudioEngine(
            fileSystem: MockFileSystem(),
            nativeEngine: mockEngine
        )
        
        // Load a track (mock implementation)
        let track = Track(
            id: UUID(),
            title: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/test/path.mp3"
        )
        try await engine.loadTrack(track)
        
        // When: Setting playback speed to 2x
        engine.playbackSpeed = .double
        
        // Then: Native engine rate should be 2.0
        XCTAssertEqual(mockEngine.getRate(), 2.0, accuracy: 0.01)
        XCTAssertEqual(engine.playbackSpeed, .double)
    }
    
    /// BDD: Given audio is playing, when I change playback speed to 0.5x, then audio should play at half speed
    func testChangePlaybackSpeedToHalf() async throws {
        // Given: Audio engine with a loaded track
        let mockEngine = MockNativeAudioEngine()
        let engine = AudioEngine(
            fileSystem: MockFileSystem(),
            nativeEngine: mockEngine
        )
        
        let track = Track(
            id: UUID(),
            title: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/test/path.mp3"
        )
        try await engine.loadTrack(track)
        
        // When: Setting playback speed to 0.5x
        engine.playbackSpeed = .half
        
        // Then: Native engine rate should be 0.5
        XCTAssertEqual(mockEngine.getRate(), 0.5, accuracy: 0.01)
        XCTAssertEqual(engine.playbackSpeed, .half)
    }
    
    /// BDD: Given audio is playing at 2x, when I change to 1x, then audio should play at normal speed
    func testChangePlaybackSpeedFromDoubleToNormal() async throws {
        // Given: Audio engine playing at 2x speed
        let mockEngine = MockNativeAudioEngine()
        let engine = AudioEngine(
            fileSystem: MockFileSystem(),
            nativeEngine: mockEngine
        )
        
        let track = Track(
            id: UUID(),
            title: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/test/path.mp3"
        )
        try await engine.loadTrack(track)
        engine.playbackSpeed = .double
        
        // When: Changing to normal speed
        engine.playbackSpeed = .normal
        
        // Then: Native engine rate should be 1.0
        XCTAssertEqual(mockEngine.getRate(), 1.0, accuracy: 0.01)
        XCTAssertEqual(engine.playbackSpeed, .normal)
    }
    
    // MARK: - Scenario: Playback Speed Persistence
    
    /// BDD: Given I set playback speed to 1.5x, when I close and reopen the app, then speed should be restored to 1.5x
    func testPlaybackSpeedPersistence() {
        // Given: AppSettings with saved playback speed
        let savedSpeed = PlaybackSpeed.oneAndHalf
        AppSettings.shared.playbackSpeed = savedSpeed
        
        // When: Creating a new AudioEngine
        let engine = AudioEngine()
        
        // Then: Engine should load saved speed
        XCTAssertEqual(engine.playbackSpeed, savedSpeed)
    }
    
    /// BDD: Given I haven't set a playback speed, when I create an AudioEngine, then it should use default (1x) speed
    func testPlaybackSpeedDefaultOnFirstLaunch() {
        // Given: AppSettings with default speed
        AppSettings.shared.playbackSpeed = .normal
        
        // When: Creating a new AudioEngine
        let engine = AudioEngine()
        
        // Then: Engine should use default speed
        XCTAssertEqual(engine.playbackSpeed, .normal)
    }
    
    // MARK: - Scenario: Visualization Speed Matching
    
    /// BDD: Given audio is playing at 2x speed, when visualization is running, then visualization should update at 2x rate
    func testVisualizationSpeedMatchesPlaybackSpeed() async {
        // Given: Audio engine at 2x speed
        let mockEngine = MockNativeAudioEngine()
        let engine = AudioEngine(
            fileSystem: MockFileSystem(),
            nativeEngine: mockEngine
        )
        engine.playbackSpeed = .double
        
        // When: Creating visualization view model
        let viewModel = AudioVisualiserViewModel(audioEngine: engine)
        
        // Then: Playback speed multiplier should be 2.0
        XCTAssertEqual(viewModel.playbackSpeedMultiplier, 2.0, accuracy: 0.01)
    }
    
    /// BDD: Given audio is playing at 0.5x speed, when visualization is running, then visualization should update at 0.5x rate
    func testVisualizationSpeedMatchesSlowPlayback() async {
        // Given: Audio engine at 0.5x speed
        let mockEngine = MockNativeAudioEngine()
        let engine = AudioEngine(
            fileSystem: MockFileSystem(),
            nativeEngine: mockEngine
        )
        engine.playbackSpeed = .half
        
        // When: Creating visualization view model
        let viewModel = AudioVisualiserViewModel(audioEngine: engine)
        
        // Then: Playback speed multiplier should be 0.5
        XCTAssertEqual(viewModel.playbackSpeedMultiplier, 0.5, accuracy: 0.01)
    }
    
    // MARK: - Scenario: All Speed Options Available
    
    /// BDD: Given the playback speed control, when I view available speeds, then I should see all 6 options
    func testAllPlaybackSpeedOptionsAvailable() {
        // Given: PlaybackSpeed enum
        // When: Checking all cases
        let allSpeeds = PlaybackSpeed.allCases
        
        // Then: Should have all 6 speed options
        XCTAssertEqual(allSpeeds.count, 6)
        XCTAssertTrue(allSpeeds.contains(.half))
        XCTAssertTrue(allSpeeds.contains(.threeQuarter))
        XCTAssertTrue(allSpeeds.contains(.normal))
        XCTAssertTrue(allSpeeds.contains(.oneAndHalf))
        XCTAssertTrue(allSpeeds.contains(.double))
        XCTAssertTrue(allSpeeds.contains(.quadruple))
    }
    
    // MARK: - Scenario: Speed Changes During Playback
    
    /// BDD: Given audio is playing at 1x, when I change to 4x during playback, then speed should change immediately
    func testChangeSpeedDuringPlayback() async throws {
        // Given: Audio engine playing at 1x
        let mockEngine = MockNativeAudioEngine()
        let engine = AudioEngine(
            fileSystem: MockFileSystem(),
            nativeEngine: mockEngine
        )
        
        let track = Track(
            id: UUID(),
            title: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/test/path.mp3"
        )
        try await engine.loadTrack(track)
        engine.playbackSpeed = .normal
        try await engine.play()
        
        // When: Changing to 4x during playback
        engine.playbackSpeed = .quadruple
        
        // Then: Rate should be 4.0 (may be clamped to 2.0 by AVAudioPlayer)
        // Note: AVAudioPlayer supports up to 2.0x, so 4.0x will be clamped
        let rate = mockEngine.getRate()
        XCTAssertGreaterThanOrEqual(rate, 2.0, "Rate should be at least 2.0 (AVAudioPlayer max)")
        XCTAssertEqual(engine.playbackSpeed, .quadruple)
    }
}
#endif
