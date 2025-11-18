//
//  AcoustIDProtocol.swift
//  MetadataEngine
//
//  Protocol for AcoustID fingerprinting and lookup services
//

import Foundation
@preconcurrency import Shared

/// Protocol for generating audio fingerprints (Chromaprint)
public protocol FingerprintGeneratorProtocol: Sendable {
    /// Generate a fingerprint for an audio file
    /// - Parameter fileURL: The URL of the audio file
    /// - Returns: The fingerprint string (Chromaprint format)
    /// - Throws: Error if fingerprinting fails
    func generateFingerprint(fileURL: URL) async throws -> String
}

/// Protocol for AcoustID lookup service
public protocol AcoustIDLookupProtocol: Sendable {
    /// Lookup metadata using an AcoustID fingerprint
    /// - Parameter fingerprint: The Chromaprint fingerprint
    /// - Parameter duration: The duration of the track in seconds
    /// - Returns: Array of potential matches with metadata
    /// - Throws: Error if lookup fails
    func lookup(fingerprint: String, duration: TimeInterval) async throws -> [AcoustIDMatch]
}

/// Represents a match from AcoustID lookup
public struct AcoustIDMatch: Codable, Equatable, Sendable {
    /// MusicBrainz recording ID
    public let recordingID: String
    
    /// Track title
    public let title: String
    
    /// Artist name
    public let artist: String
    
    /// Album name (optional)
    public let album: String?
    
    /// Release year (optional)
    public let year: Int?
    
    /// Track number (optional)
    public let trackNumber: Int?
    
    /// Disc number (optional)
    public let discNumber: Int?
    
    /// Genre (optional)
    public let genre: String?
    
    /// Confidence score (0.0 to 1.0)
    public let score: Double
    
    public init(
        recordingID: String,
        title: String,
        artist: String,
        album: String? = nil,
        year: Int? = nil,
        trackNumber: Int? = nil,
        discNumber: Int? = nil,
        genre: String? = nil,
        score: Double
    ) {
        self.recordingID = recordingID
        self.title = title
        self.artist = artist
        self.album = album
        self.year = year
        self.trackNumber = trackNumber
        self.discNumber = discNumber
        self.genre = genre
        self.score = score
    }
}

/// Errors that can occur during fingerprinting or AcoustID lookup
public enum AcoustIDError: Error, LocalizedError, Equatable {
    case fileNotFound(URL)
    case fingerprintGenerationFailed(String)
    case lookupFailed(String)
    case networkError(String)
    case invalidResponse(String)
    case rateLimitExceeded
    case noMatchesFound
    
    public var errorDescription: String? {
        switch self {
        case let .fileNotFound(url):
            return "File not found: \(url.path)"
        case let .fingerprintGenerationFailed(reason):
            return "Fingerprint generation failed: \(reason)"
        case let .lookupFailed(reason):
            return "AcoustID lookup failed: \(reason)"
        case let .networkError(reason):
            return "Network error: \(reason)"
        case let .invalidResponse(reason):
            return "Invalid response: \(reason)"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .noMatchesFound:
            return "No matches found"
        }
    }
}

/// Protocol abstraction for AcoustID services (useful for UI and testing layers)
public protocol AcoustIDServicing: Sendable {
    /// Identify a track by generating a fingerprint for a file URL
    /// - Parameter fileURL: Audio file URL
    /// - Returns: Array of potential matches
    func identifyTrack(fileURL: URL) async throws -> [AcoustIDMatch]
}
