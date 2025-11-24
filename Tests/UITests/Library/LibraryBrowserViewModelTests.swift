//
//  LibraryBrowserViewModelTests.swift
//  UITests
//
//  TDD tests for the library browser ViewModel
//
//  Copyright © 2025 CycleRunCode Club
//

import Foundation
import XCTest

@testable import Audientia
@testable import Shared

@MainActor
final class LibraryBrowserViewModelTests: XCTestCase {
    var viewModel: LibraryBrowserViewModel!
    var mockIndexer: MockLibraryIndexer!
    var mockConfigurationManager: MockLibraryViewConfigurationManager!
    
    override func setUp() async throws {
        try await super.setUp()
        mockIndexer = MockLibraryIndexer()
        mockConfigurationManager = MockLibraryViewConfigurationManager()
        viewModel = LibraryBrowserViewModel(
            indexer: mockIndexer,
            configurationManager: mockConfigurationManager
        )
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockIndexer = nil
        mockConfigurationManager = nil
        try await super.tearDown()
    }
    
    func testLoadLibraryAppliesConfigurationAndTracks() async {
        await mockIndexer.setTracks(sampleTracks())
        await mockConfigurationManager.setConfiguration(
            LibraryViewConfiguration(
                viewMode: .grid,
                grouping: .artist,
                sortOrder: .artist,
                sortDirection: .descending,
                visibleColumns: []
            )
        )
        
        await viewModel.loadLibrary()
        
        XCTAssertTrue(viewModel.hasLoaded)
        XCTAssertEqual(viewModel.viewMode, .grid)
        XCTAssertEqual(viewModel.grouping, .artist)
        XCTAssertEqual(viewModel.sortOrder, .artist)
        XCTAssertEqual(viewModel.sortDirection, .descending)
        XCTAssertEqual(viewModel.tracks.count, 3)
    }
    
    func testSetViewModePersistsConfiguration() async {
        await viewModel.loadLibrary()
        await viewModel.setViewMode(.grid)
        
        let saved = await mockConfigurationManager.configuration
        XCTAssertEqual(saved.viewMode, .grid)
    }
    
    func testSetSortOrderUpdatesTrackOrder() async {
        await mockIndexer.setTracks(sampleTracks())
        await viewModel.loadLibrary()
        
        await viewModel.setSortOrder(.artist, direction: .ascending)
        
        XCTAssertEqual(viewModel.tracks.first?.artist, "Ambience")
    }
    
    func testSearchFiltersTracks() async {
        await mockIndexer.setTracks(sampleTracks())
        await viewModel.loadLibrary()
        
        await viewModel.updateSearchText("Pulse")
        
        XCTAssertEqual(viewModel.filteredTracks.count, 1)
        XCTAssertEqual(viewModel.filteredTracks.first?.title, "Pulse Runner")
    }
    
    func testRefreshLibraryForcesReload() async {
        await mockIndexer.setTracks([])
        await viewModel.loadLibrary()
        
        await mockIndexer.setTracks(sampleTracks())
        await viewModel.refreshLibrary()
        
        XCTAssertEqual(viewModel.tracks.count, 3)
    }
    
    // MARK: - Helpers
    
    private func sampleTracks() -> [Track] {
        [
            Track(
                title: "Aurora",
                artist: "Ambience",
                album: "Sleep Cycle",
                duration: 210,
                filePath: "/tmp/a.mp3",
                fileSize: 1024,
                bitrate: 320,
                sampleRate: 44100,
                year: 2022,
                genre: "Ambient",
                rating: 4
            ),
            Track(
                title: "Pulse Runner",
                artist: "Neon Division",
                album: "Night Drive",
                duration: 188,
                filePath: "/tmp/b.mp3",
                fileSize: 2048,
                bitrate: 320,
                sampleRate: 48000,
                year: 2024,
                genre: "Synthwave",
                rating: 5
            ),
            Track(
                title: "Orbit",
                artist: "Celeste",
                album: "Gravity",
                duration: 245,
                filePath: "/tmp/c.mp3",
                fileSize: 4096,
                bitrate: 256,
                sampleRate: 44100,
                year: 2020,
                genre: "Electronica",
                rating: 3
            )
        ]
    }
}
