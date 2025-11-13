//
//  LibraryViewModel.swift
//  Audientia
//
//  ViewModel for library management
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import os.log
@preconcurrency import Shared

// Note: DataLayer types are used but imported implicitly through module dependencies
// LibraryScanner, LibraryIndexer, and LibrarySearch are public types from DataLayer module

/// ViewModel for the Library view
/// Manages library state, tracks, and user interactions
@MainActor
public final class LibraryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// All tracks in the library
    @Published public private(set) var tracks: [Track] = []
    
    /// Filtered tracks based on search query
    @Published public private(set) var filteredTracks: [Track] = []
    
    /// Current search query
    @Published public var searchQuery: String = "" {
        didSet {
            performSearch()
        }
    }
    
    /// Selected view mode (list or grid)
    @Published public var viewMode: ViewMode = .list
    
    /// Is library currently being scanned
    @Published public private(set) var isScanning: Bool = false
    
    /// Scan progress (0.0 to 1.0)
    @Published public private(set) var scanProgress: Double = 0.0
    
    /// Last error that occurred
    @Published public private(set) var lastError: Error?
    
    // MARK: - Private Properties
    
    private let scanner: any LibraryScannerProtocol
    private let indexer: any LibraryIndexerProtocol
    private let search: LibrarySearch
    
    // MARK: - Initialization
    
    /// Initialize the library view model
    /// - Parameters:
    ///   - scanner: Library scanner instance
    ///   - indexer: Library indexer instance
    ///   - search: Library search instance
    public init(
        scanner: any LibraryScannerProtocol,
        indexer: any LibraryIndexerProtocol,
        search: LibrarySearch
    ) {
        self.scanner = scanner
        self.indexer = indexer
        self.search = search
    }
    
    // MARK: - Public Methods
    
    /// Scan a directory for audio files
    /// - Parameter directoryURL: URL of the directory to scan
    public func scanDirectory(_ directoryURL: URL) async {
        isScanning = true
        scanProgress = 0.0
        lastError = nil
        
        do {
            // Scan directory
            let scannedTracks = try await scanner.scan(directory: directoryURL)
            
            // Index tracks
            try await indexer.index(tracks: scannedTracks)
            
            // Update tracks
            await loadTracks()
            
            isScanning = false
            scanProgress = 1.0
        } catch {
            Logger.shared.error("Failed to scan directory: \(error.localizedDescription)")
            lastError = error
            isScanning = false
            scanProgress = 0.0
        }
    }
    
    /// Load all tracks from the indexer
    public func loadTracks() async {
        let allTracks = await indexer.getAllTracks()
        tracks = allTracks
        filteredTracks = allTracks
    }
    
    /// Perform search with current query
    private func performSearch() {
        guard !searchQuery.isEmpty else {
            filteredTracks = tracks
            return
        }
        
        Task {
            do {
                let results = try await search.search(query: searchQuery, field: .all)
                filteredTracks = results
            } catch {
                Logger.shared.error("Search failed: \(error.localizedDescription)")
                lastError = error
                filteredTracks = tracks
            }
        }
    }
    
    /// Clear search query
    public func clearSearch() {
        searchQuery = ""
    }
    
    // MARK: - View Mode
    
    /// View mode for library display
    public enum ViewMode: String, CaseIterable {
        case list = "List"
        case grid = "Grid"
    }
}
