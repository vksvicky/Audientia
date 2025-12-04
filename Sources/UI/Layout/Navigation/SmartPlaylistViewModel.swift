//
//  SmartPlaylistViewModel.swift
//  Audientia
//
//  ViewModel for Smart Playlist queries
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import DataLayer
import Foundation
@preconcurrency import Shared
import SwiftUI

/// Smart playlist types available in sidebar
public enum SmartPlaylistType: String, CaseIterable, Sendable {
    case recentlyAdded
    case topRated
    case fiveStarTracks
    
    public var displayName: String {
        switch self {
        case .recentlyAdded: return "Recently Added"
        case .topRated: return "Top Rated"
        case .fiveStarTracks: return "5-Star Tracks"
        }
    }
}

/// ViewModel for Smart Playlist queries
/// Manages fetching tracks for smart playlist types
@MainActor
public final class SmartPlaylistViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Tracks for the selected smart playlist type
    @Published public private(set) var tracks: [Track] = []
    
    /// Loading state
    @Published public private(set) var isLoading = false
    
    /// Error state
    @Published public private(set) var error: Error?
    
    // MARK: - Dependencies
    
    private let libraryIndexer: LibraryIndexerProtocol
    
    // MARK: - Initialization
    
    public init(libraryIndexer: LibraryIndexerProtocol) {
        self.libraryIndexer = libraryIndexer
    }
    
    // MARK: - Public Methods
    
    /// Load tracks for a smart playlist type
    /// - Parameter type: The smart playlist type to load
    /// - Parameter limit: Maximum number of tracks to return (default: 100, nil for unlimited)
    public func loadTracks(for type: SmartPlaylistType, limit: Int? = 100) async {
        isLoading = true
        error = nil
        
            let allTracks = await libraryIndexer.getAllTracks()
            let filteredTracks = filterTracks(allTracks, for: type)
            tracks = limit.map { Array(filteredTracks.prefix($0)) } ?? filteredTracks
            isLoading = false
    }
    
    // MARK: - Private Methods
    
    /// Filter tracks based on smart playlist type
    private func filterTracks(_ tracks: [Track], for type: SmartPlaylistType) -> [Track] {
        switch type {
        case .recentlyAdded:
            // NOTE: Track model doesn't have dateAdded yet, so we'll use ID as a proxy
            // In the future, this should sort by actual dateAdded property
            return tracks.sorted { $0.id.uuidString > $1.id.uuidString }
            
        case .topRated:
            // Sort by rating (highest first), then by title for ties
            return tracks
                .filter { $0.rating != nil }
                .sorted { lhs, rhs in
                    if let lhsRating = lhs.rating, let rhsRating = rhs.rating {
                        if lhsRating != rhsRating {
                            return lhsRating > rhsRating
                        }
                    }
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }
            
        case .fiveStarTracks:
            // Filter to only 5-star tracks, sorted by title
            return tracks
                .filter { $0.rating == 5 }
                .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }
}
