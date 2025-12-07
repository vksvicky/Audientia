//
//  PlaybackSpeedTests.swift
//  AudioCoreTests
//
//  TDD tests for playback speed functionality
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

#if canImport(XCTest)
@testable import AudioCore
@testable import Shared
import XCTest

@MainActor
final class PlaybackSpeedTests: XCTestCase {
    
    // MARK: - PlaybackSpeed Enum Tests
    
    func testPlaybackSpeedAllCases() {
        // Given: All playback speed cases
        // When: Checking all cases
        // Then: All expected speeds should be present
        let allCases = PlaybackSpeed.allCases
        XCTAssertEqual(allCases.count, 6, "Should have 6 speed options")
        XCTAssertTrue(allCases.contains(.half))
        XCTAssertTrue(allCases.contains(.threeQuarter))
        XCTAssertTrue(allCases.contains(.normal))
        XCTAssertTrue(allCases.contains(.oneAndHalf))
        XCTAssertTrue(allCases.contains(.double))
        XCTAssertTrue(allCases.contains(.quadruple))
    }
    
    func testPlaybackSpeedRawValues() {
        // Given: Playback speed enum cases
        // When: Checking raw values
        // Then: Raw values should match expected rates
        XCTAssertEqual(PlaybackSpeed.half.rawValue, 0.5)
        XCTAssertEqual(PlaybackSpeed.threeQuarter.rawValue, 0.75)
        XCTAssertEqual(PlaybackSpeed.normal.rawValue, 1.0)
        XCTAssertEqual(PlaybackSpeed.oneAndHalf.rawValue, 1.5)
        XCTAssertEqual(PlaybackSpeed.double.rawValue, 2.0)
        XCTAssertEqual(PlaybackSpeed.quadruple.rawValue, 4.0)
    }
    
    func testPlaybackSpeedDisplayNames() {
        // Given: Playback speed enum cases
        // When: Checking display names
        // Then: Display names should be formatted correctly
        XCTAssertEqual(PlaybackSpeed.half.displayName, "0.5x")
        XCTAssertEqual(PlaybackSpeed.threeQuarter.displayName, "0.75x")
        XCTAssertEqual(PlaybackSpeed.normal.displayName, "1x")
        XCTAssertEqual(PlaybackSpeed.oneAndHalf.displayName, "1.5x")
        XCTAssertEqual(PlaybackSpeed.double.displayName, "2x")
        XCTAssertEqual(PlaybackSpeed.quadruple.displayName, "4x")
    }
    
    func testPlaybackSpeedDefault() {
        // Given: Default playback speed
        // When: Checking default value
        // Then: Should be normal (1x)
        XCTAssertEqual(PlaybackSpeed.default, .normal)
    }
    
    func testPlaybackSpeedCodable() throws {
        // Given: A playback speed value
        // When: Encoding and decoding
        // Then: Should preserve the value
        let speed = PlaybackSpeed.oneAndHalf
        let encoder = JSONEncoder()
        let data = try encoder.encode(speed)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PlaybackSpeed.self, from: data)
        
        XCTAssertEqual(decoded, speed)
    }
    
    // MARK: - AudioEngine Playback Speed Tests
    
    func testAudioEngineInitialPlaybackSpeed() {
        // Given: A new AudioEngine
        // When: Checking initial playback speed
        // Then: Should match AppSettings default
        let engine = AudioEngine()
        XCTAssertEqual(engine.playbackSpeed, AppSettings.shared.playbackSpeed)
    }
    
    func testAudioEngineSetPlaybackSpeed() {
        // Given: An AudioEngine
        // When: Setting playback speed
        // Then: Speed should be updated
        let engine = AudioEngine()
        let newSpeed = PlaybackSpeed.double
        
        engine.playbackSpeed = newSpeed
        
        XCTAssertEqual(engine.playbackSpeed, newSpeed)
    }
    
    func testAudioEnginePlaybackSpeedAffectsNativeEngine() {
        // Given: An AudioEngine with a mock native engine
        // When: Setting playback speed
        // Then: Native engine rate should be updated
        let mockEngine = MockNativeAudioEngine()
        let engine = AudioEngine(
            fileSystem: MockFileSystem(),
            nativeEngine: mockEngine
        )
        
        engine.playbackSpeed = PlaybackSpeed.oneAndHalf
        
        XCTAssertEqual(mockEngine.lastSetRate, 1.5, accuracy: 0.01)
    }
    
    func testAudioEnginePlaybackSpeedPersistence() {
        // Given: An AudioEngine with saved speed
        // When: Creating a new engine
        // Then: Should load saved speed from AppSettings
        let originalSpeed = PlaybackSpeed.double
        AppSettings.shared.playbackSpeed = originalSpeed
        
        let engine = AudioEngine()
        
        // Engine should load from AppSettings
        XCTAssertEqual(engine.playbackSpeed, originalSpeed)
    }
}
#endif
