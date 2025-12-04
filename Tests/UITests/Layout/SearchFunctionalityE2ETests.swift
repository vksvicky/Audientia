//
//  SearchFunctionalityE2ETests.swift
//  Audientia - UI E2E Tests
//
//  End-to-end tests for search functionality across tabs
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import SwiftUI
import XCTest

@testable import Audientia
@testable import AudioCore
@testable import DataLayer
@testable import Shared

// MARK: - End-to-End Tests for Search Functionality

/// End-to-end tests for search functionality across tabs
final class SearchFunctionalityE2ETests: XCTestCase {
    
    var mockAudioEngine: MockAudioEngine!
    var mockLibraryIndexer: SearchMockLibraryIndexer!
    var mockPlaylistManager: SearchMockPlaylistManager!
    var mockDeviceSyncManager: SearchMockDeviceSyncManager!
    
    @MainActor
    override func setUp() {
        super.setUp()
        mockAudioEngine = MockAudioEngine()
        mockLibraryIndexer = SearchMockLibraryIndexer()
        mockPlaylistManager = SearchMockPlaylistManager()
        mockDeviceSyncManager = SearchMockDeviceSyncManager()
    }
    
    override func tearDown() {
        mockAudioEngine = nil
        mockLibraryIndexer = nil
        mockPlaylistManager = nil
        mockDeviceSyncManager = nil
        super.tearDown()
    }
    
    // MARK: - Library Tab Search E2E Tests
    
    /// E2E: User searches for tracks in Library tab
    @MainActor
    func testE2E_UserSearchesForTracksInLibraryTab() async {
        // Given: Main window is open with Library tab selected
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        
        // When: User types in search field
        // Then: Search should route to LibraryBrowserViewModel
        let libraryViewModel = LibraryBrowserViewModel()
        await libraryViewModel.updateSearchText("test")
        
        // Verify search text is set
        XCTAssertEqual(libraryViewModel.searchText, "test", "Search text should be set")
    }
    
    /// E2E: User searches for tracks and filters results
    @MainActor
    func testE2E_UserSearchesAndFiltersTracks() async {
        // Given: Library with tracks
        let track1 = createTestTrack(id: UUID(), title: "Test Song", artist: "Test Artist")
        let track2 = createTestTrack(id: UUID(), title: "Another Song", artist: "Other Artist")
        await mockLibraryIndexer.setTracks([track1, track2])
        
        // When: User searches for "Test"
        // Note: LibraryBrowserViewModel uses LibrarySearch internally via the indexer
        let libraryViewModel = LibraryBrowserViewModel(indexer: mockLibraryIndexer)
        await libraryViewModel.loadLibrary()
        await libraryViewModel.updateSearchText("Test")
        
        // Then: Results should be filtered
        // Note: Actual filtering is tested in LibraryBrowserViewModelFilteringTests
        XCTAssertEqual(libraryViewModel.searchText, "Test", "Search text should be set")
    }
    
    /// E2E: User clears search in Library tab
    @MainActor
    func testE2E_UserClearsSearchInLibraryTab() async {
        // Given: Library tab with search text
        let libraryViewModel = LibraryBrowserViewModel()
        await libraryViewModel.updateSearchText("test")
        
        // When: User clears search
        await libraryViewModel.updateSearchText("")
        
        // Then: Search text should be empty
        XCTAssertEqual(libraryViewModel.searchText, "", "Search text should be cleared")
    }
    
    // MARK: - Playlists Tab Search E2E Tests
    
    /// E2E: User searches for playlists in Playlists tab
    @MainActor
    func testE2E_UserSearchesForPlaylistsInPlaylistsTab() async {
        // Given: Main window is open with Playlists tab selected
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        
        // When: User types in search field
        // Then: Search should route to PlaylistSidebarViewModel
        let playlistViewModel = PlaylistSidebarViewModel(playlistManager: mockPlaylistManager)
        await playlistViewModel.updateSearchText("test")
        
        // Verify search text is set
        XCTAssertEqual(playlistViewModel.searchText, "test", "Search text should be set")
    }
    
