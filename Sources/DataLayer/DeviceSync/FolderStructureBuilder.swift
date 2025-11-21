//
//  FolderStructureBuilder.swift
//  DataLayer
//
//  Builds folder paths based on folder structure configuration
//

import Foundation
import Shared

/// Protocol for building folder paths from tracks
public protocol FolderStructureBuilderProtocol: Sendable {
    func buildPath(for track: Track, structure: FolderStructure) -> String
}

/// Implementation that builds folder paths based on track metadata
public struct FolderStructureBuilder: FolderStructureBuilderProtocol {
    
    public init() {}
    
    public func buildPath(for track: Track, structure: FolderStructure) -> String {
        let sanitizedArtist = sanitize(track.artist.isEmpty ? "Unknown Artist" : track.artist)
        let sanitizedAlbum = sanitize(track.album.isEmpty ? "Unknown Album" : track.album)
        let sanitizedGenre = sanitize(track.genre ?? "Unknown Genre")
        let sanitizedTitle = sanitize(track.title.isEmpty ? "Unknown Track" : track.title)
        
        switch structure {
        case .flat:
            return sanitizedTitle
            
        case .artistAlbum:
            return "\(sanitizedArtist)/\(sanitizedAlbum)/\(sanitizedTitle)"
            
        case .albumArtist:
            return "\(sanitizedAlbum)/\(sanitizedArtist)/\(sanitizedTitle)"
            
        case .genreArtistAlbum:
            return "\(sanitizedGenre)/\(sanitizedArtist)/\(sanitizedAlbum)/\(sanitizedTitle)"
        }
    }
    
    private func sanitize(_ name: String) -> String {
        // Remove invalid characters for file system paths
        let invalidChars = CharacterSet(charactersIn: "/:<>\"|?*\\")
        let sanitized = name.components(separatedBy: invalidChars).joined(separator: "_")
        // Remove leading/trailing spaces and dots (Windows compatibility)
        return sanitized.trimmingCharacters(in: CharacterSet(charactersIn: " ."))
    }
}
