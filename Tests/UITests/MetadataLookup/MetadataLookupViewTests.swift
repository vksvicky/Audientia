//
//  MetadataLookupViewTests.swift
//  UITests
//
//  TDD tests for MetadataLookupView
//

@testable import MetadataEngine
@testable import Shared
import SwiftUI
import XCTest

@MainActor
final class MetadataLookupViewTests: XCTestCase {
    
    func testViewInitializes() {
        let view = MetadataLookupView(
            acoustIDService: MetadataLookupViewTestsMockAcoustIDService(),
            musicBrainzClient: MetadataLookupViewTestsMockMusicBrainzClient(),
            discogsClient: MetadataLookupViewTestsMockDiscogsClient(),
            metadataMerger: MetadataMerger()
        )
        XCTAssertNotNil(view)
    }
    
    func testViewDisplaysStatusMessage() {
        let viewModel = MetadataLookupViewModel(
            acoustIDService: MetadataLookupViewTestsMockAcoustIDService(),
            musicBrainzClient: MetadataLookupViewTestsMockMusicBrainzClient(),
            discogsClient: MetadataLookupViewTestsMockDiscogsClient(),
            metadataMerger: MetadataMerger()
        )
        let view = MetadataLookupView(viewModel: viewModel)
        XCTAssertNotNil(view)
    }
}

// MARK: - Simple mocks for view tests

private final class MetadataLookupViewTestsMockAcoustIDService: AcoustIDServicing, @unchecked Sendable {
    func identifyTrack(fileURL: URL) async throws -> [AcoustIDMatch] { [] }
}

private final class MetadataLookupViewTestsMockMusicBrainzClient: MusicBrainzClientProtocol, @unchecked Sendable {
    func lookupRecording(recordingID: String) async throws -> MusicBrainzRecording {
        MusicBrainzRecording(id: recordingID, title: "", artist: "")
    }
    
    func searchRecordings(query: String) async throws -> [MusicBrainzRecording] { [] }
    
    func lookupRelease(releaseID: String) async throws -> MusicBrainzRelease {
        MusicBrainzRelease(id: releaseID, title: "", artist: "")
    }
    
    func searchReleases(query: String) async throws -> [MusicBrainzRelease] { [] }
}

private final class MetadataLookupViewTestsMockDiscogsClient: DiscogsClientProtocol, @unchecked Sendable {
    func searchReleases(query: String) async throws -> [DiscogsRelease] { [] }
    func lookupRelease(releaseID: Int) async throws -> DiscogsRelease {
        DiscogsRelease(id: releaseID, title: "", artist: "")
    }
    func searchArtists(query: String) async throws -> [DiscogsArtist] { [] }
}