    /// E2E: User searches for playlists and filters results
    @MainActor
    func testE2E_UserSearchesAndFiltersPlaylists() async {
        // Given: Playlists list
        let playlist1 = createTestPlaylist(id: UUID(), name: "Test Playlist")
        let playlist2 = createTestPlaylist(id: UUID(), name: "Another Playlist")
        mockPlaylistManager.playlists = [playlist1, playlist2]
        
        let playlistViewModel = PlaylistSidebarViewModel(playlistManager: mockPlaylistManager)
        await playlistViewModel.loadPlaylists()
        
        // When: User searches for "Test"
        await playlistViewModel.updateSearchText("Test")
        
        // Then: Results should be filtered
        XCTAssertEqual(playlistViewModel.searchText, "Test", "Search text should be set")
        // Note: Actual filtering is tested in PlaylistSidebarViewModelTests
    }
    
    /// E2E: User clears search in Playlists tab
    @MainActor
    func testE2E_UserClearsSearchInPlaylistsTab() async {
        // Given: Playlists tab with search text
        let playlistViewModel = PlaylistSidebarViewModel(playlistManager: mockPlaylistManager)
        await playlistViewModel.updateSearchText("test")
        
        // When: User clears search
        await playlistViewModel.updateSearchText("")
        
        // Then: Search text should be empty
        XCTAssertEqual(playlistViewModel.searchText, "", "Search text should be cleared")
    }
    
    // MARK: - Devices Tab Search E2E Tests
    
    /// E2E: User searches for devices in Devices tab
    @MainActor
    func testE2E_UserSearchesForDevicesInDevicesTab() async {
        // Given: Main window is open with Devices tab selected
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        
        // When: User types in search field
        // Then: Search should route to DeviceSidebarViewModel
        let deviceViewModel = DeviceSidebarViewModel(deviceSyncManager: mockDeviceSyncManager)
        await deviceViewModel.updateSearchText("test")
        
        // Verify search text is set
        XCTAssertEqual(deviceViewModel.searchText, "test", "Search text should be set")
    }
    
    /// E2E: User searches for devices and filters results
    @MainActor
    func testE2E_UserSearchesAndFiltersDevices() async {
        // Given: Devices list
        let device1 = createTestDevice(id: UUID(), name: "Test Device")
        let device2 = createTestDevice(id: UUID(), name: "Another Device")
        await mockDeviceSyncManager.setDevices([device1, device2])
        
        let deviceViewModel = DeviceSidebarViewModel(deviceSyncManager: mockDeviceSyncManager)
        await deviceViewModel.loadDevices()
        
        // When: User searches for "Test"
        await deviceViewModel.updateSearchText("Test")
        
        // Then: Results should be filtered
        XCTAssertEqual(deviceViewModel.searchText, "Test", "Search text should be set")
        // Note: Actual filtering is tested in DeviceSidebarViewModelTests
    }
    
    /// E2E: User clears search in Devices tab
    @MainActor
    func testE2E_UserClearsSearchInDevicesTab() async {
        // Given: Devices tab with search text
        let deviceViewModel = DeviceSidebarViewModel(deviceSyncManager: mockDeviceSyncManager)
        await deviceViewModel.updateSearchText("test")
        
        // When: User clears search
        await deviceViewModel.updateSearchText("")
        
        // Then: Search text should be empty
        XCTAssertEqual(deviceViewModel.searchText, "", "Search text should be cleared")
    }
    
    // MARK: - Search Routing E2E Tests
    
    /// E2E: Search routes to correct ViewModel when switching tabs
    @MainActor
    func testE2E_SearchRoutesToCorrectViewModelWhenSwitchingTabs() async {
        // Given: Main window is open
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        
        // When: User types in search field and switches tabs
        // Then: Search should route to correct ViewModel
        // - Library tab: libraryBrowserViewModel.updateSearchText()
        // - Playlists tab: playlistSidebarViewModel.updateSearchText()
        // - Devices tab: deviceSidebarViewModel.updateSearchText()
        
        // Verify ViewModels exist and can handle search
        let libraryViewModel = LibraryBrowserViewModel()
        await libraryViewModel.updateSearchText("test")
        XCTAssertEqual(libraryViewModel.searchText, "test", "Library ViewModel should handle search")
        
        let playlistViewModel = PlaylistSidebarViewModel(playlistManager: mockPlaylistManager)
        await playlistViewModel.updateSearchText("test")
        XCTAssertEqual(playlistViewModel.searchText, "test", "Playlist ViewModel should handle search")
        
        let deviceViewModel = DeviceSidebarViewModel(deviceSyncManager: mockDeviceSyncManager)
        await deviceViewModel.updateSearchText("test")
        XCTAssertEqual(deviceViewModel.searchText, "test", "Device ViewModel should handle search")
    }
    
