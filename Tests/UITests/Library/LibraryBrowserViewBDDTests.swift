//
//  LibraryBrowserViewBDDTests.swift
//  UITests
//
//  BDD scenarios for LibraryBrowserView
//  Following user-centric "As a user, I want to..." format
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import DataLayer
@testable import Shared
import SwiftUI
@testable import UI
import XCTest

/// BDD-style test scenarios for LibraryBrowserView
/// Following user-centric "As a user, I want to..." format
@MainActor
final class LibraryBrowserViewBDDTests: XCTestCase {
    
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
    
    // MARK: - BDD Scenarios
    
    /// BDD: As a user, I want to see my library tracks in a list view
    func testUserViewsLibraryInListView() async {
        // Given - I have tracks in my library
        let tracks = MockTrackFactory.makeTracks(count: 5)
        try? await mockIndexer.index(tracks: tracks)
        await viewModel.loadTracks()
        viewModel.viewMode = .list
        
        // When - I view my library
        // (ViewModel state is checked directly)
        
        // Then - I should see my tracks in a list
        XCTAssertEqual(viewModel.viewMode, .list, "Should be in list view mode")
        XCTAssertEqual(viewModel.filteredTracks.count, 5, "Should see 5 tracks")
        XCTAssertFalse(viewModel.filteredTracks.isEmpty, "Should have tracks visible")
    }
    
    /// BDD: As a user, I want to switch between list and grid views
    func testUserSwitchesBetweenListAndGridViews() {
        // Given - I am viewing my library in list mode
        viewModel.viewMode = .list
        XCTAssertEqual(viewModel.viewMode, .list, "Should start in list mode")
        
        // When - I switch to grid view
        viewModel.viewMode = .grid
        
        // Then - I should see my tracks in a grid
        XCTAssertEqual(viewModel.viewMode, .grid, "Should be in grid view mode")
        
        // When - I switch back to list view
        viewModel.viewMode = .list
        
        // Then - I should see my tracks in a list again
        XCTAssertEqual(viewModel.viewMode, .list, "Should be back in list view mode")
    }
    
    /// BDD: As a user, I want to search for tracks by title
    func testUserSearchesForTracksByTitle() async {
        // Given - I have tracks in my library
        let tracks = [
            MockTrackFactory.makeTrack(title: "Bohemian Rhapsody", artist: "Queen"),
            MockTrackFactory.makeTrack(title: "Stairway to Heaven", artist: "Led Zeppelin"),
            MockTrackFactory.makeTrack(title: "Hotel California", artist: "Eagles")
        ]
        try? await mockIndexer.index(tracks: tracks)
        await viewModel.loadTracks()
        
        // When - I search for "Bohemian"
        viewModel.searchQuery = "Bohemian"
        try? await Task.sleep(nanoseconds: 100_000_000) // Wait for search
        
        // Then - I should see only matching tracks
        XCTAssertEqual(viewModel.filteredTracks.count, 1, "Should find 1 matching track")
        XCTAssertEqual(viewModel.filteredTracks.first?.title, "Bohemian Rhapsody", "Should find Bohemian Rhapsody")
    }
    
    /// BDD: As a user, I want to search for tracks by artist
    func testUserSearchesForTracksByArtist() async {
        // Given - I have tracks from different artists
        let tracks = [
            MockTrackFactory.makeTrack(title: "Song 1", artist: "Queen"),
            MockTrackFactory.makeTrack(title: "Song 2", artist: "Led Zeppelin"),
            MockTrackFactory.makeTrack(title: "Song 3", artist: "Queen")
        ]
        try? await mockIndexer.index(tracks: tracks)
        await viewModel.loadTracks()
        
        // When - I search for "Queen"
        viewModel.searchQuery = "Queen"
        try? await Task.sleep(nanoseconds: 100_000_000) // Wait for search
        
        // Then - I should see all tracks by Queen
        XCTAssertEqual(viewModel.filteredTracks.count, 2, "Should find 2 tracks by Queen")
        XCTAssertTrue(viewModel.filteredTracks.allSatisfy { $0.artist == "Queen" }, "All results should be by Queen")
    }
    
    /// BDD: As a user, I want to clear my search and see all tracks again
    func testUserClearsSearchToSeeAllTracks() async {
        // Given - I have tracks and have searched
        let tracks = MockTrackFactory.makeTracks(count: 10)
        try? await mockIndexer.index(tracks: tracks)
        await viewModel.loadTracks()
        viewModel.searchQuery = "Track 1"
        try? await Task.sleep(nanoseconds: 100_000_000)
        let filteredCount = viewModel.filteredTracks.count
        
        // When - I clear my search
        viewModel.clearSearch()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then - I should see all my tracks again
        XCTAssertTrue(viewModel.searchQuery.isEmpty, "Search query should be empty")
        XCTAssertEqual(viewModel.filteredTracks.count, 10, "Should see all 10 tracks")
        XCTAssertGreaterThan(viewModel.filteredTracks.count, filteredCount, "Should see more tracks after clearing")
    }
    
