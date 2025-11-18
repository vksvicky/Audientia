//
//  MetadataMergeProtocol.swift
//  MetadataEngine
//
//  Protocol for metadata merge strategies
//

import Foundation
@preconcurrency import Shared

/// Protocol for metadata merge strategies
public protocol MetadataMergeStrategyProtocol: Sendable {
    /// Merge metadata from multiple sources into a Track
    /// - Parameters:
    ///   - originalTrack: The original track with existing metadata
    ///   - sources: Array of metadata sources to merge
    /// - Returns: Merged Track with combined metadata
    /// - Throws: Error if merge fails
    func merge(originalTrack: Track, sources: [MetadataSource]) throws -> Track
}

/// Represents a metadata source with confidence score
public struct MetadataSource: Equatable, Sendable {
    /// Source type
    public let type: MetadataSourceType
    
    /// Confidence score (0.0 to 1.0)
    public let confidence: Double
    
    /// Metadata fields from this source
    public let metadata: MetadataFields
    
    public init(
        type: MetadataSourceType,
        confidence: Double,
        metadata: MetadataFields
    ) {
        self.type = type
        self.confidence = max(0.0, min(1.0, confidence)) // Clamp to 0.0-1.0
        self.metadata = metadata
    }
}

/// Type of metadata source
public enum MetadataSourceType: String, Equatable, Sendable {
    case acoustID
    case musicBrainz
    case discogs
    case existing // Existing track metadata
}

/// Metadata fields that can be merged
public struct MetadataFields: Equatable, Sendable {
    public let title: String?
    public let artist: String?
    public let album: String?
    public let year: Int?
    public let trackNumber: Int?
    public let discNumber: Int?
    public let genre: String?
    
    public init(
        title: String? = nil,
        artist: String? = nil,
        album: String? = nil,
        year: Int? = nil,
        trackNumber: Int? = nil,
        discNumber: Int? = nil,
        genre: String? = nil
    ) {
        self.title = title
        self.artist = artist
        self.album = album
        self.year = year
        self.trackNumber = trackNumber
        self.discNumber = discNumber
        self.genre = genre
    }
}

/// Merge strategy types
public enum MergeStrategy: Hashable, Sendable {
    /// Prefer existing metadata, only fill missing fields
    case fillMissing
    
    /// Prefer highest confidence source for each field
    case highestConfidence
    
    /// Prefer specific source (e.g., MusicBrainz over Discogs)
    case preferSource(MetadataSourceType)
    
    /// Prefer most complete source (most non-nil fields)
    case mostComplete
    
    /// Prefer existing metadata, only update if new value is more complete
    case conservative
}

/// Errors that can occur during metadata merging
public enum MetadataMergeError: Error, LocalizedError, Equatable {
    case noSources
    case invalidConfidence(Double)
    case mergeFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .noSources:
            return "No metadata sources provided"
        case let .invalidConfidence(confidence):
            return "Invalid confidence score: \(confidence) (must be 0.0-1.0)"
        case let .mergeFailed(reason):
            return "Merge failed: \(reason)"
        }
    }
}
