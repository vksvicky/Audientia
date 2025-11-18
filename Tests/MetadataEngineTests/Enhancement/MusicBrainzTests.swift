//
//  MusicBrainzTests.swift
//  MetadataEngineTests
//
//  TDD tests for MusicBrainz API client
//

import Foundation
import XCTest

@testable import MetadataEngine
@testable import Shared

/// TDD tests for MusicBrainz API client following Right-BICEP principles
// swiftlint:disable type_body_length
final class MusicBrainzTests: XCTestCase {
    
    // MARK: - Right: Are the results right?
    
    func testLookupRecordingByID() async throws {
        // Given: A valid MusicBrainz recording ID
        let recordingID = "mbid-123"
        let client = MockMusicBrainzClient()
        let expectedRecording = MusicBrainzRecording(
            id: recordingID,
            title: "Bohemian Rhapsody",
            artist: "Queen",
            release: "A Night at the Opera",
            releaseID: "mbid-release-123",
            date: 1975,
            trackNumber: 11,
            discNumber: 1,
            genres: ["Rock", "Progressive Rock"],
            duration: 355000
        )
        client.mockRecording = expectedRecording
        
        // When: Looking up the recording
        let recording = try await client.lookupRecording(recordingID: recordingID)
        
        // Then: Correct recording is returned
        XCTAssertEqual(recording.id, recordingID)
        XCTAssertEqual(recording.title, "Bohemian Rhapsody")
        XCTAssertEqual(recording.artist, "Queen")
        XCTAssertEqual(recording.release, "A Night at the Opera")
        XCTAssertEqual(recording.date, 1975)
    }
    
    func testSearchRecordings() async throws {
        // Given: A search query
        let query = "artist:Queen title:Bohemian"
        let client = MockMusicBrainzClient()
        let recording1 = MusicBrainzRecording(
            id: "mbid-123",
            title: "Bohemian Rhapsody",
            artist: "Queen",
            date: 1975
        )
        let recording2 = MusicBrainzRecording(
            id: "mbid-456",
            title: "Bohemian Rhapsody (Live)",
            artist: "Queen",
            date: 1985
        )
        client.mockSearchRecordings = [recording1, recording2]
        
        // When: Searching for recordings
        let recordings = try await client.searchRecordings(query: query)
        
        // Then: Matching recordings are returned
        XCTAssertEqual(recordings.count, 2)
        XCTAssertTrue(recordings.allSatisfy { $0.artist == "Queen" })
        XCTAssertTrue(recordings.allSatisfy { $0.title.contains("Bohemian") })
    }
    
    func testLookupReleaseByID() async throws {
        // Given: A valid MusicBrainz release ID
        let releaseID = "mbid-release-123"
        let client = MockMusicBrainzClient()
        let track1 = MusicBrainzRecording(
            id: "mbid-1",
            title: "Death on Two Legs",
            artist: "Queen",
            trackNumber: 1
        )
        let track2 = MusicBrainzRecording(
            id: "mbid-2",
            title: "Lazing on a Sunday Afternoon",
            artist: "Queen",
            trackNumber: 2
        )
        let expectedRelease = MusicBrainzRelease(
            id: releaseID,
            title: "A Night at the Opera",
            artist: "Queen",
            date: 1975,
            type: "Album",
            trackCount: 12,
            discCount: 1,
            genres: ["Rock"],
            tracks: [track1, track2]
        )
        client.mockRelease = expectedRelease
        
        // When: Looking up the release
        let release = try await client.lookupRelease(releaseID: releaseID)
        
        // Then: Correct release is returned with tracks
        XCTAssertEqual(release.id, releaseID)
        XCTAssertEqual(release.title, "A Night at the Opera")
        XCTAssertEqual(release.artist, "Queen")
        XCTAssertEqual(release.date, 1975)
        XCTAssertEqual(release.tracks.count, 2)
    }
    
    func testSearchReleases() async throws {
        // Given: A search query
        let query = "artist:Queen release:A Night at the Opera"
        let client = MockMusicBrainzClient()
        let release1 = MusicBrainzRelease(
            id: "mbid-release-123",
            title: "A Night at the Opera",
            artist: "Queen",
            date: 1975
        )
        let release2 = MusicBrainzRelease(
            id: "mbid-release-456",
            title: "A Night at the Opera (Remastered)",
            artist: "Queen",
            date: 2011
        )
        client.mockSearchReleases = [release1, release2]
        
        // When: Searching for releases
        let releases = try await client.searchReleases(query: query)
        
        // Then: Matching releases are returned
        XCTAssertEqual(releases.count, 2)
        XCTAssertTrue(releases.allSatisfy { $0.artist == "Queen" })
        XCTAssertTrue(releases.allSatisfy { $0.title.contains("A Night at the Opera") })
    }
    
