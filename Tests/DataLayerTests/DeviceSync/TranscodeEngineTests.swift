//
//  TranscodeEngineTests.swift
//  DataLayerTests
//
//  TDD tests for TranscodeEngine (Right-BICEP)
//

@testable import DataLayer
@testable import Shared
import XCTest

final class TranscodeEngineTests: XCTestCase {
    
    private var engine: MockTranscodeEngine!
    
    override func setUp() async throws {
        try await super.setUp()
        engine = MockTranscodeEngine()
    }
    
    override func tearDown() async throws {
        engine = nil
        try await super.tearDown()
    }
    
    // MARK: - Right: Correctness Tests
    
    func testTranscodeWithValidInputProducesOutput() async throws {
        // Given
        let track = DeviceSyncFixtures.track()
        let profile = TranscodeProfile(
            name: "MP3 192kbps",
            format: .mp3,
            bitrate: 192
        )
        let outputPath = "/tmp/test_output.mp3"
        await engine.setShouldSucceed(true)
        await engine.setMockOutputPath(outputPath)
        
        // When
        let result = try await engine.transcode(
            inputPath: track.filePath,
            outputPath: outputPath,
            profile: profile,
            progress: { _ in }
        )
        
        // Then
        XCTAssertEqual(result, outputPath)
        let transcodeCalled = await engine.transcodeCalled
        XCTAssertTrue(transcodeCalled)
        let lastInputPath = await engine.lastInputPath
        XCTAssertEqual(lastInputPath, track.filePath)
        let lastProfile = await engine.lastProfile
        XCTAssertEqual(lastProfile?.format, .mp3)
    }
    
    func testNeedsTranscodingReturnsTrueWhenFormatDiffers() async {
        // Given
        let track = DeviceSyncFixtures.track(filePath: "/test.flac")
        let profile = TranscodeProfile(
            name: "MP3 192kbps",
            format: .mp3,
            bitrate: 192
        )
        await engine.setMockNeedsTranscoding(true)
        
        // When
        let needsTranscoding = await engine.needsTranscoding(track: track, profile: profile)
        
        // Then
        XCTAssertTrue(needsTranscoding)
    }
    
    func testNeedsTranscodingReturnsFalseWhenFormatMatches() async {
        // Given
        let track = DeviceSyncFixtures.track(filePath: "/test.mp3")
        let profile = TranscodeProfile(
            name: "MP3 192kbps",
            format: .mp3,
            bitrate: 192
        )
        await engine.setMockNeedsTranscoding(false)
        
        // When
        let needsTranscoding = await engine.needsTranscoding(track: track, profile: profile)
        
        // Then
        XCTAssertFalse(needsTranscoding)
    }
    
    func testEstimateOutputSizeCalculatesBasedOnBitrate() async {
        // Given
        let track = DeviceSyncFixtures.track(duration: 180.0) // 3 minutes
        let profile = TranscodeProfile(
            name: "MP3 192kbps",
            format: .mp3,
            bitrate: 192
        )
        // 192 kbps * 180 seconds = 34,560 kilobits = 4,320,000 bytes
        let expectedSize: Int64 = 4_320_000
        await engine.setMockEstimatedSize(expectedSize)
        
        // When
        let estimatedSize = await engine.estimateOutputSize(track: track, profile: profile)
        
        // Then
        XCTAssertEqual(estimatedSize, expectedSize)
    }
    
    // MARK: - B: Boundary Tests
    
    func testTranscodeWithVeryShortFile() async throws {
        // Given
        let track = DeviceSyncFixtures.track(duration: 1.0) // 1 second
        let profile = TranscodeProfile(name: "MP3", format: .mp3, bitrate: 192)
        await engine.setShouldSucceed(true)
        await engine.setMockOutputPath("/tmp/short.mp3")
        
        // When/Then: Should not crash
        _ = try await engine.transcode(
            inputPath: track.filePath,
            outputPath: "/tmp/short.mp3",
            profile: profile,
            progress: { _ in }
        )
    }
    
    func testTranscodeWithVeryLongFile() async throws {
        // Given
        let track = DeviceSyncFixtures.track(duration: 10800.0) // 3 hours
        let profile = TranscodeProfile(name: "MP3", format: .mp3, bitrate: 192)
        await engine.setShouldSucceed(true)
        await engine.setMockOutputPath("/tmp/long.mp3")
        
        // When/Then: Should handle long files
        _ = try await engine.transcode(
            inputPath: track.filePath,
            outputPath: "/tmp/long.mp3",
            profile: profile,
            progress: { _ in }
        )
    }
    
    // MARK: - I: Inverse Tests
    
    func testTranscodeThenVerifyOutputExists() async throws {
        // Given
        let track = DeviceSyncFixtures.track()
        let profile = TranscodeProfile(name: "MP3", format: .mp3, bitrate: 192)
        let outputPath = "/tmp/test.mp3"
        await engine.setShouldSucceed(true)
        await engine.setMockOutputPath(outputPath)
        
        // When
        let result = try await engine.transcode(
            inputPath: track.filePath,
            outputPath: outputPath,
            profile: profile
        ) { _ in }
        
        // Then
        XCTAssertEqual(result, outputPath)
        let transcodeCalled = await engine.transcodeCalled
        XCTAssertTrue(transcodeCalled)
    }
    
