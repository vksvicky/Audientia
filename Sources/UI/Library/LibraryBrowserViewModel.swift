//
//  LibraryBrowserViewModel.swift
//  Audientia
//
//  ViewModel for the enhanced library browser
//
//  Copyright © 2025 CycleRunCode Club
//

import DataLayer
import os.log
import Shared
import SwiftUI

@MainActor
public final class LibraryBrowserViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published public private(set) var tracks: [Track] = []
    @Published public private(set) var filteredTracks: [Track] = []
    @Published public private(set) var searchText: String = ""
    @Published public private(set) var viewMode: LibraryViewMode = .list
    @Published public private(set) var grouping: LibraryGrouping = .none
    @Published public private(set) var sortOrder: LibrarySortOrder = .title
    @Published public private(set) var sortDirection: LibrarySortDirection = .ascending
    @Published public private(set) var isLoading = false
    @Published public private(set) var lastError: Error?
    @Published public private(set) var hasLoaded = false
    
    // MARK: - Dependencies
    
    private let indexer: LibraryIndexerProtocol
    private let configurationManager: any LibraryViewConfigurationManagerProtocol
    private let searchService: LibrarySearch
    private let artworkExtractor: ArtworkExtractorProtocol
    private let logger = Logger.userInterface
    
    // MARK: - Initialization
    
    @Published public private(set) var artworkCache: [UUID: TrackArtwork] = [:]
    
    public init(
        indexer: LibraryIndexerProtocol = LibraryIndexer(),
        configurationManager: any LibraryViewConfigurationManagerProtocol = LibraryViewConfigurationManager(),
        artworkExtractor: ArtworkExtractorProtocol = HeuristicArtworkExtractor()
    ) {
        self.indexer = indexer
        self.configurationManager = configurationManager
        self.searchService = LibrarySearch(indexer: indexer)
        self.artworkExtractor = artworkExtractor
    }
    
    // MARK: - Public API
    
    public var totalTrackCount: Int {
        tracks.count
    }
    
    public func loadLibraryIfNeeded() async {
        guard hasLoaded == false else { return }
        await loadLibrary()
    }
    
    public func loadLibrary() async {
        isLoading = true
        lastError = nil
        
        let configuration = await configurationManager.loadConfiguration()
        apply(configuration: configuration)
        
        let indexedTracks = await indexer.getAllTracks()
        tracks = sort(tracks: indexedTracks)
        filteredTracks = tracks
        hasLoaded = true
        
        Task {
            await preloadArtworks(for: tracks)
        }
        
        isLoading = false
    }
    
    public func refreshLibrary() async {
        hasLoaded = false
        await loadLibrary()
    }
    
    public func updateSearchText(_ text: String) async {
        searchText = text
        lastError = nil
        
        guard text.isEmpty == false else {
            filteredTracks = tracks
            return
        }
        
        do {
            let results = try await searchService.search(query: text)
            filteredTracks = sort(tracks: results)
        } catch {
            lastError = error
            logger.error("Search failed: \(error.localizedDescription)")
        }
    }
    
    public func setViewMode(_ mode: LibraryViewMode) async {
        guard mode != viewMode else { return }
        viewMode = mode
        await persistConfiguration()
    }
    
    public func setGrouping(_ value: LibraryGrouping) async {
        guard value != grouping else { return }
        grouping = value
        await persistConfiguration()
    }
    
    public func setSortOrder(_ order: LibrarySortOrder, direction: LibrarySortDirection? = nil) async {
        var updated = false
        if order != sortOrder {
            sortOrder = order
            updated = true
        }
        if let direction, direction != sortDirection {
            sortDirection = direction
            updated = true
        }
        guard updated else { return }
        tracks = sort(tracks: tracks)
        filteredTracks = sort(tracks: filteredTracks)
        await persistConfiguration()
    }
    
    public func clearError() {
        lastError = nil
    }
    
    public func artwork(for track: Track) -> TrackArtwork? {
        artworkCache[track.id]
    }
    
    public func loadArtwork(for track: Track) async {
        guard artworkCache[track.id] == nil else { return }
        guard let artwork = await artworkExtractor.extractArtwork(for: track) else { return }
        artworkCache[track.id] = artwork
    }
    
    // MARK: - Helpers
    
    private func apply(configuration: LibraryViewConfiguration) {
        viewMode = configuration.viewMode
        grouping = configuration.grouping
        sortOrder = configuration.sortOrder
        sortDirection = configuration.sortDirection
    }
    
    private func sort(tracks: [Track]) -> [Track] {
        let sorted = tracks.sorted { lhs, rhs in
            switch sortOrder {
            case .title:
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            case .artist:
                return lhs.artist.localizedCaseInsensitiveCompare(rhs.artist) == .orderedAscending
            case .album:
                return lhs.album.localizedCaseInsensitiveCompare(rhs.album) == .orderedAscending
            case .year:
                return compareOptional(lhs.year, rhs.year)
            case .rating:
                return compareOptional(lhs.rating, rhs.rating)
            case .duration:
                return lhs.duration < rhs.duration
            case .dateAdded:
                return lhs.id.uuidString < rhs.id.uuidString
            }
        }
        return sortDirection == .ascending ? sorted : sorted.reversed()
    }
    
    private func compareOptional<T: Comparable>(_ lhs: T?, _ rhs: T?) -> Bool {
        switch (lhs, rhs) {
        case let (leftValue?, rightValue?):
            return leftValue < rightValue
        case (nil, _?):
            return true
        case (_?, nil):
            return false
        default:
            return false
        }
    }
    
    private func persistConfiguration() async {
        let configuration = LibraryViewConfiguration(
            viewMode: viewMode,
            grouping: grouping,
            sortOrder: sortOrder,
            sortDirection: sortDirection,
            visibleColumns: []
        )
        do {
            try await configurationManager.saveConfiguration(configuration)
        } catch {
            lastError = error
            logger.error("Failed to save library configuration: \(error.localizedDescription)")
        }
    }
    
    private func preloadArtworks(for tracks: [Track]) async {
        await withTaskGroup(of: (UUID, TrackArtwork?).self) { group in
            for track in tracks {
                group.addTask { [artworkExtractor] in
                    let artwork = await artworkExtractor.extractArtwork(for: track)
                    return (track.id, artwork)
                }
            }
            
            for await (trackID, artwork) in group {
                if let artwork {
                    artworkCache[trackID] = artwork
                }
            }
        }
    }
}
