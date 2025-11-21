//
//  FFmpegTranscodeEngineIntegrationTests.swift
//  DataLayerTests
//
//  Integration tests for FFmpegTranscodeEngine with FFmpeg wrapper
//

@testable import DataLayer
@testable import Shared
import XCTest

final class FFmpegTranscodeEngineIntegrationTests: XCTestCase {
    
    private var ffmpegWrapper: MockFFmpegWrapper!
    private var engine: FFmpegTranscodeEngine!
    private var tempDirectory: URL!
    private var testInputFile: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        ffmpegWrapper = MockFFmpegWrapper()
        engine = FFmpegTranscodeEngine(ffmpegWrapper: ffmpegWrapper)
        
        // Create temporary directory and test input file
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        testInputFile = tempDirectory.appendingPathComponent("test.flac")
        // Create a dummy file for testing
        try "dummy audio data".write(to: testInputFile, atomically: true, encoding: .utf8)
    }
    
    override func tearDown() async throws {
        // Clean up temporary files
        if let tempDir = tempDirectory {
            try? FileManager.default.removeItem(at: tempDir)
        }
        engine = nil
        ffmpegWrapper = nil
        try await super.tearDown()
    }
    
    // MARK: - Right: Correctness Tests
    
    func testTranscodeCallsFFmpegWrapperWithCorrectParameters() async throws {
        // Given
        let inputPath = testInputFile.path
        let profile = TranscodeProfile(
            name: "MP3 192kbps",
            format: .mp3,
            bitrate: 192,
            sampleRate: 44100
        )
        let outputPath = tempDirectory.appendingPathComponent("output.mp3").path
        await ffmpegWrapper.setShouldSucceed(true)
        
        // When
        _ = try await engine.transcode(
            inputPath: inputPath,
            outputPath: outputPath,
            profile: profile,
            progress: { _ in }
        )
        
        // Then
        let transcodeCalled = await ffmpegWrapper.transcodeCalled
        let lastInputPath = await ffmpegWrapper.lastInputPath
        let lastOutputPath = await ffmpegWrapper.lastOutputPath
        let lastFormat = await ffmpegWrapper.lastFormat
        let lastBitrate = await ffmpegWrapper.lastBitrate
        
        XCTAssertTrue(transcodeCalled)
        XCTAssertEqual(lastInputPath, inputPath)
        XCTAssertEqual(lastOutputPath, outputPath)
        XCTAssertEqual(lastFormat, .mp3)
        XCTAssertEqual(lastBitrate, 192)
    }
    
    func testTranscodeReportsProgress() async throws {
        // Given
        let inputPath = testInputFile.path
        let profile = TranscodeProfile(name: "MP3", format: .mp3, bitrate: 192)
        let outputPath = tempDirectory.appendingPathComponent("output.mp3").path
        await ffmpegWrapper.setShouldSucceed(true)
        
        var progressValues: [Double] = []
        
        // When
        _ = try await engine.transcode(
            inputPath: inputPath,
            outputPath: outputPath,
            profile: profile,
            progress: { progress in
                progressValues.append(progress)
            }
        )
        
        // Then
        XCTAssertGreaterThan(progressValues.count, 0)
        if let first = progressValues.first {
            XCTAssertEqual(first, 0.0, accuracy: 0.01)
        }
        if let last = progressValues.last {
            XCTAssertEqual(last, 1.0, accuracy: 0.01)
        }
    }
    
    // MARK: - E: Error Tests
    
    func testTranscodePropagatesFFmpegErrors() async {
        // Given
        let inputPath = testInputFile.path
        let profile = TranscodeProfile(name: "MP3", format: .mp3, bitrate: 192)
        let outputPath = tempDirectory.appendingPathComponent("output.mp3").path
        await ffmpegWrapper.setShouldSucceed(false)
        await ffmpegWrapper.setMockError(.transcodingFailed("FFmpeg error"))
        
        // When/Then
        do {
            _ = try await engine.transcode(
                inputPath: inputPath,
                outputPath: outputPath,
                profile: profile,
                progress: { _ in }
            )
            XCTFail("Should have thrown error")
        } catch let error as TranscodeError {
            if case .transcodingFailed(let message) = error {
                XCTAssertTrue(message.contains("FFmpeg error"))
            } else {
                XCTFail("Unexpected error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testTranscodeHandlesFFmpegUnavailable() async {
        // Given
        let inputPath = testInputFile.path
        let profile = TranscodeProfile(name: "MP3", format: .mp3, bitrate: 192)
        let outputPath = tempDirectory.appendingPathComponent("output.mp3").path
        await ffmpegWrapper.setMockIsAvailable(false)
        
        // When/Then
        do {
            _ = try await engine.transcode(
                inputPath: inputPath,
                outputPath: outputPath,
                profile: profile,
                progress: { _ in }
            )
            XCTFail("Should have thrown error")
        } catch let error as TranscodeError {
            XCTAssertEqual(error, .engineNotAvailable)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
