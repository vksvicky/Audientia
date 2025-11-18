//
//  AcoustIDServiceTests.swift
//  MetadataEngineTests
//
//  TDD tests for AcoustIDService
//

import Foundation
import XCTest

@testable import MetadataEngine
@testable import Shared

/// TDD tests for AcoustIDService following Right-BICEP principles
final class AcoustIDServiceTests: XCTestCase {
    
    // MARK: - Right: Are the results right?
    
    func testIdentifyTrackWithValidFile() async throws {
        // Given: A valid audio file
        let fileURL = createTempAudioFile()
        let generator = MockFingerprintGenerator()
        generator.mockFingerprint = "AQADtE..."
        
        let lookupService = MockAcoustIDLookup()
        let expectedMatch = AcoustIDMatch(
            recordingID: "mbid-123",
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            year: 2020,
            score: 0.95
        )
        lookupService.mockMatches = [expectedMatch]
        
        let service = AcoustIDService(
            fingerprintGenerator: generator,
            lookupService: lookupService
        )
        
        // When: Identifying the track
        let matches = try await service.identifyTrack(fileURL: fileURL)
        
        // Then: Matches are returned, sorted by score
        XCTAssertEqual(matches.count, 1)
        guard let match = matches.first else {
            XCTFail("Expected a match")
            return
        }
        XCTAssertEqual(match.recordingID, "mbid-123")
        XCTAssertEqual(match.title, "Test Song")
        XCTAssertEqual(match.artist, "Test Artist")
    }
    
    func testIdentifyTrackWithTrackObject() async throws {
        // Given: A Track object
        let track = Track(
            id: UUID(),
            title: "Unknown",
            artist: "Unknown",
            album: "Unknown",
            duration: 180.0,
            filePath: createTempAudioFile().path,
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100
        )
        
        let generator = MockFingerprintGenerator()
        generator.mockFingerprint = "AQADtE..."
        
        let lookupService = MockAcoustIDLookup()
        let expectedMatch = AcoustIDMatch(
            recordingID: "mbid-123",
            title: "Test Song",
            artist: "Test Artist",
            score: 0.95
        )
        lookupService.mockMatches = [expectedMatch]
        
        let service = AcoustIDService(
            fingerprintGenerator: generator,
            lookupService: lookupService
        )
        
        // When: Identifying the track
        let matches = try await service.identifyTrack(track)
        
        // Then: Matches are returned using track duration
        XCTAssertEqual(matches.count, 1)
        guard let match = matches.first else {
            XCTFail("Expected a match")
            return
        }
        XCTAssertEqual(match.title, "Test Song")
    }
    
    // MARK: - Boundary Conditions
    