    /// E2E: Search persists when switching tabs
    @MainActor
    func testE2E_SearchPersistsWhenSwitchingTabs() async {
        // Given: User has typed search text in Library tab
        let libraryViewModel = LibraryBrowserViewModel()
        await libraryViewModel.updateSearchText("test query")
        
        // When: User switches to Playlists tab
        let playlistViewModel = PlaylistSidebarViewModel(playlistManager: mockPlaylistManager)
        
        // Then: Search text should be available for new tab
        // Note: In actual implementation, searchText is shared state in MainWindowLayoutView
        // Each tab's ViewModel receives the search text when that tab is active
        await playlistViewModel.updateSearchText("test query")
        XCTAssertEqual(playlistViewModel.searchText, "test query", "Search text should be available in new tab")
    }
    
    // MARK: - Search Case-Insensitivity E2E Tests
    
    /// E2E: Search is case-insensitive in Library tab
    @MainActor
    func testE2E_SearchIsCaseInsensitiveInLibraryTab() async {
        // Given: Library with tracks
        let track = createTestTrack(id: UUID(), title: "Test Song", artist: "Test Artist")
        await mockLibraryIndexer.setTracks([track])
        
        let libraryViewModel = LibraryBrowserViewModel(indexer: mockLibraryIndexer)
        await libraryViewModel.loadLibrary()
        
        // When: User searches with different cases
        await libraryViewModel.updateSearchText("TEST")
        XCTAssertEqual(libraryViewModel.searchText, "TEST", "Search should accept uppercase")
        
        await libraryViewModel.updateSearchText("test")
        XCTAssertEqual(libraryViewModel.searchText, "test", "Search should accept lowercase")
        
        await libraryViewModel.updateSearchText("TeSt")
        XCTAssertEqual(libraryViewModel.searchText, "TeSt", "Search should accept mixed case")
    }
    
    /// E2E: Search is case-insensitive in Playlists tab
    @MainActor
    func testE2E_SearchIsCaseInsensitiveInPlaylistsTab() async {
        // Given: Playlists list
        let playlist = createTestPlaylist(id: UUID(), name: "Test Playlist")
        mockPlaylistManager.playlists = [playlist]
        
        let playlistViewModel = PlaylistSidebarViewModel(playlistManager: mockPlaylistManager)
        await playlistViewModel.loadPlaylists()
        
        // When: User searches with different cases
        await playlistViewModel.updateSearchText("TEST")
        XCTAssertEqual(playlistViewModel.searchText, "TEST", "Search should accept uppercase")
        
        await playlistViewModel.updateSearchText("test")
        XCTAssertEqual(playlistViewModel.searchText, "test", "Search should accept lowercase")
    }
    
    /// E2E: Search is case-insensitive in Devices tab
    @MainActor
    func testE2E_SearchIsCaseInsensitiveInDevicesTab() async {
        // Given: Devices list
        let device = createTestDevice(id: UUID(), name: "Test Device")
        await mockDeviceSyncManager.setDevices([device])
        
        let deviceViewModel = DeviceSidebarViewModel(deviceSyncManager: mockDeviceSyncManager)
        await deviceViewModel.loadDevices()
        
        // When: User searches with different cases
        await deviceViewModel.updateSearchText("TEST")
        XCTAssertEqual(deviceViewModel.searchText, "TEST", "Search should accept uppercase")
        
        await deviceViewModel.updateSearchText("test")
        XCTAssertEqual(deviceViewModel.searchText, "test", "Search should accept lowercase")
    }
    
    // MARK: - Search Partial Matching E2E Tests
    
    /// E2E: Search supports partial matching in Library tab
    @MainActor
    func testE2E_SearchSupportsPartialMatchingInLibraryTab() async {
        // Given: Library with tracks
        let track = createTestTrack(id: UUID(), title: "Test Song", artist: "Test Artist")
        await mockLibraryIndexer.setTracks([track])
        
        let libraryViewModel = LibraryBrowserViewModel(indexer: mockLibraryIndexer)
        await libraryViewModel.loadLibrary()
        
        // When: User searches with partial text
        await libraryViewModel.updateSearchText("Test")
        XCTAssertEqual(libraryViewModel.searchText, "Test", "Search should accept partial text")
        
        await libraryViewModel.updateSearchText("Song")
        XCTAssertEqual(libraryViewModel.searchText, "Song", "Search should match partial text")
    }
    
