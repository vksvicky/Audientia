//
//  MockFactories.swift
//  AudioCoreTests
//
//  Mock factory for AudioCore tests
//

import Foundation
@testable import Shared

/// Factory for creating mock data for AudioCore tests
enum MockFactory {
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
    ) -> Shared.Track {
        Shared.Track(
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
    
    /// Creates an array of mock tracks
    static func makeTracks(count: Int) -> [Shared.Track] {
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
}
