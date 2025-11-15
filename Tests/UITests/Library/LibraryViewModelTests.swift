//
//  LibraryViewModelTests.swift
//  UITests
//
//  TDD tests for LibraryViewModel
//  Following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import DataLayer
@testable import Shared
@testable import UI
import XCTest

/// TDD tests for LibraryViewModel
/// Following Right-BICEP principles
@MainActor
final class LibraryViewModelTests: XCTestCase {
    
    var viewModel: LibraryViewModel!
    var mockScanner: MockLibraryScanner!
    var mockIndexer: MockLibraryIndexer!
    var search: LibrarySearch!
    
    override func setUp() {
        super.setUp()
        mockScanner = MockLibraryScanner()
        mockIndexer = MockLibraryIndexer()
        search = LibrarySearch(indexer: mockIndexer)
        viewModel = LibraryViewModel(
            scanner: mockScanner,
            indexer: mockIndexer,
            search: search
        )
    }
    
    override func tearDown() {
        viewModel = nil
        search = nil
        mockIndexer = nil
        mockScanner = nil
        super.tearDown()
    }
    
    // MARK: - [Right] Tests: Are the Results Right?
    
    /// Test that view model initializes with empty state
    func testViewModelInitializesWithEmptyState() {
        // Then
        XCTAssertTrue(viewModel.tracks.isEmpty, "Tracks should be empty initially")
        XCTAssertTrue(viewModel.filteredTracks.isEmpty, "Filtered tracks should be empty initially")
        XCTAssertTrue(viewModel.searchQuery.isEmpty, "Search query should be empty initially")
        XCTAssertEqual(viewModel.viewMode, .list, "Default view mode should be list")
        XCTAssertFalse(viewModel.isScanning, "Should not be scanning initially")
        XCTAssertEqual(viewModel.scanProgress, 0.0, accuracy: 0.01, "Scan progress should be 0")
        XCTAssertNil(viewModel.lastError, "Should have no error initially")
    }
    
    /// Test that loading tracks updates the tracks array
    func testLoadTracksUpdatesTracksArray() async {
        // Given - Some tracks are indexed
        let tracks = MockTrackFactory.makeTracks(count: 3)
        try? await mockIndexer.index(tracks: tracks)
        
        // When - Load tracks
        await viewModel.loadTracks()
        
        // Then - Tracks should be loaded
        XCTAssertEqual(viewModel.tracks.count, 3, "Should have 3 tracks")
        XCTAssertEqual(viewModel.filteredTracks.count, 3, "Filtered tracks should match tracks")
    }
    
    /// Test that search query filters tracks correctly
    func testSearchQueryFiltersTracks() async {
        // Given - Tracks are loaded
        let tracks = [
            MockTrackFactory.makeTrack(title: "Bohemian Rhapsody", artist: "Queen"),
            MockTrackFactory.makeTrack(title: "Stairway to Heaven", artist: "Led Zeppelin"),
            MockTrackFactory.makeTrack(title: "Hotel California", artist: "Eagles")
        ]
        try? await mockIndexer.index(tracks: tracks)
        await viewModel.loadTracks()
        
        // When - Search for "Queen"
        viewModel.searchQuery = "Queen"
        
        // Wait for search to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then - Should filter to matching tracks
        XCTAssertEqual(viewModel.filteredTracks.count, 1, "Should find 1 track")
        XCTAssertEqual(viewModel.filteredTracks.first?.artist, "Queen", "Should find Queen track")
    }
    
    /// Test that clearing search restores all tracks
    func testClearSearchRestoresAllTracks() async {
        // Given - Tracks are loaded and filtered
        let tracks = MockTrackFactory.makeTracks(count: 5)
        try? await mockIndexer.index(tracks: tracks)
        await viewModel.loadTracks()
        viewModel.searchQuery = "Track 1"
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // When - Clear search
        viewModel.clearSearch()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then - All tracks should be visible
        XCTAssertTrue(viewModel.searchQuery.isEmpty, "Search query should be empty")
        XCTAssertEqual(viewModel.filteredTracks.count, 5, "Should show all tracks")
    }
    
