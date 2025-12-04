//
//  PlaylistSidebarViewModel.swift
//  Audientia
//
//  ViewModel for Playlist sidebar content
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import DataLayer
import Foundation
@preconcurrency import Shared
import SwiftUI

/// ViewModel for Playlist sidebar content
/// Manages playlist list for sidebar display
@MainActor
public final class PlaylistSidebarViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// List of all playlists (sorted by name)
    @Published public private(set) var allPlaylists: [Playlist] = []
    
    /// Filtered list of playlists based on search (sorted by name)
    @Published public private(set) var playlists: [Playlist] = []
    
    /// Current search text
    @Published public private(set) var searchText: String = ""
    
    /// Loading state
    @Published public private(set) var isLoading = false
    
    /// Error state
    @Published public private(set) var error: Error?
    
    // MARK: - Dependencies
    
    private let playlistManager: any PlaylistManagerProtocol
    
    // MARK: - Initialization
    
    public init(playlistManager: any PlaylistManagerProtocol) {
        self.playlistManager = playlistManager
    }
    
    // MARK: - Public Methods
    
    /// Load all playlists
    public func loadPlaylists() async {
        isLoading = true
        error = nil
        
            let loadedPlaylists = await playlistManager.getAllPlaylists()
            // Sort playlists by name
            allPlaylists = loadedPlaylists.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            applySearchFilter()
            isLoading = false
    }
    
    /// Update search text and filter playlists
    /// - Parameter text: Search text to filter by
    public func updateSearchText(_ text: String) async {
        searchText = text
        applySearchFilter()
    }
    
    // MARK: - Private Methods
    
    /// Apply search filter to playlists
    private func applySearchFilter() {
        guard !searchText.isEmpty else {
            playlists = allPlaylists
            return
        }
        
        let normalizedSearch = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        playlists = allPlaylists.filter { playlist in
            playlist.name.lowercased().contains(normalizedSearch)
        }
    }
}
