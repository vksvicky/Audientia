// Playlist.swift
// Audientia - Playlist Model
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

import Foundation
import os.log

/// Represents a playlist in the library
/// - Note: Can be either a regular playlist (manually created) or a smart playlist (rule-based)
public struct Playlist: Codable, Equatable, Hashable, Identifiable {

    // MARK: - Properties

    /// Unique identifier for the playlist
    public let id: UUID

    /// Playlist name
    public let name: String

    /// Number of tracks in the playlist
    public let trackCount: Int

    /// Total duration of all tracks in seconds
    public let totalDuration: TimeInterval

    /// Whether this is a smart playlist (rule-based) or regular playlist
    public let isSmart: Bool

    // MARK: - Initialisation

    /// Creates a new Playlist instance
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - name: Playlist name
    ///   - trackCount: Number of tracks
    ///   - totalDuration: Total duration in seconds
    ///   - isSmart: Whether this is a smart playlist
    public init(
        id: UUID = UUID(),
        name: String,
        trackCount: Int,
        totalDuration: TimeInterval,
        isSmart: Bool
    ) {
        self.id = id
        self.name = name
        self.trackCount = trackCount
        self.totalDuration = totalDuration
        self.isSmart = isSmart

        // Log after initialisation to avoid capturing mutating self
        let playlistType = isSmart ? "Smart" : "Regular"
        let playlistName = name
        Logger.shared.debug("\(playlistType) playlist created: \(playlistName)")
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Equatable

    public static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        lhs.id == rhs.id &&
               lhs.isSmart == rhs.isSmart
    }
}

// MARK: - Codable Customization

extension Playlist {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case trackCount
        case totalDuration
        case isSmart
    }
}
