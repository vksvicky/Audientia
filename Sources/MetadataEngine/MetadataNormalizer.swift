//
//  MetadataNormalizer.swift
//  MetadataEngine
//
//  Metadata normalization utilities
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Normalizes metadata values for consistency
public final class MetadataNormalizer: @unchecked Sendable {
    
    /// Initialize the metadata normalizer
    public init() {}
    
    /// Normalize artist name
    /// - Parameter artist: Artist name to normalize
    /// - Returns: Normalized artist name, or nil if empty after normalization
    public func normalizeArtist(_ artist: String?) -> String? {
        guard let artist = artist else { return nil }
        let normalized = normalizeString(artist)
        return normalized.isEmpty ? nil : normalized
    }
    
    /// Normalize album name
    /// - Parameter album: Album name to normalize
    /// - Returns: Normalized album name, or nil if empty after normalization
    public func normalizeAlbum(_ album: String?) -> String? {
        guard let album = album else { return nil }
        let normalized = normalizeString(album)
        return normalized.isEmpty ? nil : normalized
    }
    
    /// Normalize track title
    /// - Parameter title: Track title to normalize
    /// - Returns: Normalized track title, or nil if empty after normalization
    public func normalizeTitle(_ title: String?) -> String? {
        guard let title = title else { return nil }
        let normalized = normalizeString(title)
        return normalized.isEmpty ? nil : normalized
    }
    
    /// Normalize genre
    /// - Parameter genre: Genre to normalize
    /// - Returns: Normalized genre, or nil if empty after normalization
    public func normalizeGenre(_ genre: String?) -> String? {
        guard let genre = genre else { return nil }
        let normalized = normalizeString(genre)
        return normalized.isEmpty ? nil : normalized
    }
    
    /// Normalize a metadata string
    /// - Parameter string: String to normalize
    /// - Returns: Normalized string
    public func normalizeString(_ string: String) -> String {
        // Trim whitespace
        var normalized = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Collapse multiple spaces into single space
        normalized = normalized.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        
        return normalized
    }
    
    /// Normalize a Track's metadata
    /// - Parameter track: Track to normalize
    /// - Returns: Track with normalized metadata
    public func normalizeTrack(_ track: Track) -> Track {
        // Normalize fields - if normalization results in nil (empty string), use nil
        // For required fields (title, artist, album), if original was non-empty but becomes empty
        // after normalization, we still use the normalized value (which will be empty string, not nil,
        // since Track requires non-nil strings). However, if original was empty string, normalization
        // returns nil, and we should use empty string for required fields
        let normalizedTitle = normalizeTitle(track.title)
        let normalizedArtist = normalizeArtist(track.artist)
        let normalizedAlbum = normalizeAlbum(track.album)
        
        return Track(
            id: track.id,
            title: normalizedTitle ?? track.title,
            artist: normalizedArtist ?? track.artist,
            album: normalizedAlbum ?? track.album,
            duration: track.duration,
            filePath: track.filePath,
            fileSize: track.fileSize,
            bitrate: track.bitrate,
            sampleRate: track.sampleRate,
            year: track.year,
            trackNumber: track.trackNumber,
            discNumber: track.discNumber,
            genre: normalizeGenre(track.genre), // Can be nil if empty
            rating: track.rating
        )
    }
}
