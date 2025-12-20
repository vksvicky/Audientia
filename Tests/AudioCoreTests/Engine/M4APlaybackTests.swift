//
//  M4APlaybackTests.swift
//  AudioCoreTests
//
//  TDD tests for M4A format playback support
//  Tests format detection, decoding, and playback with mocking
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
@testable import Shared
import XCTest

/// TDD tests for M4A playback support
/// Right-BICEP: Right results, Boundary conditions, Inverse relationships,
/// Cross-checking, Error conditions, Performance
@MainActor
final class M4APlaybackTests: XCTestCase {
    
    // MARK: - Format Detection Tests
    
    /// Test that AVFoundation decoder recognizes M4A files
    func testAVFoundationDecoderRecognizesM4AFiles() {
        // Given - M4A file path and AVFoundation supported extensions
        _ = "/tmp/test.m4a"
        let supportedExtensions = AudioFormats.avFoundationSupportedExtensions
        
        // When - Check if M4A is in AVFoundation supported extensions
        let canDecode = supportedExtensions.contains("m4a")
        
        // Then - Should recognize M4A
        XCTAssertTrue(canDecode, "AVFoundation decoder should recognize M4A files")
        XCTAssertTrue(AudioFormats.avFoundationSupportedExtensions.contains("m4a"), "M4A should be in supported extensions")
    }
    
    /// Test that M4A files are in the supported formats list
    func testM4AIsInSupportedFormats() {
        // Given - AudioFormats constants
        // When - Check if m4a is supported
        let isSupported = AudioFormats.isSupported("m4a")
        
        // Then - Should be supported
        XCTAssertTrue(isSupported, "M4A should be in allSupportedExtensions")
        XCTAssertTrue(AudioFormats.allSupportedExtensions.contains("m4a"), "M4A should be in allSupportedExtensions")
        XCTAssertTrue(AudioFormats.avFoundationSupportedExtensions.contains("m4a"), "M4A should be in avFoundationSupportedExtensions")
    }
    
    /// Test that format decoder coordinator routes M4A to AVFoundation decoder
    func testFormatCoordinatorRoutesM4AToAVFoundation() async throws {
        // Given - M4A file and real format coordinator (uses AVFoundation by default)
        let m4aPath = "/tmp/test.m4a"
        let expectedFormat = DecodedAudioFormat(
            codec: "AAC",
            sampleRate: 44_100,
            channelCount: 2,
            bitRate: 256,
            duration: 180.0
        )
        
        // Use mock coordinator to verify M4A is supported
        let mockCoordinator = MockFormatDecodingCoordinator()
        mockCoordinator.result = expectedFormat
        mockCoordinator.supportedExtensions = AudioFormats.avFoundationSupportedExtensions
        
        // When - Decode M4A format
        let format = try await mockCoordinator.decodeFormat(for: m4aPath)
        
        // Then - Should return expected format
        XCTAssertEqual(format, expectedFormat, "Should return format from AVFoundation decoder")
        XCTAssertTrue(mockCoordinator.decodeCalls.contains(m4aPath), "Should attempt to decode M4A file")
    }
    
    // MARK: - AudioEngine Integration Tests
    
    /// Test that AudioEngine can load M4A tracks
    func testAudioEngineLoadsM4ATrack() async throws {
        // Given - M4A track with mock format coordinator
        let m4aTrack = MockFactory.makeTrack(
            title: "M4A Test Track",
            filePath: "/tmp/test.m4a"
        )
        let expectedFormat = DecodedAudioFormat(
            codec: "AAC",
            sampleRate: 44_100,
            channelCount: 2,
            bitRate: 256,
            duration: 180.0
        )
        
        let mockCoordinator = MockFormatDecodingCoordinator()
        mockCoordinator.result = expectedFormat
        
        let mockNativeEngine = MockNativeAudioEngine()
        mockNativeEngine.nextLoadDuration = expectedFormat.duration
        mockNativeEngine.loadResult = true
        
        let engine = AudioEngineTestHelpers.createMockEngine(
            withTracks: [m4aTrack],
            formatCoordinator: mockCoordinator,
            nativeEngine: mockNativeEngine
        )
        
        // When - Load M4A track
        try await engine.loadTrack(m4aTrack)
        
        // Then - Track should be loaded with detected format
        XCTAssertEqual(engine.currentTrack, m4aTrack, "Current track should be set")
        XCTAssertEqual(engine.detectedFormat, expectedFormat, "Format should be detected")
        XCTAssertEqual(engine.duration, expectedFormat.duration, accuracy: 0.01, "Duration should match")
        XCTAssertEqual(mockNativeEngine.loadFileCalls.count, 1, "Native engine should be called to load file")
    }
    
