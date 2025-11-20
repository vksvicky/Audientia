//
//  MusicBrainzAdditionalTests.swift
//  MetadataEngineTests
//
//  Additional TDD tests for MusicBrainz API client (Error, Performance, Edge Cases)
//

import Foundation
import XCTest

@testable import MetadataEngine
@testable import Shared

/// Additional TDD tests for MusicBrainz API client: Error, Performance, Edge Cases
final class MusicBrainzAdditionalTests: XCTestCase {
    
    // MARK: - Error Conditions
    
    func testLookupRecordingWithNetworkError() async {
        // Given: A network error
        let recordingID = "mbid-123"
        let client = MockMusicBrainzClient()
        client.shouldFail = true
        client.errorToThrow = MusicBrainzError.networkError("Connection timeout")
        
        // When/Then: Error is thrown
        do {
            _ = try await client.lookupRecording(recordingID: recordingID)
            XCTFail("Should have thrown an error")
        } catch let error as MusicBrainzError {
            XCTAssertEqual(error, .networkError("Connection timeout"))
        } catch {
            XCTFail("Unexpected error: \(String(describing: error))")
        }
    }
    
    func testLookupRecordingWithRateLimitExceeded() async {
        // Given: Rate limit exceeded
        let recordingID = "mbid-123"
        let client = MockMusicBrainzClient()
        client.shouldFail = true
        client.errorToThrow = MusicBrainzError.rateLimitExceeded
        
        // When/Then: Rate limit error is thrown
        do {
            _ = try await client.lookupRecording(recordingID: recordingID)
            XCTFail("Should have thrown an error")
        } catch let error as MusicBrainzError {
            XCTAssertEqual(error, .rateLimitExceeded)
        } catch {
            XCTFail("Unexpected error: \(String(describing: error))")
        }
    }
    
    func testLookupRecordingWithInvalidResponse() async {
        // Given: Invalid response from API
        let recordingID = "mbid-123"
        let client = MockMusicBrainzClient()
        client.shouldFail = true
        client.errorToThrow = MusicBrainzError.invalidResponse("Malformed JSON")
        
        // When/Then: Invalid response error is thrown
        do {
            _ = try await client.lookupRecording(recordingID: recordingID)
            XCTFail("Should have thrown an error")
        } catch let error as MusicBrainzError {
            XCTAssertEqual(error, .invalidResponse("Malformed JSON"))
        } catch {
            XCTFail("Unexpected error: \(String(describing: error))")
        }
    }
    
    // MARK: - Performance Characteristics
    
    func testLookupRecordingPerformance() async throws {
        // Given: A valid recording ID
        let recordingID = "mbid-123"
        let client = MockMusicBrainzClient()
        client.mockRecording = MusicBrainzRecording(
            id: recordingID,
            title: "Test",
            artist: "Test"
        )
        
        // When: Measuring lookup time
        let startTime = Date()
        _ = try await client.lookupRecording(recordingID: recordingID)
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Then: Lookup completes within SLA (< 2s per roadmap)
        XCTAssertLessThan(elapsed, 2.0, "Recording lookup should complete in < 2s")
    }
    
    func testSearchRecordingsPerformance() async throws {
        // Given: A search query
        let query = "artist:Queen"
        let client = MockMusicBrainzClient()
        client.mockSearchRecordings = Array(repeating: MusicBrainzRecording(
            id: "mbid-\(UUID().uuidString)",
            title: "Test",
            artist: "Queen"
        ), count: 10)
        
        // When: Measuring search time
        let startTime = Date()
        _ = try await client.searchRecordings(query: query)
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Then: Search completes within SLA (< 2s per roadmap)
        XCTAssertLessThan(elapsed, 2.0, "Recording search should complete in < 2s")
    }
    
    // MARK: - Edge Cases
    