    // MARK: - C: Cross-check Tests
    
    func testEstimateSizeMatchesActualTranscode() async throws {
        // Given
        let track = DeviceSyncFixtures.track(duration: 180.0)
        let profile = TranscodeProfile(name: "MP3", format: .mp3, bitrate: 192)
        let estimatedSize: Int64 = 4_320_000
        await engine.setMockEstimatedSize(estimatedSize)
        await engine.setShouldSucceed(true)
        await engine.setMockOutputPath("/tmp/test.mp3")
        
        // When
        let estimated = await engine.estimateOutputSize(track: track, profile: profile)
        _ = try await engine.transcode(
            inputPath: track.filePath,
            outputPath: "/tmp/test.mp3",
            profile: profile,
            progress: { _ in }
        )
        
        // Then: Estimate should be reasonable (within 20% of actual)
        XCTAssertGreaterThan(estimated, 0)
        XCTAssertLessThan(estimated, estimatedSize * 2) // Should be within reasonable range
    }
    
    // MARK: - E: Error Tests
    
    func testTranscodeThrowsErrorForInvalidInputFile() async {
        // Given
        let profile = TranscodeProfile(name: "MP3", format: .mp3, bitrate: 192)
        await engine.setMockError(.invalidInputFile)
        
        // When/Then
        do {
            _ = try await engine.transcode(
                inputPath: "/nonexistent/file.flac",
                outputPath: "/tmp/output.mp3",
                profile: profile,
                progress: { _ in }
            )
            XCTFail("Should have thrown error")
        } catch let error as TranscodeError {
            XCTAssertEqual(error, .invalidInputFile)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testTranscodeThrowsErrorForUnsupportedFormat() async {
        // Given
        let profile = TranscodeProfile(name: "MP3", format: .mp3, bitrate: 192)
        await engine.setMockError(.unsupportedFormat)
        
        // When/Then
        do {
            _ = try await engine.transcode(
                inputPath: "/test.unknown",
                outputPath: "/tmp/output.mp3",
                profile: profile,
                progress: { _ in }
            )
            XCTFail("Should have thrown error")
        } catch let error as TranscodeError {
            XCTAssertEqual(error, .unsupportedFormat)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testTranscodeThrowsErrorForInsufficientSpace() async {
        // Given
        let profile = TranscodeProfile(name: "MP3", format: .mp3, bitrate: 192)
        await engine.setMockError(.insufficientSpace)
        
        // When/Then
        do {
            _ = try await engine.transcode(
                inputPath: "/test.flac",
                outputPath: "/tmp/output.mp3",
                profile: profile,
                progress: { _ in }
            )
            XCTFail("Should have thrown error")
        } catch let error as TranscodeError {
            XCTAssertEqual(error, .insufficientSpace)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - P: Performance Tests
    
    func testTranscodePerformance() async throws {
        // Given
        let track = DeviceSyncFixtures.track(duration: 180.0)
        let profile = TranscodeProfile(name: "MP3", format: .mp3, bitrate: 192)
        await engine.setShouldSucceed(true)
        await engine.setMockOutputPath("/tmp/test.mp3")
        
        // When/Then: Measure transcoding time
        let iterations = 10
        var times: [TimeInterval] = []
        
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            _ = try await engine.transcode(
                inputPath: track.filePath,
                outputPath: "/tmp/test.mp3",
                profile: profile,
                progress: { _ in }
            )
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            times.append(elapsed)
        }
        
        let average = times.reduce(0, +) / Double(times.count)
        print("Average transcode time: \(String(format: "%.4f", average * 1000))ms")
        
        // Real-time factor should be < 0.5x (transcode 3 min file in < 1.5 min)
        XCTAssertLessThan(average, 90.0, "Transcoding should complete in reasonable time")
    }
    
    // MARK: - Edge Cases
    
    func testTranscodeWithUnusualFormat() async throws {
        // Given
        let track = DeviceSyncFixtures.track(filePath: "/test.ape")
        let profile = TranscodeProfile(name: "MP3", format: .mp3, bitrate: 192)
        await engine.setShouldSucceed(true)
        await engine.setMockOutputPath("/tmp/test.mp3")
        
        // When/Then: Should handle unusual formats
        _ = try await engine.transcode(
            inputPath: track.filePath,
            outputPath: "/tmp/test.mp3",
            profile: profile,
            progress: { _ in }
        )
    }
    
    func testTranscodeWithVariableBitrateSource() async throws {
        // Given
        let track = DeviceSyncFixtures.track(bitrate: 0) // VBR
        let profile = TranscodeProfile(name: "MP3", format: .mp3, bitrate: 192)
        await engine.setShouldSucceed(true)
        await engine.setMockOutputPath("/tmp/test.mp3")
        
        // When/Then: Should handle VBR sources
        _ = try await engine.transcode(
            inputPath: track.filePath,
            outputPath: "/tmp/test.mp3",
            profile: profile,
            progress: { _ in }
        )
    }
}
