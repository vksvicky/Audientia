// Artist.swift
// Audientia - Artist Model
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

import Foundation
import os

private let artistLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Audientia", category: "ArtistModel")

/// Represents an artist in the library
public struct Artist: Codable, Equatable, Hashable, Identifiable {

    // MARK: - Properties

    /// Unique identifier for the artist
    public let id: UUID

    /// Artist name
    public let name: String

    /// Number of albums by this artist
    public let albumCount: Int

    /// Number of tracks by this artist
    public let trackCount: Int

    // MARK: - Initialisation

    /// Creates a new Artist instance
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - name: Artist name
    ///   - albumCount: Number of albums
    ///   - trackCount: Number of tracks
    public init(
        id: UUID = UUID(),
        name: String,
        albumCount: Int,
        trackCount: Int
    ) {
        self.id = id
        self.name = name
        self.albumCount = albumCount
        self.trackCount = trackCount

        // Log after initialisation to avoid capturing mutating self
        let artistName = name
        artistLogger.debug("Artist created: \(artistName)")
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Equatable

    public static func == (lhs: Artist, rhs: Artist) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Codable Customization

extension Artist {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case albumCount
        case trackCount
    }
}