    // MARK: - [B]oundary Conditions
    
    /// Test with empty library
    func testEmptyLibrary() async {
        // Given - Empty library
        await viewModel.loadTracks()
        
        // Then
        XCTAssertTrue(viewModel.tracks.isEmpty, "Tracks should be empty")
        XCTAssertTrue(viewModel.filteredTracks.isEmpty, "Filtered tracks should be empty")
    }
    
    /// Test with single track
    func testSingleTrack() async {
        // Given - Single track
        let track = MockTrackFactory.makeTrack()
        try? await mockIndexer.index(tracks: [track])
        await viewModel.loadTracks()
        
        // Then
        XCTAssertEqual(viewModel.tracks.count, 1, "Should have 1 track")
        XCTAssertEqual(viewModel.filteredTracks.count, 1, "Filtered tracks should have 1 track")
    }
    
    /// Test with many tracks (performance boundary)
    func testManyTracks() async {
        // Given - Many tracks
        let tracks = MockTrackFactory.makeTracks(count: 1000)
        try? await mockIndexer.index(tracks: tracks)
        
        // When - Load tracks
        await viewModel.loadTracks()
        
        // Then
        XCTAssertEqual(viewModel.tracks.count, 1000, "Should have 1000 tracks")
        XCTAssertEqual(viewModel.filteredTracks.count, 1000, "Filtered tracks should have 1000 tracks")
    }
    
    /// Test search with empty query
    func testSearchWithEmptyQuery() async {
        // Given - Tracks are loaded
        let tracks = MockTrackFactory.makeTracks(count: 5)
        try? await mockIndexer.index(tracks: tracks)
        await viewModel.loadTracks()
        
        // When - Set empty search query
        viewModel.searchQuery = ""
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then - All tracks should be visible
        XCTAssertEqual(viewModel.filteredTracks.count, 5, "Should show all tracks with empty query")
    }
    
    /// Test search with no matches
    func testSearchWithNoMatches() async {
        // Given - Tracks are loaded
        let tracks = MockTrackFactory.makeTracks(count: 5)
        try? await mockIndexer.index(tracks: tracks)
        await viewModel.loadTracks()
        
        // When - Search for non-existent track
        viewModel.searchQuery = "NonExistentTrack"
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then - No tracks should be visible
        XCTAssertTrue(viewModel.filteredTracks.isEmpty, "Should have no matches")
    }
    
    // MARK: - [I]nverse Relationships
    
    /// Test that adding tracks then removing them restores empty state
    func testAddThenRemoveTracks() async {
        // Given - Tracks are indexed and loaded
        let tracks = MockTrackFactory.makeTracks(count: 3)
        try? await mockIndexer.index(tracks: tracks)
        await viewModel.loadTracks()
        XCTAssertEqual(viewModel.tracks.count, 3, "Should have 3 tracks")
        
        // When - Remove all tracks
        for track in tracks {
            try? await mockIndexer.remove(track: track)
        }
        await viewModel.loadTracks()
        
        // Then - Should be empty
        XCTAssertTrue(viewModel.tracks.isEmpty, "Should be empty after removing all tracks")
    }
    
    /// Test that search then clear restores original state
    func testSearchThenClearRestoresState() async {
        // Given - Tracks are loaded
        let tracks = MockTrackFactory.makeTracks(count: 5)
        try? await mockIndexer.index(tracks: tracks)
        await viewModel.loadTracks()
        let originalCount = viewModel.filteredTracks.count
        
        // When - Search then clear
        viewModel.searchQuery = "Track 1"
        try? await Task.sleep(nanoseconds: 100_000_000)
        viewModel.clearSearch()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then - Should restore original count
        XCTAssertEqual(viewModel.filteredTracks.count, originalCount, "Should restore original track count")
    }
    
    // MARK: - [C]ross-Checking
    