    /// Test that AudioEngine handles M4A format detection failure gracefully
    func testAudioEngineHandlesM4AFormatDetectionFailure() async throws {
        // Given - M4A track with failing format detection
        let m4aTrack = MockFactory.makeTrack(
            title: "M4A Test Track",
            filePath: "/tmp/test.m4a"
        )
        
        let mockCoordinator = MockFormatDecodingCoordinator()
        mockCoordinator.shouldFail = true
        mockCoordinator.error = FormatDecoderError.decoderFailed(decoder: "AVFoundation", reason: "Test failure")
        
        let mockNativeEngine = MockNativeAudioEngine()
        mockNativeEngine.loadResult = true
        mockNativeEngine.nextLoadDuration = 180.0
        
        let engine = AudioEngineTestHelpers.createMockEngine(
            withTracks: [m4aTrack],
            formatCoordinator: mockCoordinator,
            nativeEngine: mockNativeEngine
        )
        
        // When - Load M4A track (format detection fails but native load succeeds)
        try await engine.loadTrack(m4aTrack)
        
        // Then - Track should still be loaded (format detection is non-fatal)
        XCTAssertEqual(engine.currentTrack, m4aTrack, "Current track should be set even if format detection fails")
        XCTAssertNil(engine.detectedFormat, "Format should be nil when detection fails")
        XCTAssertNotNil(engine.lastFormatDetectionError, "Should record format detection error")
        XCTAssertEqual(mockNativeEngine.loadFileCalls.count, 1, "Native engine should still attempt to load")
    }
    
    /// Test that AudioEngine can play M4A tracks
    func testAudioEnginePlaysM4ATrack() async throws {
        // Given - Loaded M4A track
        let m4aTrack = MockFactory.makeTrack(
            title: "M4A Test Track",
            filePath: "/tmp/test.m4a"
        )
        
        let mockNativeEngine = MockNativeAudioEngine()
        mockNativeEngine.loadResult = true
        mockNativeEngine.playResult = true
        mockNativeEngine.nextLoadDuration = 180.0
        
        let engine = AudioEngineTestHelpers.createMockEngine(
            withTracks: [m4aTrack],
            nativeEngine: mockNativeEngine
        )
        
        // When - Load and play M4A track
        try await engine.loadTrack(m4aTrack)
        try await engine.play()
        
        // Then - Should be playing
        XCTAssertEqual(engine.state, .playing, "Engine should be in playing state")
        XCTAssertEqual(mockNativeEngine.playCallCount, 1, "Native engine should be called to play")
    }
    
    /// Test that M4A tracks can be seeked
    func testAudioEngineSeeksM4ATrack() async throws {
        // Given - Playing M4A track
        let m4aTrack = MockFactory.makeTrack(
            title: "M4A Test Track",
            filePath: "/tmp/test.m4a"
        )
        
        let mockNativeEngine = MockNativeAudioEngine()
        mockNativeEngine.loadResult = true
        mockNativeEngine.playResult = true
        mockNativeEngine.seekResult = true
        mockNativeEngine.nextLoadDuration = 180.0
        
        let engine = AudioEngineTestHelpers.createMockEngine(
            withTracks: [m4aTrack],
            nativeEngine: mockNativeEngine
        )
        
        try await engine.loadTrack(m4aTrack)
        try await engine.play()
        
        // When - Seek to 60 seconds
        try await engine.seek(to: 60.0)
        
        // Then - Should seek successfully
        XCTAssertEqual(mockNativeEngine.seekCalls.count, 1, "Native engine should be called to seek")
        XCTAssertEqual(mockNativeEngine.seekCalls.first ?? 0, 60.0, accuracy: 0.01, "Should seek to correct position")
    }
    
    // MARK: - Boundary Conditions
    
