//
//  MetadataLookupViewModelBDDTests.swift
//  UITests
//
//  BDD scenarios for MetadataLookupViewModel
//

@testable import MetadataEngine
@testable import Shared
import XCTest

@MainActor
final class MetadataLookupViewModelBDDTests: XCTestCase {
    
    func testUserAutoTagsTrackUsingLookup() async {
        // Scenario: As a user, I want to auto-tag a track using metadata lookup
        
        // Given: I have a track with missing metadata
        let track = createTrackWithMissingMetadata()
        let mockServices = createMockServices()
        let mockAcoustID = mockServices.acoustID
        let mockMusicBrainz = mockServices.musicBrainz
        let mockDiscogs = mockServices.discogs
        
        let viewModel = MetadataLookupViewModel(
            acoustIDService: mockAcoustID,
            musicBrainzClient: mockMusicBrainz,
            discogsClient: mockDiscogs,
            metadataMerger: MetadataMerger()
        )
        viewModel.loadTrack(track)
        
        // When: I perform the lookup
        await viewModel.performLookup()
        
        // And: I set the merge strategy to prefer the lookup source and apply the top match
        if let match = viewModel.matches.first {
            viewModel.mergeStrategy = .preferSource(match.source)
        }
        let mergedTrack = viewModel.applySelectedMatch()
        
        // Then: I see the track auto-tagged with new metadata
        XCTAssertEqual(mergedTrack?.title, "Bohemian Rhapsody")
        XCTAssertEqual(mergedTrack?.artist, "Queen")
        XCTAssertEqual(mergedTrack?.album, "A Night at the Opera")
        XCTAssertEqual(mergedTrack?.year, 1975)
    }
    
    // MARK: - Helper Methods
    
    private func createTrackWithMissingMetadata() -> Track {
        Track(
            title: "Unknown",
            artist: "Unknown Artist",
            album: "Unknown Album",
            duration: 180,
            filePath: "/tmp/unknown.mp3",
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100
        )
    }
    
    private struct MockServices {
        let acoustID: MockAcoustIDService
        let musicBrainz: MockMusicBrainzClient
        let discogs: MockDiscogsClient
    }
    
    private func createMockServices() -> MockServices {
        let mockAcoustID = MockAcoustIDService()
        mockAcoustID.matches = [
            AcoustIDMatch(
                recordingID: "mbid-123",
                title: "Bohemian Rhapsody",
                artist: "Queen",
                album: "A Night at the Opera",
                year: 1975,
                trackNumber: 11,
                discNumber: 1,
                genre: "Rock",
                score: 0.98
            )
        ]
        
        let mockMusicBrainz = MockMusicBrainzClient()
        mockMusicBrainz.recording = MusicBrainzRecording(
            id: "mbid-123",
            title: "Bohemian Rhapsody",
            artist: "Queen",
            release: "A Night at the Opera",
            date: 1975,
            trackNumber: 11,
            discNumber: 1,
            genres: ["Rock"]
        )
        
        let mockDiscogs = MockDiscogsClient()
        
        return MockServices(acoustID: mockAcoustID, musicBrainz: mockMusicBrainz, discogs: mockDiscogs)
    }
    
    func testUserRunsAutoTaggingForMultipleTracks() async {
        // Scenario: As a user, I want to see progress when auto-tagging multiple tracks
        
        // Given: I have two tracks in my library
        let trackA = Track(
            title: "Unknown A",
            artist: "Unknown Artist",
            album: "Unknown Album",
            duration: 180,
            filePath: "/tmp/a.mp3",
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100
        )
        let trackB = Track(
            title: "Unknown B",
            artist: "Unknown Artist",
            album: "Unknown Album",
            duration: 180,
            filePath: "/tmp/b.mp3",
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100
        )
        
        let mockAcoustID = MockAcoustIDService()
        mockAcoustID.matches = [
            AcoustIDMatch(
                recordingID: "mbid-123",
                title: "Bohemian Rhapsody",
                artist: "Queen",
                album: "A Night at the Opera",
                score: 0.95
            )
        ]
        let mockMusicBrainz = MockMusicBrainzClient()
        mockMusicBrainz.recording = MusicBrainzRecording(
            id: "mbid-123",
            title: "Bohemian Rhapsody",
            artist: "Queen"
        )
        let mockDiscogs = MockDiscogsClient()
        
        let viewModel = MetadataLookupViewModel(
            acoustIDService: mockAcoustID,
            musicBrainzClient: mockMusicBrainz,
            discogsClient: mockDiscogs,
            metadataMerger: MetadataMerger()
        )
        
        // When: I auto-tag both tracks
        await viewModel.autoTag(tracks: [trackA, trackB])
        
        // Then: I see progress reach completion
        XCTAssertEqual(viewModel.autoTaggingProgressViewModel.total, 2)
        XCTAssertEqual(viewModel.autoTaggingProgressViewModel.completed, 2)
        XCTAssertFalse(viewModel.autoTaggingProgressViewModel.isRunning)
        XCTAssertEqual(viewModel.autoTaggingProgressViewModel.statusMessage, "Auto-tagging complete")
    }
}

// MARK: - Mocks

private final class MockAcoustIDService: AcoustIDServicing, @unchecked Sendable {
    var matches: [AcoustIDMatch] = []
    
    func identifyTrack(fileURL: URL) async throws -> [AcoustIDMatch] {
        matches
    }
}

private final class MockMusicBrainzClient: MusicBrainzClientProtocol, @unchecked Sendable {
    var recording: MusicBrainzRecording?
    
    func lookupRecording(recordingID: String) async throws -> MusicBrainzRecording {
        recording ?? MusicBrainzRecording(id: recordingID, title: "", artist: "")
    }
    
    func searchRecordings(query: String) async throws -> [MusicBrainzRecording] {
        [recording].compactMap { $0 }
    }
    
    func lookupRelease(releaseID: String) async throws -> MusicBrainzRelease {
        MusicBrainzRelease(id: releaseID, title: "", artist: "")
    }
    
    func searchReleases(query: String) async throws -> [MusicBrainzRelease] {
        []
    }
}

private final class MockDiscogsClient: DiscogsClientProtocol, @unchecked Sendable {
    func searchReleases(query: String) async throws -> [DiscogsRelease] {
        []
    }
    
    func lookupRelease(releaseID: Int) async throws -> DiscogsRelease {
        DiscogsRelease(id: releaseID, title: "", artist: "")
    }
    
    func searchArtists(query: String) async throws -> [DiscogsArtist] {
        []
    }
}
