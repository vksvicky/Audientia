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
        let engine = AudioEngineTestHelpers.createMockEngine(
            withTracks: [track],
            formatCoordinator: mockCoordinator
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
            formatCoordinator: mockCoordinator
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
        let engine = AudioEngine(
            fileSystem: mockFileSystem,
            formatCoordinator: DefaultFormatDecodingCoordinator()
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
}