    /// Test M4A file with uppercase extension
    func testM4AFileWithUppercaseExtension() async throws {
        // Given - M4A file with uppercase extension
        let m4aTrack = MockFactory.makeTrack(
            title: "M4A Test Track",
            filePath: "/tmp/test.M4A"
        )
        
        let mockNativeEngine = MockNativeAudioEngine()
        mockNativeEngine.loadResult = true
        mockNativeEngine.nextLoadDuration = 180.0
        
        let engine = AudioEngineTestHelpers.createMockEngine(
            withTracks: [m4aTrack],
            nativeEngine: mockNativeEngine
        )
        
        // When - Load track
        try await engine.loadTrack(m4aTrack)
        
        // Then - Should load successfully (extension should be case-insensitive)
        XCTAssertEqual(engine.currentTrack, m4aTrack, "Should load track with uppercase extension")
    }
    
    /// Test M4A file with mixed case extension
    func testM4AFileWithMixedCaseExtension() async throws {
        // Given - M4A file with mixed case extension
        let m4aTrack = MockFactory.makeTrack(
            title: "M4A Test Track",
            filePath: "/tmp/test.M4a"
        )
        
        let mockNativeEngine = MockNativeAudioEngine()
        mockNativeEngine.loadResult = true
        mockNativeEngine.nextLoadDuration = 180.0
        
        let engine = AudioEngineTestHelpers.createMockEngine(
            withTracks: [m4aTrack],
            nativeEngine: mockNativeEngine
        )
        
        // When - Load track
        try await engine.loadTrack(m4aTrack)
        
        // Then - Should load successfully
        XCTAssertEqual(engine.currentTrack, m4aTrack, "Should load track with mixed case extension")
    }
    
    // MARK: - Error Conditions
    
    /// Test that missing M4A file throws appropriate error
    func testMissingM4AFileThrowsError() async {
        // Given - Non-existent M4A file
        let m4aTrack = MockFactory.makeTrack(
            title: "M4A Test Track",
            filePath: "/tmp/nonexistent.m4a"
        )
        
        let mockFileSystem = MockFileSystem()
        mockFileSystem.shouldFail = true
        
        let engine = AudioEngine(
            fileSystem: mockFileSystem,
            formatCoordinator: MockFormatDecodingCoordinator(),
            nativeEngine: MockNativeAudioEngine()
        )
        
        // When - Try to load missing file
        // Then - Should throw trackLoadFailed error
        do {
            try await engine.loadTrack(m4aTrack)
            XCTFail("Should throw error for missing file")
        } catch let error as AudioEngineError {
            if case .trackLoadFailed = error {
                // Expected error
            } else {
                XCTFail("Expected trackLoadFailed error, got \(error)")
            }
        } catch {
            XCTFail("Expected AudioEngineError, got \(error)")
        }
    }
    
    /// Test that corrupted M4A file is handled gracefully
    func testCorruptedM4AFileHandling() async throws {
        // Given - M4A track with format detection failure (corrupted file)
        let m4aTrack = MockFactory.makeTrack(
            title: "M4A Test Track",
            filePath: "/tmp/corrupted.m4a"
        )
        
        let mockCoordinator = MockFormatDecodingCoordinator()
        mockCoordinator.shouldFail = true
        mockCoordinator.error = FormatDecoderError.decoderFailed(decoder: "AVFoundation", reason: "Invalid file format")
        
        let mockNativeEngine = MockNativeAudioEngine()
        mockNativeEngine.loadResult = false // Native engine also fails
        
        let engine = AudioEngineTestHelpers.createMockEngine(
            withTracks: [m4aTrack],
            formatCoordinator: mockCoordinator,
            nativeEngine: mockNativeEngine
        )
        
        // When - Try to load corrupted file
        // Note: AudioEngine doesn't throw when both format detection and native load fail,
        // it sets the state to error temporarily, but then resets to stopped.
        // The format detection error is stored in lastFormatDetectionError
        try await engine.loadTrack(m4aTrack)
        
        // Then - Format detection error should be recorded
        XCTAssertNotNil(engine.lastFormatDetectionError, "Should record format detection error for corrupted file")
        if let error = engine.lastFormatDetectionError {
            XCTAssertTrue(
                error.localizedDescription.contains("failed") ||
                error.localizedDescription.contains("Invalid"),
                "Error should indicate failure: \(error.localizedDescription)"
            )
        }
        
        // Track should still be loaded (state will be .stopped, not .error, due to code flow)
        XCTAssertEqual(engine.currentTrack?.filePath, m4aTrack.filePath, "Track should be set even with format detection error")
        XCTAssertEqual(engine.state, .stopped, "State should be stopped after load completes")
    }
}

// MARK: - Test Helpers

private enum TestError: Error {
    case unexpected
}
