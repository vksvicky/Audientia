//
//  MetadataLookupViewModelTests.swift
//  UITests
//
//  TDD tests for MetadataLookupViewModel following Right-BICEP principles
//

@testable import MetadataEngine
@testable import Shared
import SwiftUI
import XCTest

@MainActor
final class MetadataLookupViewModelTests: XCTestCase {
    
    fileprivate var viewModel: MetadataLookupViewModel!
    fileprivate var mockAcoustID: MockAcoustIDService!
    fileprivate var mockMusicBrainz: MockMusicBrainzClient!
    fileprivate var mockDiscogs: MockDiscogsClient!
    
    override func setUp() async throws {
        try await super.setUp()
        mockAcoustID = MockAcoustIDService()
        mockMusicBrainz = MockMusicBrainzClient()
        mockDiscogs = MockDiscogsClient()
        viewModel = MetadataLookupViewModel(
            acoustIDService: mockAcoustID,
            musicBrainzClient: mockMusicBrainz,
            discogsClient: mockDiscogs,
            metadataMerger: MetadataMerger()
        )
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockAcoustID = nil
        mockMusicBrainz = nil
        mockDiscogs = nil
        try await super.tearDown()
    }
    
    private func createTrack(
        title: String = "Test Song",
        artist: String = "Test Artist",
        album: String = "Test Album",
        path: String = "/tmp/test.mp3"
    ) -> Track {
        Track(
            id: UUID(),
            title: title,
            artist: artist,
            album: album,
            duration: 180,
            filePath: path,
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100
        )
    }
    
    // MARK: - Right: Are the results right?
    
    func testPerformLookupPopulatesMatches() async {
        // Given
        let track = createTrack()
        viewModel.loadTrack(track)
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
                score: 0.95
            )
        ]
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
        
        // When
        await viewModel.performLookup()
        
        // Then
        XCTAssertEqual(viewModel.matches.count, 1)
        XCTAssertEqual(viewModel.matches.first?.fields.title, "Bohemian Rhapsody")
        XCTAssertEqual(viewModel.selectedMatchID, viewModel.matches.first?.id)
    }
    
    // MARK: - Boundary Conditions
    
    func testPerformLookupHandlesError() async {
        // Given
        let track = createTrack()
        viewModel.loadTrack(track)
        mockAcoustID.shouldThrow = true
        
        // When
        await viewModel.performLookup()
        
        // Then
        XCTAssertNotNil(viewModel.lastError)
        XCTAssertTrue(viewModel.matches.isEmpty)
    }
    
    // MARK: - Inverse Relationships
    
    func testSelectMatchUpdatesPreview() async {
        // Given
        let track = createTrack()
        viewModel.loadTrack(track)
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
                score: 0.95
            )
        ]
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
        
        await viewModel.performLookup()
        
        // When - Use preferSource strategy to prefer the lookup source over original
        if let match = viewModel.matches.first {
            viewModel.mergeStrategy = .preferSource(match.source)
            viewModel.selectMatch(match.id)
        }
        
        // Then
        XCTAssertEqual(viewModel.mergePreview?.title, "Bohemian Rhapsody")
        XCTAssertEqual(viewModel.mergePreview?.artist, "Queen")
    }
    
    // MARK: - Cross-Check Using Other Means
    
    func testChangingMergeStrategyRecomputesPreview() async {
        // Given
        let track = createTrack()
        viewModel.loadTrack(track)
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
                score: 0.95
            )
        ]
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
        
        await viewModel.performLookup()
        
        // When
        viewModel.mergeStrategy = .mostComplete
        
        // Then
        XCTAssertEqual(viewModel.mergePreview?.album, "A Night at the Opera")
    }
    
    // MARK: - Performance Characteristics
    
    func testPerformLookupPerformance() async {
        // Given
        let track = createTrack()
        viewModel.loadTrack(track)
        mockAcoustID.matches = (1...5).map { index in
            AcoustIDMatch(
                recordingID: "mbid-\(index)",
                title: "Title \(index)",
                artist: "Artist \(index)",
                album: "Album \(index)",
                year: 1970 + index,
                trackNumber: index,
                discNumber: 1,
                genre: "Rock",
                score: 0.9
            )
        }
        mockMusicBrainz.recording = MusicBrainzRecording(
            id: "mbid-1",
            title: "Title 1",
            artist: "Artist 1"
        )
        
        // When
        let start = Date()
        await viewModel.performLookup()
        let elapsed = Date().timeIntervalSince(start)
        
        // Then
        XCTAssertLessThan(elapsed, 1.0, "Lookup should complete quickly")
    }
}

// MARK: - Mocks

private final class MockAcoustIDService: AcoustIDServicing, @unchecked Sendable {
    var matches: [AcoustIDMatch] = []
    var shouldThrow = false
    
    func identifyTrack(fileURL: URL) async throws -> [AcoustIDMatch] {
        if shouldThrow {
            throw AcoustIDError.lookupFailed("Test failure")
        }
        return matches
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
    var releases: [DiscogsRelease] = []
    
    func searchReleases(query: String) async throws -> [DiscogsRelease] {
        releases
    }
    
    func lookupRelease(releaseID: Int) async throws -> DiscogsRelease {
        DiscogsRelease(id: releaseID, title: "", artist: "")
    }
    
    func searchArtists(query: String) async throws -> [DiscogsArtist] {
        []
    }
}