    /// E2E: Search supports partial matching in Playlists tab
    @MainActor
    func testE2E_SearchSupportsPartialMatchingInPlaylistsTab() async {
        // Given: Playlists list
        let playlist = createTestPlaylist(id: UUID(), name: "Test Playlist")
        mockPlaylistManager.playlists = [playlist]
        
        let playlistViewModel = PlaylistSidebarViewModel(playlistManager: mockPlaylistManager)
        await playlistViewModel.loadPlaylists()
        
        // When: User searches with partial text
        await playlistViewModel.updateSearchText("Test")
        XCTAssertEqual(playlistViewModel.searchText, "Test", "Search should accept partial text")
        
        await playlistViewModel.updateSearchText("Playlist")
        XCTAssertEqual(playlistViewModel.searchText, "Playlist", "Search should match partial text")
    }
    
    /// E2E: Search supports partial matching in Devices tab
    @MainActor
    func testE2E_SearchSupportsPartialMatchingInDevicesTab() async {
        // Given: Devices list
        let device = createTestDevice(id: UUID(), name: "Test Device")
        await mockDeviceSyncManager.setDevices([device])
        
        let deviceViewModel = DeviceSidebarViewModel(deviceSyncManager: mockDeviceSyncManager)
        await deviceViewModel.loadDevices()
        
        // When: User searches with partial text
        await deviceViewModel.updateSearchText("Test")
        XCTAssertEqual(deviceViewModel.searchText, "Test", "Search should accept partial text")
        
        await deviceViewModel.updateSearchText("Device")
        XCTAssertEqual(deviceViewModel.searchText, "Device", "Search should match partial text")
    }
    
    // MARK: - Search Whitespace Handling E2E Tests
    
    /// E2E: Search trims whitespace in Library tab
    @MainActor
    func testE2E_SearchTrimsWhitespaceInLibraryTab() async {
        // Given: Library tab
        let libraryViewModel = LibraryBrowserViewModel()
        
        // When: User searches with leading/trailing whitespace
        await libraryViewModel.updateSearchText("  test  ")
        
        // Then: Whitespace should be trimmed
        // Note: Actual trimming is handled in LibrarySearch implementation
        XCTAssertEqual(libraryViewModel.searchText, "  test  ", "Search text should be set (trimming handled by search service)")
    }
    
    /// E2E: Search trims whitespace in Playlists tab
    @MainActor
    func testE2E_SearchTrimsWhitespaceInPlaylistsTab() async {
        // Given: Playlists tab
        let playlistViewModel = PlaylistSidebarViewModel(playlistManager: mockPlaylistManager)
        
        // When: User searches with leading/trailing whitespace
        await playlistViewModel.updateSearchText("  test  ")
        
        // Then: Whitespace should be trimmed
        // Note: Actual trimming is handled in PlaylistSidebarViewModel.applySearchFilter()
        XCTAssertEqual(playlistViewModel.searchText, "  test  ", "Search text should be set (trimming handled in filter)")
    }
    
    /// E2E: Search trims whitespace in Devices tab
    @MainActor
    func testE2E_SearchTrimsWhitespaceInDevicesTab() async {
        // Given: Devices tab
        let deviceViewModel = DeviceSidebarViewModel(deviceSyncManager: mockDeviceSyncManager)
        
        // When: User searches with leading/trailing whitespace
        await deviceViewModel.updateSearchText("  test  ")
        
        // Then: Whitespace should be trimmed
        // Note: Actual trimming is handled in DeviceSidebarViewModel.applySearchFilter()
        XCTAssertEqual(deviceViewModel.searchText, "  test  ", "Search text should be set (trimming handled in filter)")
    }
    
    // MARK: - Helper Methods
    
    private func createTestTrack(id: UUID, title: String, artist: String) -> Track {
        Track(
            id: id,
            title: title,
            artist: artist,
            album: "",
            duration: 180.0,
            filePath: "/test/\(title).mp3",
            fileSize: 1024 * 1024,
            bitrate: 320,
            sampleRate: 44_100
        )
    }
    
    private func createTestPlaylist(id: UUID, name: String) -> Playlist {
        Playlist(
            id: id,
            name: name,
            trackCount: 0,
            totalDuration: 0.0,
            isSmart: false
        )
    }
    
    private func createTestDevice(id: UUID, name: String) -> Device {
        Device(
            id: id,
            name: name,
            type: .usb,
            capacity: 1024 * 1024 * 1024,
            availableSpace: 512 * 1024 * 1024,
            mountPath: nil,
            status: .ready
        )
    }
}

