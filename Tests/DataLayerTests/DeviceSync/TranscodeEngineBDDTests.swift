//
//  TranscodeEngineBDDTests.swift
//  DataLayerTests
//
//  BDD scenarios for TranscodeEngine
//

@testable import DataLayer
@testable import Shared
import XCTest

final class TranscodeEngineBDDTests: XCTestCase {
    
    private var engine: MockTranscodeEngine!
    
    override func setUp() async throws {
        try await super.setUp()
        engine = MockTranscodeEngine()
    }
    
    override func tearDown() async throws {
        engine = nil
        try await super.tearDown()
    }
    
    // MARK: - BDD Scenarios
    
    func testAsUserIWantToSyncFLACFilesAsMP3_320kbps() async throws {
        // Scenario: As a user, I want to sync FLAC files as MP3 320kbps
        
        // Given: I have a FLAC file
        let flacTrack = DeviceSyncFixtures.track(
            filePath: "/Music/album/track.flac",
            bitrate: 1000 // FLAC is lossless, high bitrate
        )
        let mp3Profile = TranscodeProfile(
            name: "MP3 320kbps",
            format: .mp3,
            bitrate: 320
        )
        engine.shouldSucceed = true
        engine.mockOutputPath = "/tmp/track.mp3"
        engine.mockNeedsTranscoding = true
        
        // When: I transcode it to MP3 320kbps
        let needsTranscoding = await engine.needsTranscoding(track: flacTrack, profile: mp3Profile)
        XCTAssertTrue(needsTranscoding, "FLAC should need transcoding to MP3")
        
        let outputPath = try await engine.transcode(
            inputPath: flacTrack.filePath,
            outputPath: "/tmp/track.mp3",
            profile: mp3Profile,
            progress: { progress in
                XCTAssertGreaterThanOrEqual(progress, 0.0)
                XCTAssertLessThanOrEqual(progress, 1.0)
            }
        )
        
        // Then: I get an MP3 file at 320kbps
        XCTAssertEqual(outputPath, "/tmp/track.mp3")
        XCTAssertTrue(await engine.transcodeCalled)
        XCTAssertEqual(await engine.lastProfile?.format, .mp3)
        XCTAssertEqual(await engine.lastProfile?.bitrate, 320)
    }
    
    func testAsUserIWantToTranscodeHighQualityAACForSmallerFileSize() async throws {
        // Scenario: As a user, I want to transcode high-quality AAC for smaller file size
        
        // Given: I have a high-bitrate MP3 file
        let highQualityTrack = DeviceSyncFixtures.track(
            filePath: "/Music/track.mp3",
            bitrate: 320,
            fileSize: 10 * 1024 * 1024 // 10MB
        )
        let aacProfile = TranscodeProfile(
            name: "AAC 256kbps",
            format: .aac,
            bitrate: 256
        )
        engine.shouldSucceed = true
        engine.mockOutputPath = "/tmp/track.m4a"
        engine.mockEstimatedSize = 8 * 1024 * 1024 // Estimated 8MB
        
        // When: I transcode it to AAC 256kbps
        let estimatedSize = await engine.estimateOutputSize(track: highQualityTrack, profile: aacProfile)
        
        // Then: The estimated file size is smaller
        XCTAssertLessThan(estimatedSize, highQualityTrack.fileSize, "AAC should be smaller than MP3")
        
        let outputPath = try await engine.transcode(
            inputPath: highQualityTrack.filePath,
            outputPath: "/tmp/track.m4a",
            profile: aacProfile,
            progress: { _ in }
        )
        
        XCTAssertEqual(outputPath, "/tmp/track.m4a")
        XCTAssertEqual(await engine.lastProfile?.format, .aac)
    }
    
