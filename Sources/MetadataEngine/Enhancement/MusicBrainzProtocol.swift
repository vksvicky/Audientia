//
//  MusicBrainzProtocol.swift
//  MetadataEngine
//
//  Protocol for MusicBrainz API client
//

import Foundation
@preconcurrency import Shared

/// Protocol for MusicBrainz API client
public protocol MusicBrainzClientProtocol: Sendable {
    /// Lookup a recording by MusicBrainz recording ID
    /// - Parameter recordingID: The MusicBrainz recording ID (MBID)
    /// - Returns: Recording metadata if found
    /// - Throws: Error if lookup fails
    func lookupRecording(recordingID: String) async throws -> MusicBrainzRecording
    
    /// Search for recordings by query
    /// - Parameter query: Search query (e.g., "artist:Queen title:Bohemian Rhapsody")
    /// - Returns: Array of matching recordings
    /// - Throws: Error if search fails
    func searchRecordings(query: String) async throws -> [MusicBrainzRecording]
    
    /// Lookup a release by MusicBrainz release ID
    /// - Parameter releaseID: The MusicBrainz release ID (MBID)
    /// - Returns: Release metadata if found
    /// - Throws: Error if lookup fails
    func lookupRelease(releaseID: String) async throws -> MusicBrainzRelease
    
    /// Search for releases by query
    /// - Parameter query: Search query (e.g., "artist:Queen release:A Night at the Opera")
    /// - Returns: Array of matching releases
    /// - Throws: Error if search fails
    func searchReleases(query: String) async throws -> [MusicBrainzRelease]
}

/// Represents a MusicBrainz recording
public struct MusicBrainzRecording: Codable, Equatable, Sendable {
    /// MusicBrainz recording ID
    public let id: String
    
    /// Recording title
    public let title: String
    
    /// Artist name (primary artist)
    public let artist: String
    
    /// Artist IDs (all artists)
    public let artistIDs: [String]
    
    /// Release title (if part of a release)
    public let release: String?
    
    /// Release ID (if part of a release)
    public let releaseID: String?
    
    /// Release date (year)
    public let date: Int?
    
    /// Track number on release
    public let trackNumber: Int?
    
    /// Disc number (for multi-disc releases)
    public let discNumber: Int?
    
    /// Genre tags
    public let genres: [String]
    
    /// Duration in milliseconds
    public let duration: Int?
    
    public init(
        id: String,
        title: String,
        artist: String,
        artistIDs: [String] = [],
        release: String? = nil,
        releaseID: String? = nil,
        date: Int? = nil,
        trackNumber: Int? = nil,
        discNumber: Int? = nil,
        genres: [String] = [],
        duration: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.artistIDs = artistIDs
        self.release = release
        self.releaseID = releaseID
        self.date = date
        self.trackNumber = trackNumber
        self.discNumber = discNumber
        self.genres = genres
        self.duration = duration
    }
}

/// Represents a MusicBrainz release (album)
public struct MusicBrainzRelease: Codable, Equatable, Sendable {
    /// MusicBrainz release ID
    public let id: String
    
    /// Release title
    public let title: String
    
    /// Artist name (primary artist)
    public let artist: String
    
    /// Artist IDs (all artists)
    public let artistIDs: [String]
    
    /// Release date (year)
    public let date: Int?
    
    /// Release type (Album, Single, EP, etc.)
    public let type: String?
    
    /// Track count
    public let trackCount: Int?
    
    /// Disc count
    public let discCount: Int?
    
    /// Genre tags
    public let genres: [String]
    
    /// Tracks on this release
    public let tracks: [MusicBrainzRecording]
    
    public init(
        id: String,
        title: String,
        artist: String,
        artistIDs: [String] = [],
        date: Int? = nil,
        type: String? = nil,
        trackCount: Int? = nil,
        discCount: Int? = nil,
        genres: [String] = [],
        tracks: [MusicBrainzRecording] = []
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.artistIDs = artistIDs
        self.date = date
        self.type = type
        self.trackCount = trackCount
        self.discCount = discCount
        self.genres = genres
        self.tracks = tracks
    }
}

/// Errors that can occur during MusicBrainz API operations
public enum MusicBrainzError: Error, LocalizedError, Equatable {
    case invalidRecordingID(String)
    case invalidReleaseID(String)
    case recordingNotFound(String)
    case releaseNotFound(String)
    case networkError(String)
    case invalidResponse(String)
    case rateLimitExceeded
    case invalidQuery(String)
    
    public var errorDescription: String? {
        switch self {
        case let .invalidRecordingID(id):
            return "Invalid recording ID: \(id)"
        case let .invalidReleaseID(id):
            return "Invalid release ID: \(id)"
        case let .recordingNotFound(id):
            return "Recording not found: \(id)"
        case let .releaseNotFound(id):
            return "Release not found: \(id)"
        case let .networkError(reason):
            return "Network error: \(reason)"
        case let .invalidResponse(reason):
            return "Invalid response: \(reason)"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case let .invalidQuery(query):
            return "Invalid query: \(query)"
        }
    }
}
