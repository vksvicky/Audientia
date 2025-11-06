// MockFactories.swift
// Audientia - Test Infrastructure for Mocking
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

import Foundation
@testable import Shared

/// Factory for creating mock data for testing
enum MockFactory {

    // MARK: - Track Mocks

    /// Creates a mock Track with default values
    static func makeTrack(
        id: UUID = UUID(),
        title: String = "Test Track",
        artist: String = "Test Artist",
        album: String = "Test Album",
        duration: TimeInterval = 180.0,
        filePath: String = "/path/to/track.mp3",
        fileSize: Int64 = 5_000_000,
        bitrate: Int = 320,
        sampleRate: Int = 44100,
        trackNumber: Int? = 1,
        year: Int? = 2024,
        discNumber: Int? = 1,
        genre: String? = "Rock",
        rating: Int? = nil
    ) -> Track {
        Track(
            id: id,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            filePath: filePath,
            fileSize: fileSize,
            bitrate: bitrate,
            sampleRate: sampleRate,
            year: year,
            trackNumber: trackNumber,
            discNumber: discNumber,
            genre: genre,
            rating: rating
        )
    }

    /// Creates a minimal Track with only required fields
    static func makeMinimalTrack() -> Track {
        Track(
            id: UUID(),
            title: "Minimal Track",
            artist: "Unknown Artist",
            album: "Unknown Album",
            duration: 0.0,
            filePath: "/path/to/track.mp3",
            fileSize: 0,
            bitrate: 0,
            sampleRate: 0
        )
    }

    /// Creates a Track with Unicode characters
    static func makeUnicodeTrack() -> Track {
        Track(
            id: UUID(),
            title: "テスト曲 🎵",
            artist: "アーティスト",
            album: "アルバム",
            duration: 200.0,
            filePath: "/path/to/テスト.mp3",
            fileSize: 4_000_000,
            bitrate: 256,
            sampleRate: 48000,
            year: 2024,
            trackNumber: 1,
            discNumber: 1,
            genre: "J-Pop"
        )
    }

    /// Creates an array of mock tracks
    static func makeTracks(count: Int) -> [Track] {
        (0..<count).map { index in
            makeTrack(
                title: "Track \(index + 1)",
                trackNumber: index + 1,
                year: nil,
                discNumber: nil,
                genre: nil,
                rating: nil
            )
        }
    }

    // MARK: - Album Mocks

    /// Creates a mock Album with default values
    static func makeAlbum(
        id: UUID = UUID(),
        title: String = "Test Album",
        artist: String = "Test Artist",
        year: Int? = 2024,
        genre: String? = "Rock",
        trackCount: Int = 10,
        totalDuration: TimeInterval = 1800.0
    ) -> Album {
        Album(
            id: id,
            title: title,
            artist: artist,
            year: year,
            genre: genre,
            trackCount: trackCount,
            totalDuration: totalDuration
        )
    }

    /// Creates a mock Album with custom title
    static func makeAlbum(title: String) -> Album {
        makeAlbum(id: UUID(), title: title, artist: "Test Artist", year: 2024, genre: "Rock", trackCount: 10, totalDuration: 1800.0)
    }

    /// Creates a minimal Album
    static func makeMinimalAlbum() -> Album {
        Album(
            id: UUID(),
            title: "Unknown Album",
            artist: "Unknown Artist",
            year: nil,
            genre: nil,
            trackCount: 0,
            totalDuration: 0.0
        )
    }

    // MARK: - Artist Mocks

    /// Creates a mock Artist with default values
    static func makeArtist(
        id: UUID = UUID(),
        name: String = "Test Artist",
        albumCount: Int = 5,
        trackCount: Int = 50
    ) -> Artist {
        Artist(
            id: id,
            name: name,
            albumCount: albumCount,
            trackCount: trackCount
        )
    }

    /// Creates a mock Artist with custom name
    static func makeArtist(name: String) -> Artist {
        makeArtist(id: UUID(), name: name, albumCount: 5, trackCount: 50)
    }

    /// Creates a minimal Artist
    static func makeMinimalArtist() -> Artist {
        Artist(
            id: UUID(),
            name: "Unknown Artist",
            albumCount: 0,
            trackCount: 0
        )
    }

    // MARK: - Playlist Mocks

    /// Creates a mock Playlist with default values
    static func makePlaylist(
        id: UUID = UUID(),
        name: String = "Test Playlist",
        trackCount: Int = 20,
        totalDuration: TimeInterval = 3600.0,
        isSmart: Bool = false
    ) -> Playlist {
        Playlist(
            id: id,
            name: name,
            trackCount: trackCount,
            totalDuration: totalDuration,
            isSmart: isSmart
        )
    }

    /// Creates a mock Playlist with custom name
    static func makePlaylist(name: String) -> Playlist {
        makePlaylist(id: UUID(), name: name, trackCount: 20, totalDuration: 3600.0, isSmart: false)
    }

    /// Creates a minimal Playlist
    static func makeMinimalPlaylist() -> Playlist {
        Playlist(
            id: UUID(),
            name: "New Playlist",
            trackCount: 0,
            totalDuration: 0.0,
            isSmart: false
        )
    }

    /// Creates a smart Playlist
    static func makeSmartPlaylist() -> Playlist {
        Playlist(
            id: UUID(),
            name: "Smart Playlist",
            trackCount: 0,
            totalDuration: 0.0,
            isSmart: true
        )
    }
}
