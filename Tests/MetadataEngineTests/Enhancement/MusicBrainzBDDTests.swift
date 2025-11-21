//
//  MusicBrainzBDDTests.swift
//  MetadataEngineTests
//
//  BDD tests for MusicBrainz API client
//

import Foundation
import XCTest

@testable import MetadataEngine
@testable import Shared

/// BDD tests for MusicBrainz API client following user-centric scenarios
final class MusicBrainzBDDTests: XCTestCase {
    
    // MARK: - BDD Scenarios
    
    func testUserWantsToAutoTagAlbumUsingMusicBrainz() async throws {
        // Scenario: As a user, I want to auto-tag an album using MusicBrainz
        
        // Given: I have an album with incomplete metadata
        let releaseID = "mbid-release-123"
        let client = MockMusicBrainzClient()
        
        let track1 = MusicBrainzRecording(
            id: "mbid-1",
            title: "Death on Two Legs",
            artist: "Queen",
            release: "A Night at the Opera",
            releaseID: releaseID,
            date: 1975,
            trackNumber: 1,
            discNumber: 1,
            genres: ["Rock"]
        )
        let track2 = MusicBrainzRecording(
            id: "mbid-2",
            title: "Lazing on a Sunday Afternoon",
            artist: "Queen",
            release: "A Night at the Opera",
            releaseID: releaseID,
            date: 1975,
            trackNumber: 2,
            discNumber: 1,
            genres: ["Rock"]
        )
        
        let release = MusicBrainzRelease(
            id: releaseID,
            title: "A Night at the Opera",
            artist: "Queen",
            date: 1975,
            type: "Album",
            trackCount: 12,
            discCount: 1,
            genres: ["Rock", "Progressive Rock"],
            tracks: [track1, track2]
        )
        client.mockRelease = release
        
        // When: I look up the album by release ID
        let result = try await client.lookupRelease(releaseID: releaseID)
        
        // Then: I see complete metadata for the album and all tracks
        XCTAssertEqual(result.title, "A Night at the Opera")
        XCTAssertEqual(result.artist, "Queen")
        XCTAssertEqual(result.date, 1975)
        XCTAssertEqual(result.type, "Album")
        XCTAssertEqual(result.trackCount, 12)
        XCTAssertEqual(result.genres.count, 2)
        XCTAssertTrue(result.genres.contains("Rock"))
        XCTAssertTrue(result.genres.contains("Progressive Rock"))
        XCTAssertEqual(result.tracks.count, 2)
        XCTAssertEqual(result.tracks[0].title, "Death on Two Legs")
        XCTAssertEqual(result.tracks[1].title, "Lazing on a Sunday Afternoon")
    }
    
    func testUserWantsToSearchForRecordingByTitleAndArtist() async throws {
        // Scenario: As a user, I want to search for a recording by title and artist
        
        // Given: I know the title and artist but not the MusicBrainz ID
        let query = "artist:Queen title:Bohemian Rhapsody"
        let client = MockMusicBrainzClient()
        
        let recording1 = MusicBrainzRecording(
            id: "mbid-123",
            title: "Bohemian Rhapsody",
            artist: "Queen",
            release: "A Night at the Opera",
            date: 1975,
            genres: ["Rock", "Progressive Rock"]
        )
        let recording2 = MusicBrainzRecording(
            id: "mbid-456",
            title: "Bohemian Rhapsody (Live)",
            artist: "Queen",
            release: "Live Killers",
            date: 1979,
            genres: ["Rock"]
        )
        client.mockSearchRecordings = [recording1, recording2]
        
        // When: I search for the recording
        let recordings = try await client.searchRecordings(query: query)
        
        // Then: I see multiple matching recordings sorted by relevance
        XCTAssertEqual(recordings.count, 2)
        XCTAssertTrue(recordings.allSatisfy { $0.artist == "Queen" })
        XCTAssertTrue(recordings.allSatisfy { $0.title.contains("Bohemian Rhapsody") })
        XCTAssertEqual(recordings[0].title, "Bohemian Rhapsody")
        XCTAssertEqual(recordings[0].date, 1975)
    }
    
    func testUserWantsToHandleRecordingNotFound() async {
        // Scenario: As a user, I want to handle cases where a recording is not found
        
        // Given: I have a recording ID that doesn't exist in MusicBrainz
        let recordingID = "mbid-nonexistent"
        let client = MockMusicBrainzClient()
        client.shouldFail = true
        client.errorToThrow = MusicBrainzError.recordingNotFound(recordingID)
        
        // When: I try to look up the recording
        do {
            _ = try await client.lookupRecording(recordingID: recordingID)
            XCTFail("Should have thrown an error")
        } catch let error as MusicBrainzError {
            // Then: I see a clear message that the recording was not found
            XCTAssertEqual(error, .recordingNotFound(recordingID))
            XCTAssertNotNil(error.errorDescription)
        } catch {
            XCTFail("Unexpected error: \(String(describing: error))")
        }
    }
    