    /// BDD: As a user, I want to see a message when my library is empty
    func testUserSeesEmptyLibraryMessage() async {
        // Given - My library is empty
        await viewModel.loadTracks()
        
        // When - I view my library
        
        // Then - I should see an empty state message
        XCTAssertTrue(viewModel.tracks.isEmpty, "Library should be empty")
        XCTAssertTrue(viewModel.filteredTracks.isEmpty, "Filtered tracks should be empty")
        XCTAssertTrue(viewModel.searchQuery.isEmpty, "Search query should be empty")
    }
    
    /// BDD: As a user, I want to see a message when my search has no results
    func testUserSeesNoSearchResultsMessage() async {
        // Given - I have tracks in my library
        let tracks = MockTrackFactory.makeTracks(count: 5)
        try? await mockIndexer.index(tracks: tracks)
        await viewModel.loadTracks()
        
        // When - I search for something that doesn't exist
        viewModel.searchQuery = "NonExistentTrack12345"
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then - I should see no results
        XCTAssertTrue(viewModel.filteredTracks.isEmpty, "Should have no search results")
        XCTAssertFalse(viewModel.searchQuery.isEmpty, "Search query should still be set")
    }
    
    /// BDD: As a user, I want to scan a directory and see progress
    func testUserScansDirectoryAndSeesProgress() async {
        // Given - I want to scan a directory with music files
        let tracks = MockTrackFactory.makeTracks(count: 10)
        mockScanner.mockTracks = tracks
        let directoryURL = URL(fileURLWithPath: "/test/music")
        
        // When - I scan the directory
        let scanTask = Task {
            await viewModel.scanDirectory(directoryURL)
        }
        
        // Wait a bit for scan to start
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        // Then - I should see scanning progress
        // Note: In a real implementation, progress would update during scan
        // For now, we verify the scan completes successfully
        
        // Wait for scan to complete
        await scanTask.value
        
        // Then - I should see my tracks in the library
        XCTAssertFalse(viewModel.isScanning, "Should not be scanning after completion")
        XCTAssertEqual(viewModel.scanProgress, 1.0, accuracy: 0.01, "Progress should be complete")
        XCTAssertEqual(viewModel.tracks.count, 10, "Should have 10 tracks after scan")
    }
    
    /// BDD: As a user, I want to see an error message if scanning fails
    func testUserSeesErrorMessageWhenScanFails() async {
        // Given - Scanning will fail
        mockScanner.shouldFail = true
        let directoryURL = URL(fileURLWithPath: "/test/music")
        
        // When - I try to scan the directory
        await viewModel.scanDirectory(directoryURL)
        
        // Then - I should see an error message
        XCTAssertNotNil(viewModel.lastError, "Should have an error after scan failure")
        XCTAssertFalse(viewModel.isScanning, "Should not be scanning after failure")
        XCTAssertEqual(viewModel.scanProgress, 0.0, accuracy: 0.01, "Progress should be 0 after failure")
    }
    
    /// BDD: As a user, I want to see my tracks update after scanning
    func testUserSeesTracksUpdateAfterScanning() async {
        // Given - I have an empty library
        await viewModel.loadTracks()
        XCTAssertTrue(viewModel.tracks.isEmpty, "Library should be empty initially")
        
        // When - I scan a directory with tracks
        let tracks = MockTrackFactory.makeTracks(count: 5)
        mockScanner.mockTracks = tracks
        let directoryURL = URL(fileURLWithPath: "/test/music")
        await viewModel.scanDirectory(directoryURL)
        
        // Then - I should see the new tracks in my library
        XCTAssertEqual(viewModel.tracks.count, 5, "Should have 5 tracks after scan")
        XCTAssertEqual(viewModel.filteredTracks.count, 5, "Filtered tracks should also have 5 tracks")
    }
    
    /// BDD: As a user, I want to search case-insensitively
    func testUserSearchesCaseInsensitively() async {
        // Given - I have tracks with mixed case
        let tracks = [
            MockTrackFactory.makeTrack(title: "Bohemian Rhapsody", artist: "Queen"),
            MockTrackFactory.makeTrack(title: "STAIRWAY TO HEAVEN", artist: "Led Zeppelin"),
            MockTrackFactory.makeTrack(title: "hotel california", artist: "Eagles")
        ]
        try? await mockIndexer.index(tracks: tracks)
        await viewModel.loadTracks()
        
        // When - I search with different case
        viewModel.searchQuery = "bohemian"
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then - I should find the track regardless of case
        XCTAssertEqual(viewModel.filteredTracks.count, 1, "Should find 1 track")
        XCTAssertEqual(viewModel.filteredTracks.first?.title, "Bohemian Rhapsody", "Should find Bohemian Rhapsody")
        
        // When - I search with uppercase
        viewModel.searchQuery = "STAIRWAY"
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then - I should find the track
        XCTAssertEqual(viewModel.filteredTracks.count, 1, "Should find 1 track")
        XCTAssertEqual(viewModel.filteredTracks.first?.title, "STAIRWAY TO HEAVEN", "Should find STAIRWAY TO HEAVEN")
    }
}