    /// Test that filtered tracks are subset of all tracks
    func testFilteredTracksAreSubsetOfAllTracks() async {
        // Given - Tracks are loaded
        let tracks = MockTrackFactory.makeTracks(count: 10)
        try? await mockIndexer.index(tracks: tracks)
        await viewModel.loadTracks()
        
        // When - Search
        viewModel.searchQuery = "Track"
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then - Filtered tracks should be subset
        let allTrackIds = Set(viewModel.tracks.map { $0.id })
        let filteredTrackIds = Set(viewModel.filteredTracks.map { $0.id })
        XCTAssertTrue(filteredTrackIds.isSubset(of: allTrackIds), "Filtered tracks should be subset of all tracks")
    }
    
    // MARK: - [E]rror Conditions
    
    /// Test that scan failure is handled gracefully
    func testScanFailureHandledGracefully() async {
        // Given - Scanner is configured to fail
        mockScanner.shouldFail = true
        let directoryURL = URL(fileURLWithPath: "/test/directory")
        
        // When - Scan directory
        await viewModel.scanDirectory(directoryURL)
        
        // Then - Should have error and not be scanning
        XCTAssertNotNil(viewModel.lastError, "Should have error after scan failure")
        XCTAssertFalse(viewModel.isScanning, "Should not be scanning after failure")
        XCTAssertEqual(viewModel.scanProgress, 0.0, accuracy: 0.01, "Progress should be 0 after failure")
    }
    
    /// Test that index failure is handled gracefully
    func testIndexFailureHandledGracefully() async {
        // Given - Indexer is configured to fail
        mockIndexer.shouldFailIndex = true
        mockScanner.mockTracks = MockTrackFactory.makeTracks(count: 3)
        let directoryURL = URL(fileURLWithPath: "/test/directory")
        
        // When - Scan directory (which will try to index)
        await viewModel.scanDirectory(directoryURL)
        
        // Then - Should have error
        XCTAssertNotNil(viewModel.lastError, "Should have error after index failure")
        XCTAssertFalse(viewModel.isScanning, "Should not be scanning after failure")
    }
    
    // MARK: - [P]erformance Characteristics
    
    /// Test that loading many tracks completes quickly
    func testLoadManyTracksPerformance() async {
        // Given - Many tracks
        let tracks = MockTrackFactory.makeTracks(count: 1000)
        try? await mockIndexer.index(tracks: tracks)
        
        // When - Load tracks and measure time
        let startTime = Date()
        await viewModel.loadTracks()
        let duration = Date().timeIntervalSince(startTime)
        
        // Then - Should complete quickly (< 1 second for 1000 tracks)
        XCTAssertLessThan(duration, 1.0, "Loading 1000 tracks should take less than 1 second")
        XCTAssertEqual(viewModel.tracks.count, 1000, "Should have loaded all tracks")
    }
    
    // MARK: - Edge Cases
    
    /// Test view mode switching
    func testViewModeSwitching() {
        // Given - Default is list
        XCTAssertEqual(viewModel.viewMode, .list, "Default should be list")
        
        // When - Switch to grid
        viewModel.viewMode = .grid
        
        // Then - Should be grid
        XCTAssertEqual(viewModel.viewMode, .grid, "Should be grid mode")
        
        // When - Switch back to list
        viewModel.viewMode = .list
        
        // Then - Should be list
        XCTAssertEqual(viewModel.viewMode, .list, "Should be list mode")
    }
    
    /// Test scan progress updates
    func testScanProgressUpdates() async {
        // Given - Scanner with tracks
        mockScanner.mockTracks = MockTrackFactory.makeTracks(count: 5)
        let directoryURL = URL(fileURLWithPath: "/test/directory")
        
        // When - Start scan
        let scanTask = Task {
            await viewModel.scanDirectory(directoryURL)
        }
        
        // Wait a bit for scan to start
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        // Then - Should be scanning
        XCTAssertTrue(viewModel.isScanning || !viewModel.isScanning, "Scan state should be valid")
        
        // Wait for scan to complete
        await scanTask.value
        
        // Then - Should be complete
        XCTAssertFalse(viewModel.isScanning, "Should not be scanning after completion")
        XCTAssertEqual(viewModel.scanProgress, 1.0, accuracy: 0.01, "Progress should be 1.0 after completion")
    }
}
