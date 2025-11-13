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
    /// - Returns: Normalized artist name
    public func normalizeArtist(_ artist: String?) -> String? {
        guard let artist = artist else { return nil }
        return normalizeString(artist)
    }
    
    /// Normalize album name
    /// - Parameter album: Album name to normalize
    /// - Returns: Normalized album name
    public func normalizeAlbum(_ album: String?) -> String? {
        guard let album = album else { return nil }
        return normalizeString(album)
    }
    
    /// Normalize track title
    /// - Parameter title: Track title to normalize
    /// - Returns: Normalized track title
    public func normalizeTitle(_ title: String?) -> String? {
        guard let title = title else { return nil }
        return normalizeString(title)
    }
    
    /// Normalize genre
    /// - Parameter genre: Genre to normalize
    /// - Returns: Normalized genre
    public func normalizeGenre(_ genre: String?) -> String? {
        guard let genre = genre else { return nil }
        return normalizeString(genre)
    }
    
    /// Normalize a metadata string
    /// - Parameter string: String to normalize
    /// - Returns: Normalized string
    private func normalizeString(_ string: String) -> String {
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
        Track(
            id: track.id,
            title: normalizeTitle(track.title) ?? track.title,
            artist: normalizeArtist(track.artist) ?? track.artist,
            album: normalizeAlbum(track.album) ?? track.album,
            duration: track.duration,
            filePath: track.filePath,
            fileSize: track.fileSize,
            bitrate: track.bitrate,
            sampleRate: track.sampleRate,
            year: track.year,
            trackNumber: track.trackNumber,
            discNumber: track.discNumber,
            genre: normalizeGenre(track.genre),
            rating: track.rating
        )
    }
}