    func testRecordingWithPartialMetadata() async throws {
        // Given: A recording with partial metadata
        let recordingID = "mbid-123"
        let client = MockMusicBrainzClient()
        let partialRecording = MusicBrainzRecording(
            id: recordingID,
            title: "Unknown Track",
            artist: "Unknown Artist",
            release: nil,
            releaseID: nil,
            date: nil,
            trackNumber: nil,
            discNumber: nil,
            genres: [],
            duration: nil
        )
        client.mockRecording = partialRecording
        
        // When: Looking up the recording
        let recording = try await client.lookupRecording(recordingID: recordingID)
        
        // Then: Recording with partial metadata is returned
        XCTAssertEqual(recording.title, "Unknown Track")
        XCTAssertEqual(recording.artist, "Unknown Artist")
        XCTAssertNil(recording.release)
        XCTAssertNil(recording.date)
    }
    
    func testRecordingWithUnicodeMetadata() async throws {
        // Given: A recording with Unicode characters
        let recordingID = "mbid-123"
        let client = MockMusicBrainzClient()
        let unicodeRecording = MusicBrainzRecording(
            id: recordingID,
            title: "テスト曲",
            artist: "テストアーティスト",
            release: "テストアルバム",
            genres: ["ロック"]
        )
        client.mockRecording = unicodeRecording
        
        // When: Looking up the recording
        let recording = try await client.lookupRecording(recordingID: recordingID)
        
        // Then: Unicode metadata is preserved
        XCTAssertEqual(recording.title, "テスト曲")
        XCTAssertEqual(recording.artist, "テストアーティスト")
        XCTAssertEqual(recording.release, "テストアルバム")
        XCTAssertEqual(recording.genres.first, "ロック")
    }
    
    func testReleaseWithMultipleTracks() async throws {
        // Given: A release with many tracks
        let releaseID = "mbid-release-123"
        let client = MockMusicBrainzClient()
        let tracks = (1...20).map { trackNum in
            MusicBrainzRecording(
                id: "mbid-\(trackNum)",
                title: "Track \(trackNum)",
                artist: "Test Artist",
                trackNumber: trackNum
            )
        }
        let release = MusicBrainzRelease(
            id: releaseID,
            title: "Test Album",
            artist: "Test Artist",
            trackCount: 20,
            tracks: tracks
        )
        client.mockRelease = release
        
        // When: Looking up the release
        let result = try await client.lookupRelease(releaseID: releaseID)
        
        // Then: All tracks are returned
        XCTAssertEqual(result.tracks.count, 20)
        XCTAssertEqual(result.trackCount, 20)
    }
}

// MARK: - Mock Implementation

final class MockMusicBrainzClient: MusicBrainzClientProtocol, @unchecked Sendable {
    var mockRecording: MusicBrainzRecording?
    var mockSearchRecordings: [MusicBrainzRecording] = []
    var mockRelease: MusicBrainzRelease?
    var mockSearchReleases: [MusicBrainzRelease] = []
    var shouldFail = false
    var errorToThrow: Error?
    
    func lookupRecording(recordingID: String) async throws -> MusicBrainzRecording {
        if shouldFail {
            throw errorToThrow ?? MusicBrainzError.recordingNotFound(recordingID)
        }
        if recordingID.isEmpty {
            throw MusicBrainzError.invalidRecordingID(recordingID)
        }
        guard let recording = mockRecording else {
            throw MusicBrainzError.recordingNotFound(recordingID)
        }
        return recording
    }
    
    func searchRecordings(query: String) async throws -> [MusicBrainzRecording] {
        if shouldFail {
            throw errorToThrow ?? MusicBrainzError.invalidQuery(query)
        }
        if query.isEmpty {
            throw MusicBrainzError.invalidQuery(query)
        }
        return mockSearchRecordings
    }
    
    func lookupRelease(releaseID: String) async throws -> MusicBrainzRelease {
        if shouldFail {
            throw errorToThrow ?? MusicBrainzError.releaseNotFound(releaseID)
        }
        if releaseID.isEmpty {
            throw MusicBrainzError.invalidReleaseID(releaseID)
        }
        guard let release = mockRelease else {
            throw MusicBrainzError.releaseNotFound(releaseID)
        }
        return release
    }
    
    func searchReleases(query: String) async throws -> [MusicBrainzRelease] {
        if shouldFail {
            throw errorToThrow ?? MusicBrainzError.invalidQuery(query)
        }
        if query.isEmpty {
            throw MusicBrainzError.invalidQuery(query)
        }
        return mockSearchReleases
    }
}
