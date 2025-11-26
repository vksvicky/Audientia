//
//  PlaybackCoordinatorBDDTests.swift
//  AudientiaUITests
//
//  BDD scenarios for playback coordination
//

import AudioCore
import Foundation
import Shared
import XCTest

@testable import Audientia

@MainActor
final class PlaybackCoordinatorBDDTests: XCTestCase {
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

    func testAsAUserIWantToPlayATrackFromTheLibrary() async throws {
        // Given: I have selected a track in the library
        let track = Track(
            title: "My Favorite Song",
            artist: "My Favorite Artist",
            album: "My Favorite Album",
            duration: 240,
            filePath: "/music/song.mp3",
            fileSize: 4_194_304,
            bitrate: 320,
            sampleRate: 44_100
        )
        trackSelection.select(track)

        // When: I double-click or press play
        try await coordinator.playSelectedTrack()

        // Then: The track should start playing
        XCTAssertEqual(mockAudioEngine.currentTrack?.id, track.id)
        XCTAssertEqual(mockAudioEngine.state, .playing)
    }

    func testAsAUserIWantToQueueATrackFromAPlaylist() async {
        // Given: I have selected a track in a playlist
        let track = Track(
            title: "Playlist Track",
            artist: "Playlist Artist",
            album: "Playlist Album",
            duration: 200,
            filePath: "/music/playlist.mp3",
            fileSize: 3_145_728,
            bitrate: 320,
            sampleRate: 44_100
        )
        trackSelection.select(track)

        // When: I choose "Add to Queue"
        await coordinator.queueSelectedTrack()

        // Then: The track should be added to the queue
        XCTAssertTrue(mockAudioEngine.queue.contains { $0.id == track.id })
    }

    func testAsAUserIWantToQueueMultipleTracksAtOnce() async {
        // Given: I have selected multiple tracks
        let tracks = [
            Track(title: "Song 1", artist: "Artist", album: "Album", duration: 180, filePath: "/1.mp3", fileSize: 100, bitrate: 320, sampleRate: 44100),
            Track(title: "Song 2", artist: "Artist", album: "Album", duration: 200, filePath: "/2.mp3", fileSize: 100, bitrate: 320, sampleRate: 44100),
            Track(title: "Song 3", artist: "Artist", album: "Album", duration: 220, filePath: "/3.mp3", fileSize: 100, bitrate: 320, sampleRate: 44100)
        ]

        // When: I choose "Queue All"
        await coordinator.queueTracks(tracks)

        // Then: All tracks should be in the queue
        XCTAssertEqual(mockAudioEngine.queue.count, 3)
        XCTAssertTrue(mockAudioEngine.queue.contains { $0.title == "Song 1" })
        XCTAssertTrue(mockAudioEngine.queue.contains { $0.title == "Song 2" })
        XCTAssertTrue(mockAudioEngine.queue.contains { $0.title == "Song 3" })
    }
}

