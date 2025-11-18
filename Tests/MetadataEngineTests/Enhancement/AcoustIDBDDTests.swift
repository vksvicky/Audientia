//
//  AcoustIDBDDTests.swift
//  MetadataEngineTests
//
//  BDD tests for AcoustID fingerprinting and lookup
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// BDD tests for AcoustID fingerprinting and lookup following user-centric scenarios
final class AcoustIDBDDTests: XCTestCase {
    
    // MARK: - BDD Scenarios
    
    func testUserWantsToIdentifyUnknownTrack() async throws {
        // Scenario: As a user, I want to identify an unknown track using AcoustID
        
        // Given: I have an audio file with no metadata
        let fileURL = createTempAudioFile()
        let generator = MockFingerprintGenerator()
        generator.mockFingerprint = "AQADtE..."
        
        let lookupService = MockAcoustIDLookup()
        let expectedMatch = AcoustIDMatch(
            recordingID: "mbid-123",
            title: "Bohemian Rhapsody",
            artist: "Queen",
            album: "A Night at the Opera",
            year: 1975,
            trackNumber: 11,
            genre: "Rock",
            score: 0.98
        )
        lookupService.mockMatches = [expectedMatch]
        
        // When: I generate a fingerprint and look it up
        let fingerprint = try await generator.generateFingerprint(fileURL: fileURL)
        let duration: TimeInterval = 355.0 // 5:55
        let matches = try await lookupService.lookup(fingerprint: fingerprint, duration: duration)
        
        // Then: I see the track is identified as "Bohemian Rhapsody" by Queen
        XCTAssertFalse(matches.isEmpty)
        guard let bestMatch = matches.first else {
            XCTFail("Expected a match")
            return
        }
        XCTAssertEqual(bestMatch.title, "Bohemian Rhapsody")
        XCTAssertEqual(bestMatch.artist, "Queen")
        XCTAssertEqual(bestMatch.album, "A Night at the Opera")
        XCTAssertEqual(bestMatch.year, 1975)
        XCTAssertGreaterThanOrEqual(bestMatch.score, 0.9, "High confidence match")
    }
    
    func testUserWantsToSeeMultipleMatchesForAmbiguousTrack() async throws {
        // Scenario: As a user, I want to see multiple matches when a track is ambiguous
        
        // Given: I have a track that could match multiple recordings
        let fileURL = createTempAudioFile()
        let generator = MockFingerprintGenerator()
        generator.mockFingerprint = "AQADtE..."
        
        let lookupService = MockAcoustIDLookup()
        let match1 = AcoustIDMatch(
            recordingID: "mbid-123",
            title: "Stairway to Heaven",
            artist: "Led Zeppelin",
            album: "Led Zeppelin IV",
            year: 1971,
            score: 0.95
        )
        let match2 = AcoustIDMatch(
            recordingID: "mbid-456",
            title: "Stairway to Heaven",
            artist: "Led Zeppelin",
            album: "Led Zeppelin IV (Remastered)",
            year: 2014,
            score: 0.90
        )
        let match3 = AcoustIDMatch(
            recordingID: "mbid-789",
            title: "Stairway to Heaven (Live)",
            artist: "Led Zeppelin",
            album: "How the West Was Won",
            year: 2003,
            score: 0.85
        )
        lookupService.mockMatches = [match1, match2, match3]
        
        // When: I look up the fingerprint
        let fingerprint = try await generator.generateFingerprint(fileURL: fileURL)
        let duration: TimeInterval = 482.0 // 8:02
        let matches = try await lookupService.lookup(fingerprint: fingerprint, duration: duration)
        
        // Then: I see multiple matches sorted by confidence
        XCTAssertEqual(matches.count, 3)
        XCTAssertEqual(matches[0].score, 0.95)
        XCTAssertEqual(matches[1].score, 0.90)
        XCTAssertEqual(matches[2].score, 0.85)
        XCTAssertTrue(matches.allSatisfy { $0.title == "Stairway to Heaven" })
        XCTAssertTrue(matches.allSatisfy { $0.artist == "Led Zeppelin" })
    }
    
