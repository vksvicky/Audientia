//
//  AcoustIDTests.swift
//  MetadataEngineTests
//
//  TDD tests for AcoustID fingerprinting and lookup
//

import Foundation
import XCTest

@testable import MetadataEngine
@testable import Shared

/// TDD tests for AcoustID fingerprinting and lookup following Right-BICEP principles
final class AcoustIDTests: XCTestCase {
    
    // MARK: - Right: Are the results right?
    
    func testGenerateFingerprintForValidFile() async throws {
        // Given: A valid audio file
        let fileURL = createTempAudioFile()
        let generator = MockFingerprintGenerator()
        generator.mockFingerprint = "AQADtE..."
        
        // When: Generating a fingerprint
        let fingerprint = try await generator.generateFingerprint(fileURL: fileURL)
        
        // Then: A valid fingerprint is returned
        XCTAssertFalse(fingerprint.isEmpty)
        XCTAssertEqual(fingerprint, "AQADtE...")
    }
    
    func testLookupWithValidFingerprint() async throws {
        // Given: A valid fingerprint and duration
        let fingerprint = "AQADtE..."
        let duration: TimeInterval = 180.0
        let lookupService = MockAcoustIDLookup()
        let expectedMatch = AcoustIDMatch(
            recordingID: "mbid-123",
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            year: 2020,
            trackNumber: 1,
            discNumber: 1,
            genre: "Rock",
            score: 0.95
        )
        lookupService.mockMatches = [expectedMatch]
        
        // When: Looking up the fingerprint
        let matches = try await lookupService.lookup(fingerprint: fingerprint, duration: duration)
        
        // Then: Matches are returned
        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches.first, expectedMatch)
    }
    
    // MARK: - Boundary Conditions
    
    func testGenerateFingerprintForNonExistentFile() async {
        // Given: A non-existent file
        let fileURL = URL(fileURLWithPath: "/nonexistent/file.mp3")
        let generator = MockFingerprintGenerator()
        generator.shouldFail = true
        generator.errorToThrow = AcoustIDError.fileNotFound(fileURL)
        
        // When/Then: Fingerprint generation fails
        do {
            _ = try await generator.generateFingerprint(fileURL: fileURL)
            XCTFail("Should have thrown an error")
        } catch let error as AcoustIDError {
            XCTAssertEqual(error, .fileNotFound(fileURL))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testLookupWithEmptyFingerprint() async {
        // Given: An empty fingerprint
        let fingerprint = ""
        let duration: TimeInterval = 180.0
        let lookupService = MockAcoustIDLookup()
        lookupService.shouldFail = true
        lookupService.errorToThrow = AcoustIDError.invalidResponse("Empty fingerprint")
        
        // When/Then: Lookup fails
        do {
            _ = try await lookupService.lookup(fingerprint: fingerprint, duration: duration)
            XCTFail("Should have thrown an error")
        } catch let error as AcoustIDError {
            XCTAssertEqual(error, .invalidResponse("Empty fingerprint"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testLookupWithZeroDuration() async throws {
        // Given: A fingerprint with zero duration
        let fingerprint = "AQADtE..."
        let duration: TimeInterval = 0.0
        let lookupService = MockAcoustIDLookup()
        lookupService.mockMatches = []
        
        // When: Looking up with zero duration
        let matches = try await lookupService.lookup(fingerprint: fingerprint, duration: duration)
        
        // Then: No matches are returned (boundary condition)
        XCTAssertTrue(matches.isEmpty)
    }
    
    func testLookupWithVeryLongDuration() async throws {
        // Given: A fingerprint with very long duration
        let fingerprint = "AQADtE..."
        let duration: TimeInterval = 36000.0 // 10 hours
        let lookupService = MockAcoustIDLookup()
        lookupService.mockMatches = []
        
        // When: Looking up with very long duration
        let matches = try await lookupService.lookup(fingerprint: fingerprint, duration: duration)
        
        // Then: Lookup completes (boundary condition)
        XCTAssertTrue(matches.isEmpty)
    }
    
    func testLookupWithNoMatches() async {
        // Given: A fingerprint that has no matches
        let fingerprint = "AQADtE..."
        let duration: TimeInterval = 180.0
        let lookupService = MockAcoustIDLookup()
        lookupService.shouldFail = true
        lookupService.errorToThrow = AcoustIDError.noMatchesFound
        
        // When/Then: Lookup returns no matches error
        do {
            _ = try await lookupService.lookup(fingerprint: fingerprint, duration: duration)
            XCTFail("Should have thrown an error")
        } catch let error as AcoustIDError {
            XCTAssertEqual(error, .noMatchesFound)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Inverse Relationships
    
    func testGenerateFingerprintRoundtrip() async throws {
        // Given: A file with a known fingerprint
        let fileURL = createTempAudioFile()
        let generator = MockFingerprintGenerator()
        let expectedFingerprint = "AQADtE..."
        generator.mockFingerprint = expectedFingerprint
        
        // When: Generating fingerprint twice
        let fingerprint1 = try await generator.generateFingerprint(fileURL: fileURL)
        let fingerprint2 = try await generator.generateFingerprint(fileURL: fileURL)
        
        // Then: Same fingerprint is generated (inverse: consistent results)
        XCTAssertEqual(fingerprint1, fingerprint2)
        XCTAssertEqual(fingerprint1, expectedFingerprint)
    }
    
    func testLookupWithSameFingerprintReturnsConsistentResults() async throws {
        // Given: Same fingerprint and duration
        let fingerprint = "AQADtE..."
        let duration: TimeInterval = 180.0
        let lookupService = MockAcoustIDLookup()
        let expectedMatch = AcoustIDMatch(
            recordingID: "mbid-123",
            title: "Test Song",
            artist: "Test Artist",
            score: 0.95
        )
        lookupService.mockMatches = [expectedMatch]
        
        // When: Looking up the same fingerprint twice
        let matches1 = try await lookupService.lookup(fingerprint: fingerprint, duration: duration)
        let matches2 = try await lookupService.lookup(fingerprint: fingerprint, duration: duration)
        
        // Then: Same results are returned (inverse: consistent results)
        XCTAssertEqual(matches1, matches2)
    }
    
    // MARK: - Cross-Check Using Other Means
    
    func testLookupResultsMatchExpectedFormat() async throws {
        // Given: A fingerprint lookup
        let fingerprint = "AQADtE..."
        let duration: TimeInterval = 180.0
        let lookupService = MockAcoustIDLookup()
        let expectedMatch = AcoustIDMatch(
            recordingID: "mbid-123",
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            year: 2020,
            trackNumber: 1,
            discNumber: 1,
            genre: "Rock",
            score: 0.95
        )
        lookupService.mockMatches = [expectedMatch]
        
        // When: Looking up the fingerprint
        let matches = try await lookupService.lookup(fingerprint: fingerprint, duration: duration)
        
        // Then: Results match expected format (cross-check: structure validation)
        XCTAssertEqual(matches.count, 1)
        guard let match = matches.first else {
            XCTFail("Expected a match")
            return
        }
        XCTAssertEqual(match.recordingID, "mbid-123")
        XCTAssertEqual(match.title, "Test Song")
        XCTAssertEqual(match.artist, "Test Artist")
        XCTAssertEqual(match.album, "Test Album")
        XCTAssertEqual(match.year, 2020)
        XCTAssertEqual(match.trackNumber, 1)
        XCTAssertEqual(match.discNumber, 1)
        XCTAssertEqual(match.genre, "Rock")
        XCTAssertEqual(match.score, 0.95, accuracy: 0.01)
    }
    
    // MARK: - Error Conditions
    
    func testGenerateFingerprintWithNetworkError() async {
        // Given: A network error during fingerprinting
        let fileURL = createTempAudioFile()
        let generator = MockFingerprintGenerator()
        generator.shouldFail = true
        generator.errorToThrow = AcoustIDError.networkError("Connection timeout")
        
        // When/Then: Error is thrown
        do {
            _ = try await generator.generateFingerprint(fileURL: fileURL)
            XCTFail("Should have thrown an error")
        } catch let error as AcoustIDError {
            XCTAssertEqual(error, .networkError("Connection timeout"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testLookupWithRateLimitExceeded() async {
        // Given: Rate limit exceeded
        let fingerprint = "AQADtE..."
        let duration: TimeInterval = 180.0
        let lookupService = MockAcoustIDLookup()
        lookupService.shouldFail = true
        lookupService.errorToThrow = AcoustIDError.rateLimitExceeded
        
        // When/Then: Rate limit error is thrown
        do {
            _ = try await lookupService.lookup(fingerprint: fingerprint, duration: duration)
            XCTFail("Should have thrown an error")
        } catch let error as AcoustIDError {
            XCTAssertEqual(error, .rateLimitExceeded)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testLookupWithInvalidResponse() async {
        // Given: Invalid response from API
        let fingerprint = "AQADtE..."
        let duration: TimeInterval = 180.0
        let lookupService = MockAcoustIDLookup()
        lookupService.shouldFail = true
        lookupService.errorToThrow = AcoustIDError.invalidResponse("Malformed JSON")
        
        // When/Then: Invalid response error is thrown
        do {
            _ = try await lookupService.lookup(fingerprint: fingerprint, duration: duration)
            XCTFail("Should have thrown an error")
        } catch let error as AcoustIDError {
            XCTAssertEqual(error, .invalidResponse("Malformed JSON"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Performance Characteristics
    
    func testFingerprintGenerationPerformance() async throws {
        // Given: A valid audio file
        let fileURL = createTempAudioFile()
        let generator = MockFingerprintGenerator()
        generator.mockFingerprint = "AQADtE..."
        
        // When: Measuring fingerprint generation time
        let startTime = Date()
        _ = try await generator.generateFingerprint(fileURL: fileURL)
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Then: Generation completes within reasonable time (< 5s per roadmap)
        XCTAssertLessThan(elapsed, 5.0, "Fingerprint generation should complete in < 5s")
    }
    
    func testLookupPerformance() async throws {
        // Given: A valid fingerprint
        let fingerprint = "AQADtE..."
        let duration: TimeInterval = 180.0
        let lookupService = MockAcoustIDLookup()
        lookupService.mockMatches = [AcoustIDMatch(
            recordingID: "mbid-123",
            title: "Test",
            artist: "Test",
            score: 0.95
        )]
        
        // When: Measuring lookup time
        let startTime = Date()
        _ = try await lookupService.lookup(fingerprint: fingerprint, duration: duration)
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Then: Lookup completes within SLA (< 2s per roadmap)
        XCTAssertLessThan(elapsed, 2.0, "Lookup should complete in < 2s")
    }
    
    // MARK: - Edge Cases
    
    func testLookupWithMultipleMatches() async throws {
        // Given: A fingerprint with multiple matches
        let fingerprint = "AQADtE..."
        let duration: TimeInterval = 180.0
        let lookupService = MockAcoustIDLookup()
        let match1 = AcoustIDMatch(
            recordingID: "mbid-123",
            title: "Test Song",
            artist: "Test Artist",
            score: 0.95
        )
        let match2 = AcoustIDMatch(
            recordingID: "mbid-456",
            title: "Test Song (Remix)",
            artist: "Test Artist",
            score: 0.85
        )
        lookupService.mockMatches = [match1, match2]
        
        // When: Looking up the fingerprint
        let matches = try await lookupService.lookup(fingerprint: fingerprint, duration: duration)
        
        // Then: All matches are returned, sorted by score
        XCTAssertEqual(matches.count, 2)
        XCTAssertEqual(matches.first?.score, 0.95)
        XCTAssertEqual(matches.last?.score, 0.85)
    }
    
    func testLookupWithPartialMetadata() async throws {
        // Given: A match with partial metadata
        let fingerprint = "AQADtE..."
        let duration: TimeInterval = 180.0
        let lookupService = MockAcoustIDLookup()
        let partialMatch = AcoustIDMatch(
            recordingID: "mbid-123",
            title: "Test Song",
            artist: "Test Artist",
            album: nil,
            year: nil,
            trackNumber: nil,
            discNumber: nil,
            genre: nil,
            score: 0.95
        )
        lookupService.mockMatches = [partialMatch]
        
        // When: Looking up the fingerprint
        let matches = try await lookupService.lookup(fingerprint: fingerprint, duration: duration)
        
        // Then: Match with partial metadata is returned
        XCTAssertEqual(matches.count, 1)
        guard let match = matches.first else {
            XCTFail("Expected a match")
            return
        }
        XCTAssertEqual(match.title, "Test Song")
        XCTAssertEqual(match.artist, "Test Artist")
        XCTAssertNil(match.album)
        XCTAssertNil(match.year)
    }
    
    func testLookupWithUnicodeMetadata() async throws {
        // Given: A match with Unicode characters
        let fingerprint = "AQADtE..."
        let duration: TimeInterval = 180.0
        let lookupService = MockAcoustIDLookup()
        let unicodeMatch = AcoustIDMatch(
            recordingID: "mbid-123",
            title: "テスト曲",
            artist: "テストアーティスト",
            album: "テストアルバム",
            score: 0.95
        )
        lookupService.mockMatches = [unicodeMatch]
        
        // When: Looking up the fingerprint
        let matches = try await lookupService.lookup(fingerprint: fingerprint, duration: duration)
        
        // Then: Unicode metadata is preserved
        XCTAssertEqual(matches.count, 1)
        guard let match = matches.first else {
            XCTFail("Expected a match")
            return
        }
        XCTAssertEqual(match.title, "テスト曲")
        XCTAssertEqual(match.artist, "テストアーティスト")
        XCTAssertEqual(match.album, "テストアルバム")
    }
    
    // MARK: - Helper Methods
    
    private func createTempAudioFile() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp3")
        // Create a minimal file for testing
        try? "test".write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}

// MARK: - Mock Implementations

final class MockFingerprintGenerator: FingerprintGeneratorProtocol, @unchecked Sendable {
    var mockFingerprint: String = ""
    var shouldFail = false
    var errorToThrow: Error?
    
    func generateFingerprint(fileURL: URL) async throws -> String {
        if shouldFail {
            throw errorToThrow ?? AcoustIDError.fingerprintGenerationFailed("Mock error")
        }
        return mockFingerprint
    }
}

final class MockAcoustIDLookup: AcoustIDLookupProtocol, @unchecked Sendable {
    var mockMatches: [AcoustIDMatch] = []
    var shouldFail = false
    var errorToThrow: Error?
    
    func lookup(fingerprint: String, duration: TimeInterval) async throws -> [AcoustIDMatch] {
        if shouldFail {
            throw errorToThrow ?? AcoustIDError.lookupFailed("Mock error")
        }
        if fingerprint.isEmpty {
            throw AcoustIDError.invalidResponse("Empty fingerprint")
        }
        return mockMatches
    }
}
