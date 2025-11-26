//
//  LibraryBrowserViewModelBDDTests.swift
//  UITests
//
//  BDD scenarios for the library browser ViewModel
//
//  Copyright © 2025 CycleRunCode Club
//

import Foundation
import XCTest

@testable import Audientia
@testable import Shared

@MainActor
final class LibraryBrowserViewModelBDDTests: XCTestCase {
    var viewModel: LibraryBrowserViewModel!
    var mockIndexer: MockLibraryIndexer!
    var mockConfigurationManager: MockLibraryViewConfigurationManager!
    var mockArtworkExtractor: MockArtworkExtractor!
    
    override func setUp() async throws {
        try await super.setUp()
        mockIndexer = MockLibraryIndexer()
        mockConfigurationManager = MockLibraryViewConfigurationManager()
        mockArtworkExtractor = MockArtworkExtractor()
        viewModel = LibraryBrowserViewModel(
            indexer: mockIndexer,
            configurationManager: mockConfigurationManager,
            artworkExtractor: mockArtworkExtractor
        )
        await mockIndexer.setTracks(sampleTracks())
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockIndexer = nil
        mockConfigurationManager = nil
        mockArtworkExtractor = nil
        try await super.tearDown()
    }
    
    func testAsAUserIWantToBrowseMyLibrary() async {
        // Given: I have indexed tracks
        // When: I open the library browser
        await viewModel.loadLibrary()
        
        // Then: I should see my tracks listed
        XCTAssertEqual(viewModel.filteredTracks.count, 3)
    }
    
    func testAsAUserIWantToSearchForTracks() async {
        await viewModel.loadLibrary()
        
        // When: I search for a title
        await viewModel.updateSearchText("Pulse")
        
        // Then: Only matching tracks should appear
        XCTAssertEqual(viewModel.filteredTracks.count, 1)
        XCTAssertEqual(viewModel.filteredTracks.first?.title, "Pulse Runner")
    }
    
    func testAsAUserIWantToSwitchViewModes() async {
        await viewModel.loadLibrary()
        
        // When: I switch to grid view
        await viewModel.setViewMode(.grid)
        
        // Then: The view mode should update and persist
        XCTAssertEqual(viewModel.viewMode, .grid)
        let saved = await mockConfigurationManager.configuration
        XCTAssertEqual(saved.viewMode, .grid)
    }
    
    func testAsAUserISeeAlbumArtworkWhenAvailable() async {
        guard let track = sampleTracks().first else {
            XCTFail("Sample tracks should not be empty")
            return
        }
        await mockArtworkExtractor.setArtworkToReturn(
            TrackArtwork(
                data: Data([0x00, 0x01]),
                mimeType: "image/png",
                source: .sidecar(url: URL(fileURLWithPath: "/tmp/cover.png"))
            )
        )
        
        await viewModel.loadArtwork(for: track)
        
        XCTAssertNotNil(viewModel.artwork(for: track))
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
                year: 2022
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
                year: 2024
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
                year: 2020
            )
        ]
    }
}
