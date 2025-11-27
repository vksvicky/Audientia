// AudioEngineFormatDetectionTests.swift
// AudioCoreTests
//
// Ensures AudioEngine integrates with the format decoder coordinator using TDD/BDD.
//

@testable import AudioCore
@testable import Shared
import XCTest

@MainActor
final class AudioEngineFormatDetectionTests: XCTestCase {
    /// Given a track and a successful decoder, when loading, then detectedFormat should be stored
    func testLoadTrackStoresDetectedFormat() async throws {
        // Given
        let track = MockFactory.makeTrack(
            title: "Format Test",
            duration: 200,
            filePath: "/tmp/format-test.flac"
        )
        let expectedFormat = DecodedAudioFormat(
            codec: "MockFLAC",
            sampleRate: 96_000,
            channelCount: 2,
            bitRate: 1_000,
            duration: 205
        )
        let mockCoordinator = MockFormatDecodingCoordinator()
        mockCoordinator.result = expectedFormat
        let nativeEngine = MockNativeAudioEngine()
        nativeEngine.nextLoadDuration = expectedFormat.duration
        let engine = AudioEngineTestHelpers.createMockEngine(
            withTracks: [track],
            formatCoordinator: mockCoordinator,
            nativeEngine: nativeEngine
        )

        // When
        try await engine.loadTrack(track)

        // Then (Right-BICEP: Right result, Boundary by verifying duration override)
        XCTAssertEqual(engine.detectedFormat, expectedFormat)
        XCTAssertNil(engine.lastFormatDetectionError)
        XCTAssertEqual(engine.duration, expectedFormat.duration, accuracy: 0.01)
    }

    /// Given the decoder throws an error, when loading, then AudioEngine should fallback gracefully
    func testLoadTrackHandlesFormatDetectionFailure() async throws {
        // Given
        let track = MockFactory.makeTrack(
            title: "Format Failure",
            duration: 180,
            filePath: "/tmp/failure.mp3"
        )
        let mockCoordinator = MockFormatDecodingCoordinator()
        mockCoordinator.error = FormatDecoderError.decoderFailed(decoder: "Mock", reason: "Simulated failure")
        let engine = AudioEngineTestHelpers.createMockEngine(
            withTracks: [track],
            formatCoordinator: mockCoordinator,
            nativeEngine: MockNativeAudioEngine()
        )

        // When
        try await engine.loadTrack(track)

        // Then (Right-BICEP: Error handling, ensures fallback to track duration)
        XCTAssertNil(engine.detectedFormat)
        XCTAssertNotNil(engine.lastFormatDetectionError)
        XCTAssertEqual(engine.duration, track.duration, accuracy: 0.01)
    }

    /// Given a FLAC track, when loading through the default coordinator, then FFmpeg decoder should populate metadata
    func testLoadFlacTrackUsesFFmpegDecoder() async throws {
        // Given
        let flacURL = try TestFixtures.createTemporaryFLACSample(durationSeconds: 2.0)
        defer { TestFixtures.removeTemporaryFile(at: flacURL) }
        let track = MockFactory.makeTrack(
            title: "FLAC Sample",
            duration: 0,
            filePath: flacURL.path
        )
        let mockFileSystem = MockFileSystem()
        mockFileSystem.addFile(flacURL.path)
        let nativeEngine = MockNativeAudioEngine()
        nativeEngine.nextLoadDuration = 0.0
        let engine = AudioEngine(
            fileSystem: mockFileSystem,
            formatCoordinator: DefaultFormatDecodingCoordinator(),
            nativeEngine: nativeEngine
        )

        // When
        try await engine.loadTrack(track)

        // Then (Right-BICEP: Cross-check metadata from decoder)
        guard let detectedFormat = engine.detectedFormat else {
            return XCTFail("Expected detected format from FFmpeg decoder")
        }
        XCTAssertEqual(detectedFormat.codec, "FLAC")
        XCTAssertEqual(detectedFormat.sampleRate, 44_100)
        XCTAssertEqual(detectedFormat.channelCount, 2)
        XCTAssertGreaterThan(detectedFormat.duration, 1.9)
        XCTAssertEqual(engine.duration, detectedFormat.duration, accuracy: 0.0001)
    }

    /// Given detected metadata supplies duration, playback should run until that duration elapses
    func testPlaybackUsesDetectedDurationBeforeCompleting() async throws {
        // Given
        let track = MockFactory.makeTrack(
            title: "Detected Duration",
            duration: 0,
            filePath: "/tmp/detected-duration.flac"
        )
        let detectedFormat = DecodedAudioFormat(
            codec: "MockFLAC",
            sampleRate: 44_100,
            channelCount: 2,
            bitRate: 320_000,
            duration: 1.0
        )
        let mockCoordinator = MockFormatDecodingCoordinator()
        mockCoordinator.result = detectedFormat
        let nativeEngine = MockNativeAudioEngine()
        nativeEngine.nextLoadDuration = detectedFormat.duration
        let engine = AudioEngineTestHelpers.createMockEngine(
            withTracks: [track],
            formatCoordinator: mockCoordinator,
            nativeEngine: nativeEngine
        )

        // When
        try await engine.loadTrack(track)
        try await engine.play()

        // Then - before metadata duration elapsed we should still be playing
        nativeEngine.currentPosition = 0.2
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2s
        XCTAssertEqual(engine.state, .playing, "Engine should keep playing until detected duration finishes")

        // After detected duration we should transition to stopped
        nativeEngine.currentPosition = 1.2
        try await Task.sleep(nanoseconds: 200_000_000) // allow loop to observe completion
        XCTAssertEqual(engine.state, .stopped, "Engine should stop once detected duration elapses")
    }
}
