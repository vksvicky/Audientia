//
//  TrackDetailsViewModelBDDTests.swift
//  AudientiaUITests
//
//  BDD scenarios for Track Details panel
//

import Shared
import XCTest

@testable import Audientia

@MainActor
final class TrackDetailsViewModelBDDTests: XCTestCase {
    var viewModel: TrackDetailsViewModel!
    var metadataProvider: MockTrackMetadataProvider!

    override func setUp() {
        super.setUp()
        metadataProvider = MockTrackMetadataProvider()
        metadataProvider.metadata = TrackMetadata(
            albumArtist: "CycleRun",
            composer: "Composer",
            lyricist: nil,
            bpm: 110,
            musicalKey: "G min",
            comment: "User note",
            playCount: 21,
            lastPlayed: Date().addingTimeInterval(-1800),
            addedDate: Date().addingTimeInterval(-86_400),
            energy: 0.6,
            danceability: 0.7
        )
        viewModel = TrackDetailsViewModel(metadataProvider: metadataProvider)
    }

    override func tearDown() {
        viewModel = nil
        metadataProvider = nil
        super.tearDown()
    }

    func testAsAUserSelectingTrackShowsItsDetails() async {
        // Given: I have a track in my library
        let track = makeTrack(title: "Nebula", artist: "Orbitals")

        // When: I select the track in the UI
        await viewModel.updateSelection(track)

        // Then: I should see its metadata and insights
        XCTAssertEqual(viewModel.summaryRows.first?.value, "Nebula")
        XCTAssertFalse(viewModel.audioRows.isEmpty)
    }

    func testAsAUserClearingSelectionShowsPlaceholder() async {
        // Given: I was viewing a track
        await viewModel.updateSelection(makeTrack())

        // When: I clear the selection
        await viewModel.updateSelection(nil)

        // Then: The view should reset to placeholder state
        XCTAssertNil(viewModel.selectedTrack)
        XCTAssertTrue(viewModel.summaryRows.isEmpty)
    }

    func testAsAUserSeeingErrorWhenMetadataUnavailable() async {
        // Given: Metadata provider is offline
        metadataProvider.error = MockTrackMetadataProviderError.metadataFailed
        let track = makeTrack()

        // When: I select a track
        await viewModel.updateSelection(track)

        // Then: I should see a friendly error surfaced
        XCTAssertNotNil(viewModel.lastError)
        XCTAssertTrue(viewModel.tagRows.isEmpty)
    }

    private func makeTrack(title: String = "Track", artist: String = "Artist") -> Track {
        Track(
            title: title,
            artist: artist,
            album: "Album",
            duration: 200,
            filePath: "/tmp/\(UUID().uuidString).flac",
            fileSize: 5_120_000,
            bitrate: 256,
            sampleRate: 48_000,
            year: 2023,
            trackNumber: 2,
            discNumber: 1,
            genre: "Electronic",
            rating: 5
        )
    }
}
