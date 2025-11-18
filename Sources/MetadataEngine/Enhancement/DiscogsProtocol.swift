//
//  DiscogsProtocol.swift
//  MetadataEngine
//
//  Protocol for Discogs API client
//

import Foundation
@preconcurrency import Shared

/// Protocol for Discogs API client
public protocol DiscogsClientProtocol: Sendable {
    /// Search for releases by query
    /// - Parameter query: Search query (e.g., "Queen A Night at the Opera")
    /// - Returns: Array of matching releases
    /// - Throws: Error if search fails
    func searchReleases(query: String) async throws -> [DiscogsRelease]
    
    /// Lookup a release by Discogs release ID
    /// - Parameter releaseID: The Discogs release ID
    /// - Returns: Release metadata if found
    /// - Throws: Error if lookup fails
    func lookupRelease(releaseID: Int) async throws -> DiscogsRelease
    
    /// Search for artists by query
    /// - Parameter query: Search query (e.g., "Queen")
    /// - Returns: Array of matching artists
    /// - Throws: Error if search fails
    func searchArtists(query: String) async throws -> [DiscogsArtist]
}

/// Represents a Discogs release (album)
public struct DiscogsRelease: Codable, Equatable, Sendable {
    /// Discogs release ID
    public let id: Int
    
    /// Release title
    public let title: String
    
    /// Artist name (primary artist)
    public let artist: String
    
    /// Artist IDs (all artists)
    public let artistIDs: [Int]
    
    /// Release year
    public let year: Int?
    
    /// Release format (LP, CD, etc.)
    public let format: String?
    
    /// Genre tags
    public let genres: [String]
    
    /// Style tags
    public let styles: [String]
    
    /// Track list
    public let tracks: [DiscogsTrack]
    
    /// Label name
    public let label: String?
    
    /// Catalog number
    public let catalogNumber: String?
    
    /// Country
    public let country: String?
    
    public init(
        id: Int,
        title: String,
        artist: String,
        artistIDs: [Int] = [],
        year: Int? = nil,
        format: String? = nil,
        genres: [String] = [],
        styles: [String] = [],
        tracks: [DiscogsTrack] = [],
        label: String? = nil,
        catalogNumber: String? = nil,
        country: String? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.artistIDs = artistIDs
        self.year = year
        self.format = format
        self.genres = genres
        self.styles = styles
        self.tracks = tracks
        self.label = label
        self.catalogNumber = catalogNumber
        self.country = country
    }
}

/// Represents a track on a Discogs release
public struct DiscogsTrack: Codable, Equatable, Sendable {
    /// Track title
    public let title: String
    
    /// Track position (e.g., "A1", "1", "1-1")
    public let position: String?
    
    /// Track duration (e.g., "5:55")
    public let duration: String?
    
    public init(
        title: String,
        position: String? = nil,
        duration: String? = nil
    ) {
        self.title = title
        self.position = position
        self.duration = duration
    }
}

/// Represents a Discogs artist
public struct DiscogsArtist: Codable, Equatable, Sendable {
    /// Discogs artist ID
    public let id: Int
    
    /// Artist name
    public let name: String
    
    /// Profile/description
    public let profile: String?
    
    /// Real name
    public let realName: String?
    
    public init(
        id: Int,
        name: String,
        profile: String? = nil,
        realName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.profile = profile
        self.realName = realName
    }
}

/// Errors that can occur during Discogs API operations
public enum DiscogsError: Error, LocalizedError, Equatable {
    case invalidReleaseID(Int)
    case releaseNotFound(Int)
    case networkError(String)
    case invalidResponse(String)
    case rateLimitExceeded
    case invalidQuery(String)
    case authenticationRequired
    
    public var errorDescription: String? {
        switch self {
        case let .invalidReleaseID(id):
            return "Invalid release ID: \(id)"
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
        case .authenticationRequired:
            return "Authentication required"
        }
    }
}
