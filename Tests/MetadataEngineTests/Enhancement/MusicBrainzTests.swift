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
}
