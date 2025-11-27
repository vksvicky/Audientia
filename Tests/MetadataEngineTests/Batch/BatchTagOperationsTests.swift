//
//  BatchTagOperationsTests.swift
//  MetadataEngineTests
//
//  TDD tests for BatchTagOperations following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import MetadataEngine
import os.log
@testable import Shared
import XCTest

/// TDD tests for BatchTagOperations
/// Following Right-BICEP: Right, Boundary, Inverse, Cross-check, Error, Performance
@MainActor
final class BatchTagOperationsTests: XCTestCase {
    
    var batchOperations: BatchTagOperations!
    fileprivate var mockWriter: MockTagWriter!
    fileprivate var mockValidator: MockTagValidator!
    var tempDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        mockWriter = MockTagWriter()
        mockValidator = MockTagValidator()
        batchOperations = BatchTagOperations(
            writer: mockWriter,
            validator: mockValidator
        )
        
        // Create a unique temporary directory for each test run
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true, attributes: nil)
    }
    
    override func tearDown() async throws {
        batchOperations = nil
        mockWriter = nil
        mockValidator = nil
        
        // Clean up the temporary directory
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try FileManager.default.removeItem(at: tempDirectory)
        }
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// Creates a mock track for testing
    private func createTrack(
        id: UUID = UUID(),
        title: String = "Test Title",
        artist: String = "Test Artist",
        album: String = "Test Album",
        filePath: String? = nil
    ) -> Track {
        Track(
            id: id,
            title: title,
            artist: artist,
            album: album,
            duration: 180.0,
            filePath: filePath ?? "/path/to/track\(id.uuidString).mp3",
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100,
            year: 2023,
            trackNumber: 1,
            discNumber: 1,
            genre: "Rock"
        )
    }
    
    /// Creates a mock file for testing
    private func createMockFile(fileName: String) throws -> URL {
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        try Data().write(to: fileURL)
        return fileURL
    }
    
    // MARK: - Right: Are the Results Right?
    
    /// Test updating a single track
    func testUpdateSingleTrack() async throws {
        // Given - Single track
        let fileURL = try createMockFile(fileName: "track1.mp3")
        let track = createTrack(filePath: fileURL.path)
        let updatedTrack = createTrack(
            id: track.id,
            title: "Updated Title",
            artist: "Updated Artist",
            filePath: fileURL.path
        )
        mockValidator.validationResult = TagValidationResult(isValid: true, errors: [])
        
        // When - Update track
        let result = try await batchOperations.updateTracks(
            tracks: [updatedTrack],
            fileURLs: [fileURL]
        )
        
        // Then - Should succeed
        XCTAssertEqual(result.successCount, 1, "Should update 1 track successfully")
        XCTAssertEqual(result.failureCount, 0, "Should have no failures")
        XCTAssertEqual(mockWriter.writeCallCount, 1, "Writer should be called once")
    }
    
    /// Test updating multiple tracks
    func testUpdateMultipleTracks() async throws {
        // Given - Multiple tracks
        let fileURL1 = try createMockFile(fileName: "track1.mp3")
        let fileURL2 = try createMockFile(fileName: "track2.mp3")
        let fileURL3 = try createMockFile(fileName: "track3.mp3")
        
        let track1 = createTrack(filePath: fileURL1.path)
        let track2 = createTrack(filePath: fileURL2.path)
        let track3 = createTrack(filePath: fileURL3.path)
        
        let updatedTrack1 = createTrack(id: track1.id, title: "Updated 1", filePath: fileURL1.path)
        let updatedTrack2 = createTrack(id: track2.id, title: "Updated 2", filePath: fileURL2.path)
        let updatedTrack3 = createTrack(id: track3.id, title: "Updated 3", filePath: fileURL3.path)
        
        mockValidator.validationResult = TagValidationResult(isValid: true, errors: [])
        
        // When - Update tracks
        let result = try await batchOperations.updateTracks(
            tracks: [updatedTrack1, updatedTrack2, updatedTrack3],
            fileURLs: [fileURL1, fileURL2, fileURL3]
        )
        
        // Then - Should succeed for all tracks
        XCTAssertEqual(result.successCount, 3, "Should update 3 tracks successfully")
        XCTAssertEqual(result.failureCount, 0, "Should have no failures")
        XCTAssertEqual(mockWriter.writeCallCount, 3, "Writer should be called 3 times")
    }
    
    // MARK: - Boundary Conditions
    
    /// Test updating zero tracks
    func testUpdateZeroTracks() async throws {
        // Given - Empty arrays
        mockValidator.validationResult = TagValidationResult(isValid: true, errors: [])
        
        // When/Then - Should throw noTracks error
        do {
            _ = try await batchOperations.updateTracks(
                tracks: [],
                fileURLs: []
            )
            XCTFail("Should have thrown noTracks error")
        } catch let error as BatchTagOperationsError {
            XCTAssertEqual(error, .noTracks, "Should throw noTracks error for empty arrays")
            XCTAssertEqual(mockWriter.writeCallCount, 0, "Writer should not be called")
        }
    }
    
    /// Test updating with mismatched arrays (different lengths)
    func testUpdateWithMismatchedArrays() async {
        // Given - Mismatched arrays
        let fileURL = try? createMockFile(fileName: "track1.mp3")
        guard let fileURL = fileURL else {
            XCTFail("Failed to create mock file")
            return
        }
        let track = createTrack(filePath: fileURL.path)
        mockValidator.validationResult = TagValidationResult(isValid: true, errors: [])
        
        // When/Then - Should throw error
        do {
            _ = try await batchOperations.updateTracks(
                tracks: [track],
                fileURLs: [fileURL, fileURL] // Mismatched: 1 track, 2 URLs
            )
            XCTFail("Should throw error for mismatched arrays")
        } catch {
            XCTAssertTrue(error is BatchTagOperationsError, "Should throw BatchTagOperationsError")
            if case .mismatchedArrays = error as? BatchTagOperationsError {
                // Expected
            } else {
                XCTFail("Should throw mismatchedArrays error")
            }
        }
    }
    
    // MARK: - Inverse Relationships
    
    /// Test update then verify tracks were updated
    func testUpdateThenVerify() async throws {
        // Given - Track to update
        let fileURL = try createMockFile(fileName: "track1.mp3")
        let track = createTrack(filePath: fileURL.path)
        let updatedTrack = createTrack(
            id: track.id,
            title: "Updated Title",
            filePath: fileURL.path
        )
        mockValidator.validationResult = TagValidationResult(isValid: true, errors: [])
        
        // When - Update track
        let result = try await batchOperations.updateTracks(
            tracks: [updatedTrack],
            fileURLs: [fileURL]
        )
        
        // Then - Should succeed
        XCTAssertEqual(result.successCount, 1, "Should update successfully")
        XCTAssertEqual(mockWriter.lastWrittenTrack?.title, "Updated Title", "Writer should receive updated track")
    }
    
    // MARK: - Error Conditions
    
    /// Test updating with validation failure
    func testUpdateWithValidationFailure() async throws {
        // Given - Track that fails validation
        let fileURL = try createMockFile(fileName: "track1.mp3")
        let track = createTrack(filePath: fileURL.path)
        mockValidator.validationResult = TagValidationResult(
            isValid: false,
            errors: [.invalidYear(1800)]
        )
        
        // When - Update track
        let result = try await batchOperations.updateTracks(
            tracks: [track],
            fileURLs: [fileURL]
        )
        
        // Then - Should fail without writing
        XCTAssertEqual(result.successCount, 0, "Should have 0 successes")
        XCTAssertEqual(result.failureCount, 1, "Should have 1 failure")
        XCTAssertEqual(mockWriter.writeCallCount, 0, "Writer should not be called")
        XCTAssertNotNil(result.failures.first, "Should have failure entry")
    }
    
    /// Test updating with writer error
    func testUpdateWithWriterError() async throws {
        // Given - Track that causes writer error
        let fileURL = try createMockFile(fileName: "track1.mp3")
        let track = createTrack(filePath: fileURL.path)
        mockValidator.validationResult = TagValidationResult(isValid: true, errors: [])
        mockWriter.shouldThrowError = true
        mockWriter.errorToThrow = TagWriterError.writeError(fileURL, NSError(domain: "TestError", code: 1, userInfo: nil))
        
        // When - Update track
        let result = try await batchOperations.updateTracks(
            tracks: [track],
            fileURLs: [fileURL]
        )
        
        // Then - Should fail
        XCTAssertEqual(result.successCount, 0, "Should have 0 successes")
        XCTAssertEqual(result.failureCount, 1, "Should have 1 failure")
        XCTAssertNotNil(result.failures.first, "Should have failure entry")
    }
    
    /// Test partial success (some tracks succeed, some fail)
    func testPartialSuccess() async throws {
        // Given - Multiple tracks, one fails validation
        let fileURL1 = try createMockFile(fileName: "track1.mp3")
        let fileURL2 = try createMockFile(fileName: "track2.mp3")
        
        let track1 = createTrack(filePath: fileURL1.path)
        let track2 = createTrack(filePath: fileURL2.path)
        
        // First track passes validation, second fails
        mockValidator.validationResults = [
            TagValidationResult(isValid: true, errors: []),
            TagValidationResult(isValid: false, errors: [.invalidYear(1800)])
        ]
        
        // When - Update tracks
        let result = try await batchOperations.updateTracks(
            tracks: [track1, track2],
            fileURLs: [fileURL1, fileURL2]
        )
        
        // Then - Should have partial success
        XCTAssertEqual(result.successCount, 1, "Should have 1 success")
        XCTAssertEqual(result.failureCount, 1, "Should have 1 failure")
        XCTAssertEqual(mockWriter.writeCallCount, 1, "Writer should be called once (only for valid track)")
    }
    
    // MARK: - Performance Characteristics
    
    /// Test batch update performance
    func testBatchUpdatePerformance() async throws {
        // Given - Many tracks (reduced count for faster performance test)
        let tracks = (0..<50).map { _ in
            createTrack()
        }
        let fileURLs = try (0..<50).map { index in
            try createMockFile(fileName: "track\(index).mp3")
        }
        mockValidator.validationResult = TagValidationResult(isValid: true, errors: [])
        
        // When - Measure performance of batch update
        // Run multiple iterations and measure average time
        let iterations = 5
        var times: [TimeInterval] = []
        
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            do {
                _ = try await batchOperations.updateTracks(
                    tracks: tracks,
                    fileURLs: fileURLs
                )
            } catch {
                // Ignore errors in performance test
            }
            
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            times.append(elapsed)
        }
        
        let average = times.reduce(0, +) / Double(times.count)
        Logger.testing.info("Average batch update time for 50 tracks: \(String(format: "%.2f", average * 1000), privacy: .public)ms")
        
        // Verify performance is reasonable (< 5 seconds for 50 tracks)
        XCTAssertLessThan(average, 5.0, "Batch update should complete in reasonable time")
    }
}
// MARK: - Mock Classes

