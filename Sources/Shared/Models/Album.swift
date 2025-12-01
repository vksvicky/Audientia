// Album.swift
// Audientia - Album Model
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

import Foundation
import os.log

/// Represents an album in the library
public struct Album: Codable, Equatable, Hashable, Identifiable {

    // MARK: - Properties

    /// Unique identifier for the album
    public let id: UUID

    /// Album title
    public let title: String

    /// Artist name
    public let artist: String

    /// Release year (optional)
    public let year: Int?

    /// Genre (optional)
    public let genre: String?

    /// Number of tracks in the album
    public let trackCount: Int

    /// Total duration of all tracks in seconds
    public let totalDuration: TimeInterval

    // MARK: - Initialisation

    /// Creates a new Album instance
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - title: Album title
    ///   - artist: Artist name
    ///   - year: Release year (optional)
    ///   - genre: Genre (optional)
    ///   - trackCount: Number of tracks
    ///   - totalDuration: Total duration in seconds
    public init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        year: Int? = nil,
        genre: String? = nil,
        trackCount: Int,
        totalDuration: TimeInterval
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.year = year
        self.genre = genre
        self.trackCount = trackCount
        self.totalDuration = totalDuration

        // Log after initialisation to avoid capturing mutating self
        let albumTitle = title
        let albumArtist = artist
        Logger.shared.debug("Album created: \(albumTitle) by \(albumArtist)")
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Equatable

    public static func == (lhs: Album, rhs: Album) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Codable Customization

extension Album {
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artist
        case year
        case genre
        case trackCount
        case totalDuration
    }
}
