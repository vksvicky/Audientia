//
//  BatchTagOperationsBDDTests.swift
//  MetadataEngineTests
//
//  BDD tests for BatchTagOperations
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// BDD tests for BatchTagOperations
/// Scenarios: "As a user, I want to update multiple tracks at once"
@MainActor
final class BatchTagOperationsBDDTests: XCTestCase {
    
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
        
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true, attributes: nil)
    }
    
    override func tearDown() async throws {
        batchOperations = nil
        mockWriter = nil
        mockValidator = nil
        
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try FileManager.default.removeItem(at: tempDirectory)
        }
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createTrack(
        id: UUID = UUID(),
        title: String = "Test Title",
        artist: String = "Test Artist",
        filePath: String? = nil,
        year: Int? = 2023
    ) -> Track {
        Track(
            id: id,
            title: title,
            artist: artist,
            album: "Test Album",
            duration: 180.0,
            filePath: filePath ?? "/path/to/track\(id.uuidString).mp3",
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100,
            year: year,
            trackNumber: 1,
            discNumber: 1,
            genre: "Rock"
        )
    }
    
    private func createMockFile(fileName: String) throws -> URL {
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        try Data().write(to: fileURL)
        return fileURL
    }
    
    // MARK: - Scenario: Batch Update Success
    
    /// Scenario: As a user, I want to update multiple tracks with new metadata at once
    /// Given: I have 5 tracks that need their artist name updated
    /// When: I perform a batch update operation
    /// Then: All 5 tracks should be updated successfully
    func testUserUpdatesMultipleTracksAtOnce() async throws {
        // Given - 5 tracks that need updating
        let fileURLs = try (1...5).map { index in
            try createMockFile(fileName: "track\(index).mp3")
        }
        let tracks = fileURLs.enumerated().map { index, url in
            createTrack(title: "Song \(index + 1)", artist: "New Artist", filePath: url.path)
        }
        mockValidator.validationResult = TagValidationResult(isValid: true, errors: [])
        
        // When - Perform batch update
        let result = try await batchOperations.updateTracks(
            tracks: tracks,
            fileURLs: fileURLs
        )
        
        // Then - All tracks should be updated
        XCTAssertEqual(result.successCount, 5, "All 5 tracks should be updated successfully")
        XCTAssertEqual(result.failureCount, 0, "Should have no failures")
        XCTAssertEqual(mockWriter.writeCallCount, 5, "Writer should be called 5 times")
    }
    
    // MARK: - Scenario: Batch Update with Validation Failures
    
    /// Scenario: As a user, I want to see which tracks failed validation during batch update
    /// Given: I have 3 tracks, one with invalid year
    /// When: I perform a batch update operation
    /// Then: 2 tracks should succeed, 1 should fail with validation error
    func testUserSeesValidationFailuresInBatchUpdate() async throws {
        // Given - 3 tracks, one with invalid year
        let fileURLs = try (1...3).map { index in
            try createMockFile(fileName: "track\(index).mp3")
        }
        let track1 = createTrack(filePath: fileURLs[0].path, year: 2023)
        let track2 = createTrack(filePath: fileURLs[1].path, year: 1800) // Invalid year
        let track3 = createTrack(filePath: fileURLs[2].path, year: 2023)
        
        // First and third pass validation, second fails
        mockValidator.validationResults = [
            TagValidationResult(isValid: true, errors: []),
            TagValidationResult(isValid: false, errors: [.invalidYear(1800)]),
            TagValidationResult(isValid: true, errors: [])
        ]
        
        // When - Perform batch update
        let result = try await batchOperations.updateTracks(
            tracks: [track1, track2, track3],
            fileURLs: fileURLs
        )
        
        // Then - 2 should succeed, 1 should fail
        XCTAssertEqual(result.successCount, 2, "2 tracks should succeed")
        XCTAssertEqual(result.failureCount, 1, "1 track should fail")
        XCTAssertEqual(result.failures.count, 1, "Should have 1 failure entry")
        XCTAssertEqual(mockWriter.writeCallCount, 2, "Writer should be called 2 times (only for valid tracks)")
    }
    
    // MARK: - Scenario: Batch Update with Partial Failures
    
    /// Scenario: As a user, I want batch operations to continue even if some tracks fail
    /// Given: I have 10 tracks, 2 will fail due to write errors
    /// When: I perform a batch update operation
    /// Then: 8 tracks should succeed, 2 should fail, operation should complete
    func testUserSeesPartialFailuresInBatchUpdate() async throws {
        // Given - 10 tracks, 2 will fail
        let fileURLs = try (1...10).map { _ in
            try createMockFile(fileName: "track\(UUID().uuidString).mp3")
        }
        let tracks = fileURLs.map { url in
            createTrack(filePath: url.path)
        }
        mockValidator.validationResult = TagValidationResult(isValid: true, errors: [])
        
        // Make writer fail for tracks 3 and 7
        mockWriter.failingIndices = [2, 6] // 0-based indices
        mockWriter.allFileURLs = fileURLs
        
        // When - Perform batch update
        let result = try await batchOperations.updateTracks(
            tracks: tracks,
            fileURLs: fileURLs
        )
        
        // Then - 8 should succeed, 2 should fail
        XCTAssertEqual(result.successCount, 8, "8 tracks should succeed")
        XCTAssertEqual(result.failureCount, 2, "2 tracks should fail")
        XCTAssertEqual(result.failures.count, 2, "Should have 2 failure entries")
    }
}

// MARK: - Enhanced Mock Classes

private final class MockTagWriter: TagWriterProtocol, @unchecked Sendable {
    let supportedExtensions: Set<String> = ["mp3", "flac", "m4a"]
    var writeCallCount = 0
    var lastWrittenTrack: Track?
    var shouldThrowError = false
    var errorToThrow: Error?
    var failingIndices: Set<Int> = []
    var allFileURLs: [URL] = []
    private var writeIndex = 0
    
    func canWrite(fileURL: URL) -> Bool {
        supportedExtensions.contains(fileURL.pathExtension.lowercased())
    }
    
    func write(track: Track, to fileURL: URL) async throws {
        writeCallCount += 1
        lastWrittenTrack = track
        let currentIndex = writeIndex
        writeIndex += 1
        
        if shouldThrowError || failingIndices.contains(currentIndex) {
            throw errorToThrow ?? TagWriterError.writeError(fileURL, NSError(domain: "MockError", code: 1, userInfo: nil))
        }
    }
    
    func update(track: Track, in fileURL: URL) async throws {
        try await write(track: track, to: fileURL)
    }
}

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