/// Mock TagWriter for testing
private final class MockTagWriter: TagWriterProtocol, @unchecked Sendable {
    let supportedExtensions: Set<String> = ["mp3", "flac", "m4a"]
    var writeCallCount = 0
    var lastWrittenTrack: Track?
    var shouldThrowError = false
    var errorToThrow: Error?
    
    func canWrite(fileURL: URL) -> Bool {
        supportedExtensions.contains(fileURL.pathExtension.lowercased())
    }
    
    func write(track: Track, to fileURL: URL) async throws {
        writeCallCount += 1
        lastWrittenTrack = track
        
        if shouldThrowError {
            throw errorToThrow ?? TagWriterError.writeError(fileURL, NSError(domain: "MockError", code: 1, userInfo: nil))
        }
    }
    
    func update(track: Track, in fileURL: URL) async throws {
        try await write(track: track, to: fileURL)
    }
}

/// Mock TagValidator for testing
private final class MockTagValidator: TagValidatorProtocol, @unchecked Sendable {
    var validationResult = TagValidationResult(isValid: true, errors: [])
    var validationResults: [TagValidationResult] = []
    private var validationCallCount = 0
    
    func validate(track: Track) -> TagValidationResult {
        if !validationResults.isEmpty {
            let index = validationCallCount % validationResults.count
            validationCallCount += 1
            return validationResults[index]
        }
        return validationResult
    }
}
