//
//  PlaybackCoordinatorTests.swift
//  AudientiaUITests
//
//  TDD tests for PlaybackCoordinator following Right-BICEP
//

import AudioCore
import Foundation
import Shared
import XCTest

@testable import Audientia

@MainActor
final class PlaybackCoordinatorTests: XCTestCase {
    var coordinator: PlaybackCoordinator!
    var mockAudioEngine: MockAudioEngine!
    var trackSelection: TrackSelectionStore!

    override func setUp() {
        super.setUp()
        mockAudioEngine = MockAudioEngine()
        trackSelection = TrackSelectionStore()
        coordinator = PlaybackCoordinator(
            audioEngine: mockAudioEngine,
            trackSelection: trackSelection
        )
    }

    override func tearDown() {
        coordinator = nil
        mockAudioEngine = nil
        trackSelection = nil
        super.tearDown()
    }

    // MARK: - Right Results

    func testPlaySelectedTrack() async throws {
        // Given: A selected track
        let track = makeTrack()
        trackSelection.select(track)

        // When: Playing the selected track
        try await coordinator.playSelectedTrack()

        // Then: Track should be loaded and playing
        XCTAssertEqual(mockAudioEngine.currentTrack?.id, track.id)
        XCTAssertEqual(mockAudioEngine.state, .playing)
    }

    func testQueueSelectedTrack() async throws {
        // Given: A selected track
        let track = makeTrack()
        trackSelection.select(track)

        // When: Queueing the selected track
        await coordinator.queueSelectedTrack()

        // Then: Track should be in queue
        XCTAssertTrue(mockAudioEngine.queue.contains { $0.id == track.id })
    }

    func testQueueMultipleTracks() async {
        // Given: Multiple tracks
        let tracks = [makeTrack(title: "Track 1"), makeTrack(title: "Track 2")]

        // When: Queueing all tracks
        await coordinator.queueTracks(tracks)

        // Then: All tracks should be in queue
        XCTAssertEqual(mockAudioEngine.queue.count, 2)
        XCTAssertTrue(mockAudioEngine.queue.contains { $0.title == "Track 1" })
        XCTAssertTrue(mockAudioEngine.queue.contains { $0.title == "Track 2" })
    }

    // MARK: - Boundary Conditions

    func testPlaySelectedTrackWithNoSelection() async {
        // Given: No track selected
        trackSelection.clear()

        // When: Attempting to play
        // Then: Should throw error
        do {
            try await coordinator.playSelectedTrack()
            XCTFail("Should have thrown error for no selection")
        } catch let error as PlaybackCoordinatorError {
            XCTAssertEqual(error, .noTrackSelected)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testQueueSelectedTrackWithNoSelection() async {
        // Given: No track selected
        trackSelection.clear()

        // When: Queueing
        await coordinator.queueSelectedTrack()

        // Then: Queue should remain empty (no error, just no-op)
        XCTAssertTrue(mockAudioEngine.queue.isEmpty)
    }

    func testQueueEmptyTrackList() async {
        // Given: Empty track list
        let tracks: [Track] = []

        // When: Queueing
        await coordinator.queueTracks(tracks)

        // Then: Queue should remain unchanged
        XCTAssertTrue(mockAudioEngine.queue.isEmpty)
    }

    // MARK: - Inverse Relationships

    func testPlayThenPause() async throws {
        // Given: A playing track
        let track = makeTrack()
        trackSelection.select(track)
        try await coordinator.playSelectedTrack()

        // When: Pausing
        await coordinator.pause()

        // Then: Should be paused
        XCTAssertEqual(mockAudioEngine.state, .paused)
    }

    // MARK: - Cross-Checking

    func testPlaySelectedTrackUpdatesSelection() async throws {
        // Given: A selected track
        let track = makeTrack()
        trackSelection.select(track)

        // When: Playing
        try await coordinator.playSelectedTrack()

        // Then: Selection should remain
        XCTAssertEqual(trackSelection.selectedTrack?.id, track.id)
        XCTAssertEqual(mockAudioEngine.currentTrack?.id, track.id)
    }

    // MARK: - Error Conditions

    func testPlaySelectedTrackWithLoadFailure() async {
        // Given: Audio engine configured to fail loading
        mockAudioEngine.shouldFailLoad = true
        let track = makeTrack()
        trackSelection.select(track)

        // When: Attempting to play
        // Then: Should throw error
        do {
            try await coordinator.playSelectedTrack()
            XCTFail("Should have thrown error for load failure")
        } catch {
            // Expected error
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Performance

    func testQueueManyTracksPerformance() throws {
        // Given: Many tracks
        let tracks = (0..<100).map { makeTrack(title: "Track \($0)") }

        // When: Queueing all tracks
        measure(metrics: [XCTClockMetric()]) {
            let exp = expectation(description: "queue")
            Task {
                await coordinator.queueTracks(tracks)
                exp.fulfill()
            }
            wait(for: [exp], timeout: 2.0)
        }
    }

    // MARK: - Helpers

    private func makeTrack(title: String = "Test Track") -> Track {
        Track(
            title: title,
            artist: "Test Artist",
            album: "Test Album",
            duration: 180,
            filePath: "/tmp/\(title).mp3",
            fileSize: 3_145_728,
            bitrate: 320,
            sampleRate: 44_100
        )
    }
}

