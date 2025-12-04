//
//  HomeViewModel.swift
//  Audientia
//
//  ViewModel for Home tab content
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@preconcurrency import DataLayer
import Foundation
@preconcurrency import MetadataEngine
@preconcurrency import Shared
import SwiftUI

/// ViewModel for Home tab content
/// Manages recently played tracks, recently added tracks, and other home content
@MainActor
public final class HomeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Recently played tracks (most recent first)
    @Published public private(set) var recentlyPlayedTracks: [Track] = []
    
    /// Recently added tracks (most recent first)
    @Published public private(set) var recentlyAddedTracks: [Track] = []
    
    /// Most played tracks (highest play count first)
    @Published public private(set) var mostPlayedTracks: [Track] = []
    
    /// Favourite tracks (highest rating first, minimum 4 stars)
    @Published public private(set) var favouriteTracks: [Track] = []
    
    /// Loading state
    @Published public private(set) var isLoading = false
    
    /// Error state
    @Published public private(set) var error: Error?
    
    // MARK: - Dependencies
    
    private let listeningHistory: ListeningHistoryProtocol?
    private let libraryIndexer: LibraryIndexerProtocol
    
    // MARK: - Initialization
    
    public init(
        listeningHistory: ListeningHistoryProtocol? = nil,
        libraryIndexer: LibraryIndexerProtocol
    ) {
        self.listeningHistory = listeningHistory
        self.libraryIndexer = libraryIndexer
    }
    
    // MARK: - Public Methods
    
    /// Load recently played tracks
    /// - Parameter limit: Maximum number of tracks to return (default: 10)
    public func loadRecentlyPlayed(limit: Int = 10) async {
        guard let listeningHistory = listeningHistory else {
            recentlyPlayedTracks = []
            return
        }
        
        isLoading = true
        error = nil
        
            // Get recent listening events
            let events = await listeningHistory.getRecentEvents(limit: limit * 2) // Get more to filter skipped
            
            // Filter out skipped tracks and get unique tracks (most recent first)
            var seenTrackIds = Set<UUID>()
            var uniqueEvents: [ListeningEvent] = []
            
            for event in events.reversed() {
                if !event.wasSkipped && !seenTrackIds.contains(event.trackId) {
                    uniqueEvents.append(event)
                    seenTrackIds.insert(event.trackId)
                    
                    if uniqueEvents.count >= limit {
                        break
        }
    }
}
        
        // Map events to tracks (uniqueEvents is already in most recent first order)
            var tracks: [Track] = []
        for event in uniqueEvents {
                if let track = await libraryIndexer.getTrack(by: event.trackId) {
                    tracks.append(track)
                }
            }
            
            recentlyPlayedTracks = tracks
            isLoading = false
    }
    
    /// Load recently added tracks
    /// - Parameter limit: Maximum number of tracks to return (default: 10)
    /// - Note: Currently returns all tracks since Track doesn't have dateAdded property
    ///         This will be enhanced when dateAdded is added to Track model
    public func loadRecentlyAdded(limit: Int = 10) async {
        isLoading = true
        error = nil
        
            // Get all tracks from indexer
            let allTracks = await libraryIndexer.getAllTracks()
            
            // For now, return first N tracks (will be enhanced with dateAdded sorting)
            // NOTE: Sort by dateAdded when Track model includes this property
            recentlyAddedTracks = Array(allTracks.prefix(limit))
            isLoading = false
    }
    
    /// Load most played tracks
    /// - Parameter limit: Maximum number of tracks to return (default: 10)
    public func loadMostPlayed(limit: Int = 10) async {
        guard let listeningHistory = listeningHistory else {
            mostPlayedTracks = []
            return
        }
        
        isLoading = true
        error = nil
        
            // Get all tracks from library
            let allTracks = await libraryIndexer.getAllTracks()
            
            // Get play counts for each track
            var tracksWithCounts: [(track: Track, playCount: Int)] = []
            for track in allTracks {
                let playCount = await listeningHistory.getPlayCount(for: track.id)
                if playCount > 0 { // Only include tracks that have been played
                    tracksWithCounts.append((track: track, playCount: playCount))
                }
            }
            
            // Sort by play count (descending), then by title for ties
            tracksWithCounts.sort { first, second in
                if first.playCount != second.playCount {
                    return first.playCount > second.playCount
                }
                return first.track.title.localizedCaseInsensitiveCompare(second.track.title) == .orderedAscending
            }
            
            // Take top N tracks
            mostPlayedTracks = Array(tracksWithCounts.prefix(limit).map { $0.track })
            isLoading = false
    }
    
    /// Load favourite tracks (rated 4 or 5 stars)
    /// - Parameter limit: Maximum number of tracks to return (default: 10)
    /// - Parameter minRating: Minimum rating to include (default: 4)
    public func loadFavourites(limit: Int = 10, minRating: Int = 4) async {
        isLoading = true
        error = nil
        
            // Get all tracks from library
            let allTracks = await libraryIndexer.getAllTracks()
            
            // Filter tracks with rating >= minRating
            let ratedTracks = allTracks.filter { track in
                guard let rating = track.rating else { return false }
                return rating >= minRating
            }
            
            // Sort by rating (descending), then by title for ties
            let sortedTracks = ratedTracks.sorted { first, second in
                guard let firstRating = first.rating, let secondRating = second.rating else {
                    return false
                }
                if firstRating != secondRating {
                    return firstRating > secondRating
                }
                return first.title.localizedCaseInsensitiveCompare(second.title) == .orderedAscending
            }
            
            // Take top N tracks
            favouriteTracks = Array(sortedTracks.prefix(limit))
            isLoading = false
    }
    
    /// Refresh all home content
    public func refresh() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                await self?.loadRecentlyPlayed()
            }
            group.addTask { [weak self] in
                await self?.loadRecentlyAdded()
            }
            group.addTask { [weak self] in
                await self?.loadMostPlayed()
            }
            group.addTask { [weak self] in
                await self?.loadFavourites()
            }
        }
    }
}