    func testAsUserIWantToSeeTranscodingProgress() async throws {
        // Scenario: As a user, I want to see transcoding progress
        
        // Given: I'm transcoding a long audio file
        let longTrack = DeviceSyncFixtures.track(duration: 600.0) // 10 minutes
        let profile = TranscodeProfile(name: "MP3", format: .mp3, bitrate: 192)
        engine.shouldSucceed = true
        engine.mockOutputPath = "/tmp/long.mp3"
        
        var progressValues: [Double] = []
        
        // When: I transcode the file
        _ = try await engine.transcode(
            inputPath: longTrack.filePath,
            outputPath: "/tmp/long.mp3",
            profile: profile,
            progress: { progress in
                progressValues.append(progress)
            }
        )
        
        // Then: I see progress updates from 0.0 to 1.0
        XCTAssertGreaterThan(progressValues.count, 0, "Should receive progress updates")
        XCTAssertEqual(progressValues.first, 0.0, accuracy: 0.01)
        XCTAssertEqual(progressValues.last, 1.0, accuracy: 0.01)
        
        // Progress should be monotonically increasing
        for i in 1..<progressValues.count {
            XCTAssertGreaterThanOrEqual(progressValues[i], progressValues[i - 1])
        }
    }
    
    func testAsUserIWantToSkipTranscodingWhenFormatAlreadyMatches() async {
        // Scenario: As a user, I want to skip transcoding when format already matches
        
        // Given: I have an MP3 file and want MP3 output
        let mp3Track = DeviceSyncFixtures.track(
            filePath: "/Music/track.mp3",
            bitrate: 192
        )
        let mp3Profile = TranscodeProfile(
            name: "MP3 192kbps",
            format: .mp3,
            bitrate: 192
        )
        engine.mockNeedsTranscoding = false
        
        // When: I check if transcoding is needed
        let needsTranscoding = await engine.needsTranscoding(track: mp3Track, profile: mp3Profile)
        
        // Then: Transcoding is not needed
        XCTAssertFalse(needsTranscoding, "MP3 to MP3 with same bitrate should not need transcoding")
    }
    
    func testAsUserIWantToHandleTranscodingErrorsGracefully() async {
        // Scenario: As a user, I want to handle transcoding errors gracefully
        
        // Given: I try to transcode a corrupted file
        let profile = TranscodeProfile(name: "MP3", format: .mp3, bitrate: 192)
        engine.shouldSucceed = false
        engine.mockError = .invalidInputFile
        
        // When: I attempt to transcode
        // Then: I get a clear error message
        do {
            _ = try await engine.transcode(
                inputPath: "/nonexistent/corrupted.flac",
                outputPath: "/tmp/output.mp3",
                profile: profile,
                progress: { _ in }
            )
            XCTFail("Should have thrown error")
        } catch let error as TranscodeError {
            XCTAssertEqual(error, .invalidInputFile)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testAsUserIWantToEstimateFileSizeBeforeTranscoding() async {
        // Scenario: As a user, I want to estimate file size before transcoding
        
        // Given: I have a 5-minute FLAC file
        let flacTrack = DeviceSyncFixtures.track(
            duration: 300.0, // 5 minutes
            filePath: "/Music/track.flac",
            fileSize: 50 * 1024 * 1024 // 50MB FLAC
        )
        let mp3Profile = TranscodeProfile(
            name: "MP3 192kbps",
            format: .mp3,
            bitrate: 192
        )
        // 192 kbps * 300 seconds = 57,600 kilobits = 7,200,000 bytes ≈ 7MB
        let expectedSize: Int64 = 7_200_000
        engine.mockEstimatedSize = expectedSize
        
        // When: I estimate the output size
        let estimatedSize = await engine.estimateOutputSize(track: flacTrack, profile: mp3Profile)
        
        // Then: I get a reasonable estimate
        XCTAssertGreaterThan(estimatedSize, 0)
        XCTAssertLessThan(estimatedSize, flacTrack.fileSize, "MP3 should be smaller than FLAC")
        XCTAssertEqual(estimatedSize, expectedSize)
    }
}