    // MARK: - Boundary Conditions
    
    func testLookupRecordingWithInvalidID() async {
        // Given: An invalid recording ID
        let recordingID = ""
        let client = MockMusicBrainzClient()
        client.shouldFail = true
        client.errorToThrow = MusicBrainzError.invalidRecordingID(recordingID)
        
        // When/Then: Error is thrown
        do {
            _ = try await client.lookupRecording(recordingID: recordingID)
            XCTFail("Should have thrown an error")
        } catch let error as MusicBrainzError {
            XCTAssertEqual(error, .invalidRecordingID(recordingID))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testLookupRecordingNotFound() async {
        // Given: A non-existent recording ID
        let recordingID = "mbid-nonexistent"
        let client = MockMusicBrainzClient()
        client.shouldFail = true
        client.errorToThrow = MusicBrainzError.recordingNotFound(recordingID)
        
        // When/Then: Error is thrown
        do {
            _ = try await client.lookupRecording(recordingID: recordingID)
            XCTFail("Should have thrown an error")
        } catch let error as MusicBrainzError {
            XCTAssertEqual(error, .recordingNotFound(recordingID))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testSearchRecordingsWithEmptyQuery() async {
        // Given: An empty search query
        let query = ""
        let client = MockMusicBrainzClient()
        client.shouldFail = true
        client.errorToThrow = MusicBrainzError.invalidQuery(query)
        
        // When/Then: Error is thrown
        do {
            _ = try await client.searchRecordings(query: query)
            XCTFail("Should have thrown an error")
        } catch let error as MusicBrainzError {
            XCTAssertEqual(error, .invalidQuery(query))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testSearchRecordingsWithNoResults() async throws {
        // Given: A query with no matches
        let query = "artist:NonexistentArtist title:NonexistentSong"
        let client = MockMusicBrainzClient()
        client.mockSearchRecordings = []
        
        // When: Searching for recordings
        let recordings = try await client.searchRecordings(query: query)
        
        // Then: Empty array is returned
        XCTAssertTrue(recordings.isEmpty)
    }
    
    // MARK: - Inverse Relationships
    
    func testLookupRecordingRoundtrip() async throws {
        // Given: A recording ID
        let recordingID = "mbid-123"
        let client = MockMusicBrainzClient()
        let expectedRecording = MusicBrainzRecording(
            id: recordingID,
            title: "Test Song",
            artist: "Test Artist",
            date: 2020
        )
        client.mockRecording = expectedRecording
        
        // When: Looking up the same recording twice
        let recording1 = try await client.lookupRecording(recordingID: recordingID)
        let recording2 = try await client.lookupRecording(recordingID: recordingID)
        
        // Then: Same result is returned (inverse: consistent results)
        XCTAssertEqual(recording1, recording2)
    }
    
    // MARK: - Cross-Check Using Other Means
    
    func testRecordingMetadataStructure() async throws {
        // Given: A recording with all fields
        let recordingID = "mbid-123"
        let client = MockMusicBrainzClient()
        let expectedRecording = MusicBrainzRecording(
            id: recordingID,
            title: "Test Song",
            artist: "Test Artist",
            artistIDs: ["mbid-artist-1", "mbid-artist-2"],
            release: "Test Album",
            releaseID: "mbid-release-123",
            date: 2020,
            trackNumber: 5,
            discNumber: 1,
            genres: ["Rock", "Pop"],
            duration: 180000
        )
        client.mockRecording = expectedRecording
        
        // When: Looking up the recording
        let recording = try await client.lookupRecording(recordingID: recordingID)
        
        // Then: All fields are correctly populated (cross-check: structure validation)
        XCTAssertEqual(recording.id, recordingID)
        XCTAssertEqual(recording.title, "Test Song")
        XCTAssertEqual(recording.artist, "Test Artist")
        XCTAssertEqual(recording.artistIDs.count, 2)
        XCTAssertEqual(recording.release, "Test Album")
        XCTAssertEqual(recording.releaseID, "mbid-release-123")
        XCTAssertEqual(recording.date, 2020)
        XCTAssertEqual(recording.trackNumber, 5)
        XCTAssertEqual(recording.discNumber, 1)
        XCTAssertEqual(recording.genres.count, 2)
        XCTAssertEqual(recording.duration, 180000)
    }
    
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
            XCTFail("Unexpected error: \(error)")
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
            XCTFail("Unexpected error: \(error)")
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
            XCTFail("Unexpected error: \(error)")
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