    func testUserWantsToHandleTrackWithNoMatches() async {
        // Scenario: As a user, I want to handle tracks that have no matches
        
        // Given: I have a track that doesn't exist in AcoustID database
        let fileURL = createTempAudioFile()
        let generator = MockFingerprintGenerator()
        generator.mockFingerprint = "AQADtE..."
        
        let lookupService = MockAcoustIDLookup()
        lookupService.shouldFail = true
        lookupService.errorToThrow = AcoustIDError.noMatchesFound
        
        // When: I try to look up the fingerprint
        let fingerprint = try? await generator.generateFingerprint(fileURL: fileURL)
        guard let fingerprint = fingerprint else {
            XCTFail("Failed to generate fingerprint")
            return
        }
        
        do {
            _ = try await lookupService.lookup(fingerprint: fingerprint, duration: 180.0)
            XCTFail("Should have thrown noMatchesFound error")
        } catch let error as AcoustIDError {
            // Then: I see a clear message that no matches were found
            XCTAssertEqual(error, .noMatchesFound)
            XCTAssertNotNil(error.errorDescription)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testUserWantsToHandleNetworkErrorsGracefully() async {
        // Scenario: As a user, I want network errors to be handled gracefully
        
        // Given: I have a network connection issue
        let fileURL = createTempAudioFile()
        let generator = MockFingerprintGenerator()
        generator.mockFingerprint = "AQADtE..."
        
        let lookupService = MockAcoustIDLookup()
        lookupService.shouldFail = true
        lookupService.errorToThrow = AcoustIDError.networkError("Connection timeout")
        
        // When: I try to look up a fingerprint
        let fingerprint = try? await generator.generateFingerprint(fileURL: fileURL)
        guard let fingerprint = fingerprint else {
            XCTFail("Failed to generate fingerprint")
            return
        }
        
        do {
            _ = try await lookupService.lookup(fingerprint: fingerprint, duration: 180.0)
            XCTFail("Should have thrown network error")
        } catch let error as AcoustIDError {
            // Then: I see a clear error message about the network issue
            XCTAssertEqual(error, .networkError("Connection timeout"))
            XCTAssertNotNil(error.errorDescription)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testUserWantsToHandleRateLimitErrors() async {
        // Scenario: As a user, I want rate limit errors to be handled gracefully
        
        // Given: I have exceeded the API rate limit
        let fileURL = createTempAudioFile()
        let generator = MockFingerprintGenerator()
        generator.mockFingerprint = "AQADtE..."
        
        let lookupService = MockAcoustIDLookup()
        lookupService.shouldFail = true
        lookupService.errorToThrow = AcoustIDError.rateLimitExceeded
        
        // When: I try to look up a fingerprint
        let fingerprint = try? await generator.generateFingerprint(fileURL: fileURL)
        guard let fingerprint = fingerprint else {
            XCTFail("Failed to generate fingerprint")
            return
        }
        
        do {
            _ = try await lookupService.lookup(fingerprint: fingerprint, duration: 180.0)
            XCTFail("Should have thrown rate limit error")
        } catch let error as AcoustIDError {
            // Then: I see a clear message about rate limiting
            XCTAssertEqual(error, .rateLimitExceeded)
            XCTAssertNotNil(error.errorDescription)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testUserWantsToSeePartialMetadataWhenAvailable() async throws {
        // Scenario: As a user, I want to see partial metadata when full metadata isn't available
        
        // Given: I have a track that matches but has incomplete metadata
        let fileURL = createTempAudioFile()
        let generator = MockFingerprintGenerator()
        generator.mockFingerprint = "AQADtE..."
        
        let lookupService = MockAcoustIDLookup()
        let partialMatch = AcoustIDMatch(
            recordingID: "mbid-123",
            title: "Unknown Track",
            artist: "Unknown Artist",
            album: nil,
            year: nil,
            trackNumber: nil,
            discNumber: nil,
            genre: nil,
            score: 0.75
        )
        lookupService.mockMatches = [partialMatch]
        
        // When: I look up the fingerprint
        let fingerprint = try await generator.generateFingerprint(fileURL: fileURL)
        let matches = try await lookupService.lookup(fingerprint: fingerprint, duration: 180.0)
        
        // Then: I see the available metadata (title and artist) even though other fields are missing
        XCTAssertEqual(matches.count, 1)
        guard let match = matches.first else {
            XCTFail("Expected at least one match")
            return
        }
        XCTAssertEqual(match.title, "Unknown Track")
        XCTAssertEqual(match.artist, "Unknown Artist")
        XCTAssertNil(match.album)
        XCTAssertNil(match.year)
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