    func testIdentifyTrackWithNoMatches() async {
        // Given: A track with no matches
        let fileURL = createTempAudioFile()
        let generator = MockFingerprintGenerator()
        generator.mockFingerprint = "AQADtE..."
        
        let lookupService = MockAcoustIDLookup()
        lookupService.shouldFail = true
        lookupService.errorToThrow = AcoustIDError.noMatchesFound
        
        let service = AcoustIDService(
            fingerprintGenerator: generator,
            lookupService: lookupService
        )
        
        // When/Then: Error is thrown
        do {
            _ = try await service.identifyTrack(fileURL: fileURL)
            XCTFail("Should have thrown an error")
        } catch let error as AcoustIDError {
            XCTAssertEqual(error, .noMatchesFound)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Inverse Relationships
    
    func testIdentifyTrackReturnsConsistentResults() async throws {
        // Given: Same file identified twice
        let fileURL = createTempAudioFile()
        let generator = MockFingerprintGenerator()
        generator.mockFingerprint = "AQADtE..."
        
        let lookupService = MockAcoustIDLookup()
        let expectedMatch = AcoustIDMatch(
            recordingID: "mbid-123",
            title: "Test Song",
            artist: "Test Artist",
            score: 0.95
        )
        lookupService.mockMatches = [expectedMatch]
        
        let service = AcoustIDService(
            fingerprintGenerator: generator,
            lookupService: lookupService
        )
        
        // When: Identifying the same track twice
        let matches1 = try await service.identifyTrack(fileURL: fileURL)
        let matches2 = try await service.identifyTrack(fileURL: fileURL)
        
        // Then: Same results are returned (inverse: consistent results)
        XCTAssertEqual(matches1, matches2)
    }
    
    // MARK: - Cross-Check Using Other Means
    
    func testIdentifyTrackSortsMatchesByScore() async throws {
        // Given: Multiple matches with different scores
        let fileURL = createTempAudioFile()
        let generator = MockFingerprintGenerator()
        generator.mockFingerprint = "AQADtE..."
        
        let lookupService = MockAcoustIDLookup()
        let match1 = AcoustIDMatch(
            recordingID: "mbid-123",
            title: "Test Song",
            artist: "Test Artist",
            score: 0.85
        )
        let match2 = AcoustIDMatch(
            recordingID: "mbid-456",
            title: "Test Song (Remix)",
            artist: "Test Artist",
            score: 0.95
        )
        let match3 = AcoustIDMatch(
            recordingID: "mbid-789",
            title: "Test Song (Live)",
            artist: "Test Artist",
            score: 0.90
        )
        lookupService.mockMatches = [match1, match2, match3]
        
        let service = AcoustIDService(
            fingerprintGenerator: generator,
            lookupService: lookupService
        )
        
        // When: Identifying the track
        let matches = try await service.identifyTrack(fileURL: fileURL)
        
        // Then: Matches are sorted by score (highest first)
        XCTAssertEqual(matches.count, 3)
        XCTAssertEqual(matches[0].score, 0.95)
        XCTAssertEqual(matches[1].score, 0.90)
        XCTAssertEqual(matches[2].score, 0.85)
    }
    
    // MARK: - Error Conditions
    
    func testIdentifyTrackWithFingerprintGenerationError() async {
        // Given: Fingerprint generation fails
        let fileURL = createTempAudioFile()
        let generator = MockFingerprintGenerator()
        generator.shouldFail = true
        generator.errorToThrow = AcoustIDError.fingerprintGenerationFailed("Mock error")
        
        let lookupService = MockAcoustIDLookup()
        
        let service = AcoustIDService(
            fingerprintGenerator: generator,
            lookupService: lookupService
        )
        
        // When/Then: Error is thrown
        do {
            _ = try await service.identifyTrack(fileURL: fileURL)
            XCTFail("Should have thrown an error")
        } catch let error as AcoustIDError {
            XCTAssertEqual(error, .fingerprintGenerationFailed("Mock error"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testIdentifyTrackWithLookupError() async {
        // Given: Lookup fails
        let fileURL = createTempAudioFile()
        let generator = MockFingerprintGenerator()
        generator.mockFingerprint = "AQADtE..."
        
        let lookupService = MockAcoustIDLookup()
        lookupService.shouldFail = true
        lookupService.errorToThrow = AcoustIDError.networkError("Connection timeout")
        
        let service = AcoustIDService(
            fingerprintGenerator: generator,
            lookupService: lookupService
        )
        
        // When/Then: Error is thrown
        do {
            _ = try await service.identifyTrack(fileURL: fileURL)
            XCTFail("Should have thrown an error")
        } catch let error as AcoustIDError {
            XCTAssertEqual(error, .networkError("Connection timeout"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Performance Characteristics
    
    func testIdentifyTrackPerformance() async throws {
        // Given: A valid audio file
        let fileURL = createTempAudioFile()
        let generator = MockFingerprintGenerator()
        generator.mockFingerprint = "AQADtE..."
        
        let lookupService = MockAcoustIDLookup()
        lookupService.mockMatches = [AcoustIDMatch(
            recordingID: "mbid-123",
            title: "Test",
            artist: "Test",
            score: 0.95
        )]
        
        let service = AcoustIDService(
            fingerprintGenerator: generator,
            lookupService: lookupService
        )
        
        // When: Measuring identification time
        let startTime = Date()
        _ = try await service.identifyTrack(fileURL: fileURL)
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Then: Identification completes within reasonable time (< 5s fingerprint + < 2s lookup = < 7s total)
        XCTAssertLessThan(elapsed, 7.0, "Track identification should complete in < 7s")
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
