// TestFixtures.swift
// Audientia - Test Fixtures and Sample Data
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

import Foundation
@testable import Shared

/// Test fixtures containing sample data for testing
enum TestFixtures {

    // MARK: - Sample Track Data

    static let sampleTrackJSON = """
    {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "title": "Bohemian Rhapsody",
        "artist": "Queen",
        "album": "A Night at the Opera",
        "duration": 355.0,
        "filePath": "/Music/Queen/A Night at the Opera/01 - Bohemian Rhapsody.mp3",
        "fileSize": 8500000,
        "bitrate": 320,
        "sampleRate": 44100,
        "year": 1975,
        "trackNumber": 1,
        "discNumber": 1,
        "genre": "Rock",
        "rating": 5
    }
    """

    static let sampleTrackMinimalJSON = """
    {
        "id": "550e8400-e29b-41d4-a716-446655440001",
        "title": "Unknown Track",
        "artist": "Unknown Artist",
        "album": "Unknown Album",
        "duration": 0.0,
        "filePath": "/path/to/track.mp3",
        "fileSize": 0,
        "bitrate": 0,
        "sampleRate": 0
    }
    """

    static let sampleTrackUnicodeJSON = """
    {
        "id": "550e8400-e29b-41d4-a716-446655440002",
        "title": "テスト曲 🎵",
        "artist": "アーティスト",
        "album": "アルバム",
        "duration": 200.0,
        "filePath": "/path/to/テスト.mp3",
        "fileSize": 4000000,
        "bitrate": 256,
        "sampleRate": 48000,
        "year": 2024,
        "trackNumber": 1,
        "discNumber": 1,
        "genre": "J-Pop"
    }
    """

    // MARK: - Sample Album Data

    static let sampleAlbumJSON = """
    {
        "id": "660e8400-e29b-41d4-a716-446655440000",
        "title": "A Night at the Opera",
        "artist": "Queen",
        "year": 1975,
        "genre": "Rock",
        "trackCount": 12,
        "totalDuration": 4320.0
    }
    """

    // MARK: - Sample Artist Data

    static let sampleArtistJSON = """
    {
        "id": "770e8400-e29b-41d4-a716-446655440000",
        "name": "Queen",
        "albumCount": 15,
        "trackCount": 180
    }
    """

    // MARK: - Sample Playlist Data

    static let samplePlaylistJSON = """
    {
        "id": "880e8400-e29b-41d4-a716-446655440000",
        "name": "My Favorites",
        "trackCount": 25,
        "totalDuration": 5400.0,
        "isSmart": false
    }
    """

    static let sampleSmartPlaylistJSON = """
    {
        "id": "990e8400-e29b-41d4-a716-446655440000",
        "name": "5-Star Songs",
        "trackCount": 0,
        "totalDuration": 0.0,
        "isSmart": true
    }
    """

    // MARK: - Helper Methods

    /// Decodes a JSON string to a Track
    static func decodeTrack(from json: String) throws -> Track {
        guard let data = json.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Invalid JSON string"
                )
            )
        }
        let decoder = JSONDecoder()
        return try decoder.decode(Track.self, from: data)
    }

    /// Decodes a JSON string to an Album
    static func decodeAlbum(from json: String) throws -> Album {
        guard let data = json.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Invalid JSON string"
                )
            )
        }
        let decoder = JSONDecoder()
        return try decoder.decode(Album.self, from: data)
    }

    /// Decodes a JSON string to an Artist
    static func decodeArtist(from json: String) throws -> Artist {
        guard let data = json.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Invalid JSON string"
                )
            )
        }
        let decoder = JSONDecoder()
        return try decoder.decode(Artist.self, from: data)
    }

    /// Decodes a JSON string to a Playlist
    static func decodePlaylist(from json: String) throws -> Playlist {
        guard let data = json.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Invalid JSON string"
                )
            )
        }
        let decoder = JSONDecoder()
        return try decoder.decode(Playlist.self, from: data)
    }
}
