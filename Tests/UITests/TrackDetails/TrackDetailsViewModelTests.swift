//
//  TrackDetailsViewModelTests.swift
//  AudientiaUITests
//
//  TDD coverage for TrackDetailsViewModel following Right-BICEP
//

import Shared
import XCTest

@testable import Audientia

@MainActor
final class TrackDetailsViewModelTests: XCTestCase {
    var viewModel: TrackDetailsViewModel!
    var metadataProvider: MockTrackMetadataProvider!

    override func setUp() {
        super.setUp()
        metadataProvider = MockTrackMetadataProvider()
        metadataProvider.metadata = TrackMetadata(
            albumArtist: "Cycler",
            composer: "Composer",
            lyricist: "Lyricist",
            bpm: 128,
            musicalKey: "C maj",
            comment: "Test",
            playCount: 42,
            lastPlayed: Date(),
            addedDate: Date().addingTimeInterval(-3600),
            energy: 0.75,
            danceability: 0.65
        )
        viewModel = TrackDetailsViewModel(metadataProvider: metadataProvider)
    }

    override func tearDown() {
        viewModel = nil
        metadataProvider = nil
        super.tearDown()
    }

    // MARK: - Right

    func testUpdateSelectionPopulatesRows() async {
        let track = makeTrack(title: "Song A", artist: "Artist A")

        await viewModel.updateSelection(track)

        XCTAssertEqual(viewModel.selectedTrack?.id, track.id)
        XCTAssertFalse(viewModel.summaryRows.isEmpty)
        XCTAssertFalse(viewModel.audioRows.isEmpty)
        XCTAssertFalse(viewModel.fileRows.isEmpty)
    }

    // MARK: - Boundary

    func testHandlesTracksWithoutOptionalMetadata() async {
        let track = Track(
            title: "Minimal",
            artist: "",
            album: "",
            duration: 90,
            filePath: "/tmp/minimal.mp3",
            fileSize: 512_000,
            bitrate: 128,
            sampleRate: 44_100
        )

        await viewModel.updateSelection(track)

        XCTAssertEqual(viewModel.summaryRows.first?.value, "Minimal")
        XCTAssertNil(track.genre)
    }

    // MARK: - Inverse

    func testClearingSelectionResetsState() async {
        await viewModel.updateSelection(makeTrack())
        await viewModel.updateSelection(nil)

        XCTAssertNil(viewModel.selectedTrack)
        XCTAssertTrue(viewModel.summaryRows.isEmpty)
        XCTAssertTrue(viewModel.tagRows.isEmpty)
    }

    // MARK: - Cross-check / Error

    func testMetadataProviderErrorSurfacesLastError() async {
        metadataProvider.error = MockTrackMetadataProviderError.metadataFailed
        let track = makeTrack()

        await viewModel.updateSelection(track)

        XCTAssertNotNil(viewModel.lastError)
        XCTAssertTrue(viewModel.tagRows.isEmpty)
    }

    // MARK: - Performance

    func testUpdateSelectionPerformance() throws {
        let track = makeTrack(title: "Perf", artist: "Bench")

        measure(metrics: [XCTClockMetric()]) {
            let exp = expectation(description: "update")
            Task {
                await viewModel.updateSelection(track)
                exp.fulfill()
            }
            wait(for: [exp], timeout: 1.0)
        }
    }

    // MARK: - Helpers

    private func makeTrack(title: String = "Title", artist: String = "Artist") -> Track {
        Track(
            title: title,
            artist: artist,
            album: "Album",
            duration: 240,
            filePath: "/tmp/\(UUID().uuidString).mp3",
            fileSize: 3_145_728,
            bitrate: 320,
            sampleRate: 44_100,
            year: 2024,
            trackNumber: 1,
            discNumber: 1,
            genre: "Rock",
            rating: 4
        )
    }
}
enum MockTrackMetadataProviderError: Error {
    case metadataFailed
}

final class MockTrackMetadataProvider: TrackMetadataProviding {
    var metadata: TrackMetadata?
    var error: Error?

    func metadata(for track: Track) async throws -> TrackMetadata {
        if let error {
            throw error
        }
        guard let metadata else {
            throw MockTrackMetadataProviderError.metadataFailed
        }
        return metadata
    }
}
