// Track.swift
// Audientia - Track Model
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

import Foundation
import os.log

/// Represents a single audio track in the library
/// - Note: All properties are stored as-is; validation should be done at a higher level
public struct Track: Codable, Equatable, Hashable, Identifiable {

    // MARK: - Properties

    /// Unique identifier for the track
    public let id: UUID

    /// Track title
    public let title: String

    /// Artist name
    public let artist: String

    /// Album name
    public let album: String

    /// Duration in seconds
    public let duration: TimeInterval

    /// File system path to the track file
    public let filePath: String

    /// File size in bytes
    public let fileSize: Int64

    /// Bitrate in kbps
    public let bitrate: Int

    /// Sample rate in Hz
    public let sampleRate: Int

    /// Release year (optional)
    public let year: Int?

    /// Track number on the album (optional)
    public let trackNumber: Int?

    /// Disc number (optional, for multi-disc albums)
    public let discNumber: Int?

    /// Genre (optional)
    public let genre: String?

    /// User rating (1-5, optional)
    public let rating: Int?

    // MARK: - Initialization

    /// Creates a new Track instance
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - title: Track title
    ///   - artist: Artist name
    ///   - album: Album name
    ///   - duration: Duration in seconds
    ///   - filePath: File system path
    ///   - fileSize: File size in bytes
    ///   - bitrate: Bitrate in kbps
    ///   - sampleRate: Sample rate in Hz
    ///   - year: Release year (optional)
    ///   - trackNumber: Track number (optional)
    ///   - discNumber: Disc number (optional)
    ///   - genre: Genre (optional)
    ///   - rating: User rating 1-5 (optional)
    public init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        album: String,
        duration: TimeInterval,
        filePath: String,
        fileSize: Int64,
        bitrate: Int,
        sampleRate: Int,
        year: Int? = nil,
        trackNumber: Int? = nil,
        discNumber: Int? = nil,
        genre: String? = nil,
        rating: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.filePath = filePath
        self.fileSize = fileSize
        self.bitrate = bitrate
        self.sampleRate = sampleRate
        self.year = year
        self.trackNumber = trackNumber
        self.discNumber = discNumber
        self.genre = genre
        self.rating = rating

        // Log after initialization to avoid capturing mutating self
        let trackTitle = title
        let trackArtist = artist
        Logger.shared.debug("Track created: \(trackTitle) by \(trackArtist)")
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Equatable

    public static func == (lhs: Track, rhs: Track) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Codable Customization

extension Track {
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artist
        case album
        case duration
        case filePath
        case fileSize
        case bitrate
        case sampleRate
        case year
        case trackNumber
        case discNumber
        case genre
        case rating
    }
}