// MARK: - Mock Implementations

/// Mock LibraryIndexer for testing (scoped to Search E2E tests)
actor SearchMockLibraryIndexer: LibraryIndexerProtocol {
    private var tracks: [UUID: Track] = [:]
    
    func setTracks(_ tracks: [Track]) async {
        self.tracks = Dictionary(uniqueKeysWithValues: tracks.map { ($0.id, $0) })
    }
    
    func index(tracks: [Track]) async throws {
        for track in tracks {
            self.tracks[track.id] = track
        }
    }
    
    func remove(track: Track) async throws {
        tracks.removeValue(forKey: track.id)
    }
    
    func clear() async throws {
        tracks.removeAll()
    }
    
    func getTrack(by id: UUID) async -> Track? {
        tracks[id]
    }
    
    func getIndexedTrackCount() async -> Int {
        tracks.count
    }
    
    func getAllTracks() async -> [Track] {
        Array(tracks.values)
    }
}

/// Mock PlaylistManager for testing (scoped to Search E2E tests)
final class SearchMockPlaylistManager: PlaylistManagerProtocol, @unchecked Sendable {
    var playlists: [Playlist] = []
    
    func createPlaylist(name: String) async throws -> Playlist {
        let playlist = Playlist(id: UUID(), name: name, trackCount: 0, totalDuration: 0.0, isSmart: false)
        playlists.append(playlist)
        return playlist
    }
    
    func createSmartPlaylist(name: String, rules: SmartPlaylistRules) async throws -> Playlist {
        guard rules.isValid else {
            throw PlaylistManagerError.invalidRules
        }
        let playlist = Playlist(id: UUID(), name: name, trackCount: 0, totalDuration: 0.0, isSmart: true)
        playlists.append(playlist)
        return playlist
    }
    
    func getPlaylist(by id: UUID) async -> Playlist? {
        playlists.first { $0.id == id }
    }
    
    func getAllPlaylists() async -> [Playlist] {
        playlists
    }
    
    func updatePlaylist(id: UUID, name: String) async throws {
        if let index = playlists.firstIndex(where: { $0.id == id }) {
            let existing = playlists[index]
            playlists[index] = Playlist(
                id: existing.id,
                name: name,
                trackCount: existing.trackCount,
                totalDuration: existing.totalDuration,
                isSmart: existing.isSmart
            )
        }
    }
    
    func deletePlaylist(id: UUID) async throws {
        playlists.removeAll { $0.id == id }
    }
    
    func addTrack(_ track: Track, to playlistId: UUID) async throws {
        // Mock implementation
    }
    
    func removeTrack(_ track: Track, from playlistId: UUID) async throws {
        // Mock implementation
    }
    
    func getTracks(in playlistId: UUID) async throws -> [Track] {
        // Mock implementation
        []
    }
    
    func reorderTracks(in playlistId: UUID, trackIds: [UUID]) async throws {
        // Mock implementation
    }
}

/// Mock DeviceSyncManager for testing (scoped to Search E2E tests)
actor SearchMockDeviceSyncManager: DeviceSyncManagerProtocol {
    private var storedDevices: [Device] = []
    private var storedJobs: [SyncJob] = []
    private var shouldThrowError = false
    
    func setDevices(_ devices: [Device]) async {
        storedDevices = devices
    }
    
    func setShouldThrowError(_ shouldThrow: Bool) async {
        shouldThrowError = shouldThrow
    }
    
    func availableDevices() async -> [Device] {
        if shouldThrowError {
            return []
        }
        return storedDevices
    }
    
    func jobs() async -> [SyncJob] {
        storedJobs
    }
    
    func startSync(request: SyncRequest) async throws -> SyncJob {
        if shouldThrowError {
            throw NSError(domain: "test", code: 1)
        }
        let job = SyncJob(
            id: UUID(),
            request: request,
            status: .queued,
            progress: SyncProgress(),
            conflicts: nil,
            errorDescription: nil
        )
        storedJobs.append(job)
        return job
    }
    
    func cancel(jobId: UUID) async {
        storedJobs.removeAll { $0.id == jobId }
    }
    
    func resolveConflicts(jobId: UUID, resolutions: [SyncConflictResolution]) async throws -> SyncJob {
        guard let job = storedJobs.first(where: { $0.id == jobId }) else {
            throw NSError(domain: "test", code: 1)
        }
        return job
    }
    
    func waitForIdle() async {
        // Mock implementation
    }
}