    func testUserWantsToHandleNetworkErrorsGracefully() async {
        // Scenario: As a user, I want network errors to be handled gracefully
        
        // Given: I have a network connection issue
        let recordingID = "mbid-123"
        let client = MockMusicBrainzClient()
        client.shouldFail = true
        client.errorToThrow = MusicBrainzError.networkError("Connection timeout")
        
        // When: I try to look up a recording
        do {
            _ = try await client.lookupRecording(recordingID: recordingID)
            XCTFail("Should have thrown an error")
        } catch let error as MusicBrainzError {
            // Then: I see a clear error message about the network issue
            XCTAssertEqual(error, .networkError("Connection timeout"))
            XCTAssertNotNil(error.errorDescription)
        } catch {
            XCTFail("Unexpected error: \(String(describing: error))")
        }
    }
    
    func testUserWantsToHandleRateLimitErrors() async {
        // Scenario: As a user, I want rate limit errors to be handled gracefully
        
        // Given: I have exceeded the API rate limit
        let recordingID = "mbid-123"
        let client = MockMusicBrainzClient()
        client.shouldFail = true
        client.errorToThrow = MusicBrainzError.rateLimitExceeded
        
        // When: I try to look up a recording
        do {
            _ = try await client.lookupRecording(recordingID: recordingID)
            XCTFail("Should have thrown an error")
        } catch let error as MusicBrainzError {
            // Then: I see a clear message about rate limiting
            XCTAssertEqual(error, .rateLimitExceeded)
            XCTAssertNotNil(error.errorDescription)
        } catch {
            XCTFail("Unexpected error: \(String(describing: error))")
        }
    }
    
    func testUserWantsToSeePartialMetadataWhenAvailable() async throws {
        // Scenario: As a user, I want to see partial metadata when full metadata isn't available
        
        // Given: I have a recording with incomplete metadata
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
        
        // When: I look up the recording
        let recording = try await client.lookupRecording(recordingID: recordingID)
        
        // Then: I see the available metadata (title and artist) even though other fields are missing
        XCTAssertEqual(recording.title, "Unknown Track")
        XCTAssertEqual(recording.artist, "Unknown Artist")
        XCTAssertNil(recording.release)
        XCTAssertNil(recording.date)
        XCTAssertTrue(recording.genres.isEmpty)
    }
    
    func testUserWantsToSearchForReleasesByArtistAndTitle() async throws {
        // Scenario: As a user, I want to search for releases (albums) by artist and title
        
        // Given: I know the artist and album title but not the MusicBrainz ID
        let query = "artist:Queen release:A Night at the Opera"
        let client = MockMusicBrainzClient()
        
        let release1 = MusicBrainzRelease(
            id: "mbid-release-123",
            title: "A Night at the Opera",
            artist: "Queen",
            date: 1975,
            type: "Album"
        )
        let release2 = MusicBrainzRelease(
            id: "mbid-release-456",
            title: "A Night at the Opera (Remastered)",
            artist: "Queen",
            date: 2011,
            type: "Album"
        )
        client.mockSearchReleases = [release1, release2]
        
        // When: I search for the release
        let releases = try await client.searchReleases(query: query)
        
        // Then: I see multiple matching releases
        XCTAssertEqual(releases.count, 2)
        XCTAssertTrue(releases.allSatisfy { $0.artist == "Queen" })
        XCTAssertTrue(releases.allSatisfy { $0.title.contains("A Night at the Opera") })
        XCTAssertEqual(releases[0].date, 1975)
        XCTAssertEqual(releases[1].date, 2011)
    }
    
    func testUserWantsToSeeAllTracksOnAnAlbum() async throws {
        // Scenario: As a user, I want to see all tracks on an album
        
        // Given: I have a release ID for an album
        let releaseID = "mbid-release-123"
        let client = MockMusicBrainzClient()
        
        let tracks = (1...12).map { trackNum in
            MusicBrainzRecording(
                id: "mbid-\(String(trackNum))",
                title: "Track \(String(trackNum))",
                artist: "Queen",
                release: "A Night at the Opera",
                releaseID: releaseID,
                date: 1975,
                trackNumber: trackNum,
                discNumber: 1
            )
        }
        
        let release = MusicBrainzRelease(
            id: releaseID,
            title: "A Night at the Opera",
            artist: "Queen",
            date: 1975,
            type: "Album",
            trackCount: 12,
            discCount: 1,
            tracks: tracks
        )
        client.mockRelease = release
        
        // When: I look up the release
        let result = try await client.lookupRelease(releaseID: releaseID)
        
        // Then: I see all 12 tracks with their track numbers
        XCTAssertEqual(result.tracks.count, 12)
        XCTAssertEqual(result.trackCount, 12)
        for (index, track) in result.tracks.enumerated() {
            XCTAssertEqual(track.trackNumber, index + 1)
            XCTAssertEqual(track.artist, "Queen")
            XCTAssertEqual(track.release, "A Night at the Opera")
        }
    }
}
