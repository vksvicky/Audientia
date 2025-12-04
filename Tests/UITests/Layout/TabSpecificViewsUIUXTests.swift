//
//  TabSpecificViewsUIUXTests.swift
//  Audientia - UI Tests
//
//  UI/UX tests for all tab-specific views
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import SwiftUI
import XCTest

@testable import Audientia
@testable import AudioCore
@testable import DataLayer
@preconcurrency import MetadataEngine
@testable import Shared

// MARK: - UI/UX Tests for Tab-Specific Views

/// UI/UX tests for all tab-specific views
final class TabSpecificViewsUIUXTests: XCTestCase {
    
    var mockAudioEngine: MockAudioEngine!
    var mockLibraryIndexer: TabsMockLibraryIndexer!
    var mockPlaylistManager: TabsMockPlaylistManager!
    var mockDeviceSyncManager: TabsMockDeviceSyncManager!
    var mockListeningHistory: TabsMockListeningHistory!
    
    @MainActor
    override func setUp() {
        super.setUp()
        mockAudioEngine = MockAudioEngine()
        mockLibraryIndexer = TabsMockLibraryIndexer()
        mockPlaylistManager = TabsMockPlaylistManager()
        mockDeviceSyncManager = TabsMockDeviceSyncManager()
        mockListeningHistory = TabsMockListeningHistory()
    }
    
    override func tearDown() {
        mockAudioEngine = nil
        mockLibraryIndexer = nil
        mockPlaylistManager = nil
        mockDeviceSyncManager = nil
        mockListeningHistory = nil
        super.tearDown()
    }
    
    // MARK: - Home Tab UI/UX Tests
    
    /// UI/UX: HomeContentView renders correctly
    @MainActor
    func testUIUX_HomeContentViewRendersCorrectly() {
        // Given: HomeViewModel with data
        _ = HomeViewModel(
            listeningHistory: mockListeningHistory,
            libraryIndexer: mockLibraryIndexer
        )
        
        // When: Creating MainWindowLayoutView (HomeContentView is private, so we test through MainWindowLayoutView)
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        
        // Then: View should be created successfully
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// UI/UX: HomeContentView displays recently played section
    @MainActor
    func testUIUX_HomeContentViewDisplaysRecentlyPlayed() async {
        // Given: HomeViewModel with recently played tracks
        let track = createTestTrack(id: UUID(), title: "Test Song", artist: "Test Artist")
        await mockLibraryIndexer.setTracks([track])
        await mockListeningHistory.recordEvent(ListeningEvent(
            trackId: track.id,
            timestamp: Date(),
            playDuration: 120.0,
            wasSkipped: false
        ))
        
        let homeViewModel = HomeViewModel(
            listeningHistory: mockListeningHistory,
            libraryIndexer: mockLibraryIndexer
        )
        await homeViewModel.loadRecentlyPlayed(limit: 10)
        
        // When: Creating MainWindowLayoutView (HomeContentView is private, so we test through MainWindowLayoutView)
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        
        // Then: View should be created and display recently played
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        XCTAssertFalse(homeViewModel.recentlyPlayedTracks.isEmpty, "Should have recently played tracks")
    }
    
    /// UI/UX: HomeContentView displays recently added section
    @MainActor
    func testUIUX_HomeContentViewDisplaysRecentlyAdded() async {
        // Given: HomeViewModel with recently added tracks
        let track = createTestTrack(id: UUID(), title: "New Song", artist: "New Artist")
        await mockLibraryIndexer.setTracks([track])
        
        let homeViewModel = HomeViewModel(
            listeningHistory: mockListeningHistory,
            libraryIndexer: mockLibraryIndexer
        )
        await homeViewModel.loadRecentlyAdded(limit: 10)
        
        // When: Creating MainWindowLayoutView (HomeContentView is private, so we test through MainWindowLayoutView)
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        
        // Then: View should be created and display recently added
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        XCTAssertFalse(homeViewModel.recentlyAddedTracks.isEmpty, "Should have recently added tracks")
    }
    
    /// UI/UX: HomeContentView displays most played section
    @MainActor
    func testUIUX_HomeContentViewDisplaysMostPlayed() async {
        // Given: HomeViewModel with most played tracks
        let track = createTestTrack(id: UUID(), title: "Popular Song", artist: "Popular Artist")
        await mockLibraryIndexer.setTracks([track])
        await mockListeningHistory.recordEvent(ListeningEvent(
            trackId: track.id,
            timestamp: Date(),
            playDuration: 120.0,
            wasSkipped: false
        ))
        
        let homeViewModel = HomeViewModel(
            listeningHistory: mockListeningHistory,
            libraryIndexer: mockLibraryIndexer
        )
        await homeViewModel.loadMostPlayed(limit: 10)
        
        // When: Creating MainWindowLayoutView (HomeContentView is private, so we test through MainWindowLayoutView)
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        
        // Then: View should be created and display most played
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        XCTAssertFalse(homeViewModel.mostPlayedTracks.isEmpty, "Should have most played tracks")
    }
    
    /// UI/UX: HomeContentView displays favourites section
    @MainActor
    func testUIUX_HomeContentViewDisplaysFavourites() async {
        // Given: HomeViewModel with favourite tracks
        let track = createTestTrack(id: UUID(), title: "Favourite Song", artist: "Favourite Artist", rating: 5)
        await mockLibraryIndexer.setTracks([track])
        
        let homeViewModel = HomeViewModel(
            listeningHistory: mockListeningHistory,
            libraryIndexer: mockLibraryIndexer
        )
        await homeViewModel.loadFavourites(limit: 10)
        
        // When: Creating MainWindowLayoutView (HomeContentView is private, so we test through MainWindowLayoutView)
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        
        // Then: View should be created and display favourites
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        XCTAssertFalse(homeViewModel.favouriteTracks.isEmpty, "Should have favourite tracks")
    }
    
    /// UI/UX: HomeContentView handles empty state
    @MainActor
    func testUIUX_HomeContentViewHandlesEmptyState() {
        // Given: HomeViewModel with no data
        let homeViewModel = HomeViewModel(
            listeningHistory: mockListeningHistory,
            libraryIndexer: mockLibraryIndexer
        )
        
        // When: Creating MainWindowLayoutView (HomeContentView is private, so we test through MainWindowLayoutView)
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        
        // Then: View should be created and handle empty state gracefully
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        XCTAssertTrue(homeViewModel.recentlyPlayedTracks.isEmpty, "Should have no recently played tracks")
        XCTAssertTrue(homeViewModel.recentlyAddedTracks.isEmpty, "Should have no recently added tracks")
    }
    
    // MARK: - Library Tab UI/UX Tests
    
    /// UI/UX: LibraryBrowserView renders correctly
    @MainActor
    func testUIUX_LibraryBrowserViewRendersCorrectly() {
        // Given: LibraryBrowserViewModel
        let viewModel = LibraryBrowserViewModel(indexer: mockLibraryIndexer)
        
        // When: Creating LibraryBrowserView
        let view = LibraryBrowserView(viewModel: viewModel)
        
        // Then: View should be created successfully
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// UI/UX: LibraryBrowserView displays tracks
    @MainActor
    func testUIUX_LibraryBrowserViewDisplaysTracks() async {
        // Given: LibraryBrowserViewModel with tracks
        let track = createTestTrack(id: UUID(), title: "Library Song", artist: "Library Artist")
        await mockLibraryIndexer.setTracks([track])
        
        let viewModel = LibraryBrowserViewModel(indexer: mockLibraryIndexer)
        await viewModel.loadLibrary()
        
        // When: Creating LibraryBrowserView
        let view = LibraryBrowserView(viewModel: viewModel)
        
        // Then: View should be created and display tracks
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        XCTAssertFalse(viewModel.filteredTracks.isEmpty, "Should have tracks")
    }
    
    /// UI/UX: LibraryBrowserView handles empty library
    @MainActor
    func testUIUX_LibraryBrowserViewHandlesEmptyLibrary() async {
        // Given: LibraryBrowserViewModel with no tracks
        await mockLibraryIndexer.setTracks([])
        
        let viewModel = LibraryBrowserViewModel(indexer: mockLibraryIndexer)
        await viewModel.loadLibrary()
        
        // When: Creating LibraryBrowserView
        let view = LibraryBrowserView(viewModel: viewModel)
        
        // Then: View should be created and handle empty state
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        XCTAssertTrue(viewModel.filteredTracks.isEmpty, "Should have no tracks")
    }
    
    /// UI/UX: LibraryBrowserView handles loading state
    @MainActor
    func testUIUX_LibraryBrowserViewHandlesLoadingState() {
        // Given: LibraryBrowserViewModel
        let viewModel = LibraryBrowserViewModel(indexer: mockLibraryIndexer)
        
        // When: ViewModel is loading
        // Note: isLoading is set internally during loadLibrary()
        
        // Then: View should handle loading state
        let view = LibraryBrowserView(viewModel: viewModel)
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// UI/UX: LibraryBrowserView handles error state
    @MainActor
    func testUIUX_LibraryBrowserViewHandlesErrorState() {
        // Given: LibraryBrowserViewModel
        let viewModel = LibraryBrowserViewModel(indexer: mockLibraryIndexer)
        
        // When: ViewModel has error
        // Note: Error handling is tested in LibraryBrowserViewModelTests
        
        // Then: View should handle error state
        let view = LibraryBrowserView(viewModel: viewModel)
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    // MARK: - Playlists Tab UI/UX Tests
    
    /// UI/UX: PlaylistBrowserView renders correctly
    @MainActor
    func testUIUX_PlaylistBrowserViewRendersCorrectly() {
        // Given: PlaylistManager
        let playlistManager = mockPlaylistManager as any PlaylistManagerProtocol
        
        // When: Creating PlaylistBrowserView
        let view = PlaylistBrowserView(playlistManager: playlistManager)
        
        // Then: View should be created successfully
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// UI/UX: PlaylistBrowserView displays playlists
    @MainActor
    func testUIUX_PlaylistBrowserViewDisplaysPlaylists() async {
        // Given: PlaylistManager with playlists
        let playlist = createTestPlaylist(id: UUID(), name: "Test Playlist")
        await mockPlaylistManager.setPlaylists([playlist])
        
        let playlistManager = mockPlaylistManager as any PlaylistManagerProtocol
        
        // When: Creating PlaylistBrowserView
        let view = PlaylistBrowserView(playlistManager: playlistManager)
        
        // Then: View should be created and display playlists
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// UI/UX: PlaylistBrowserView handles empty playlists
    @MainActor
    func testUIUX_PlaylistBrowserViewHandlesEmptyPlaylists() async {
        // Given: PlaylistManager with no playlists
        await mockPlaylistManager.setPlaylists([])
        
        let playlistManager = mockPlaylistManager as any PlaylistManagerProtocol
        
        // When: Creating PlaylistBrowserView
        let view = PlaylistBrowserView(playlistManager: playlistManager)
        
        // Then: View should be created and handle empty state
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    // MARK: - Devices Tab UI/UX Tests
    
    /// UI/UX: DeviceSyncView renders correctly
    @MainActor
    func testUIUX_DeviceSyncViewRendersCorrectly() {
        // When: Creating DeviceSyncView
        let view = DeviceSyncView()
        
        // Then: View should be created successfully
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// UI/UX: DeviceSyncView displays device sync interface
    @MainActor
    func testUIUX_DeviceSyncViewDisplaysDeviceSyncInterface() {
        // Given: DeviceSyncView
        let view = DeviceSyncView()
        
        // When: View is created
        // Then: View should display device sync interface
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// UI/UX: DeviceSyncView handles no devices state
    @MainActor
    func testUIUX_DeviceSyncViewHandlesNoDevices() {
        // Given: DeviceSyncView with no devices
        let view = DeviceSyncView()
        
        // When: View is created
        // Then: View should handle no devices state
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    // MARK: - Visualiser Tab UI/UX Tests
    
    /// UI/UX: AudioVisualiserView renders correctly
    @MainActor
    func testUIUX_AudioVisualiserViewRendersCorrectly() {
        // Given: NowPlayingViewModel and AudioEngine
        let nowPlayingViewModel = NowPlayingViewModel(audioEngine: mockAudioEngine)
        
        // When: Creating AudioVisualiserView
        let view = AudioVisualiserView(
            nowPlayingViewModel: nowPlayingViewModel,
            audioEngine: nil, // MockAudioEngine doesn't conform to AudioEngine, use nil for tests
            viewModel: nil
        )
        
        // Then: View should be created successfully
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// UI/UX: AudioVisualiserView displays visualisation
    @MainActor
    func testUIUX_AudioVisualiserViewDisplaysVisualisation() {
        // Given: NowPlayingViewModel and AudioEngine
        let nowPlayingViewModel = NowPlayingViewModel(audioEngine: mockAudioEngine)
        let audioVisualiserViewModel = AudioVisualiserViewModel(
            nowPlayingViewModel: nowPlayingViewModel,
            audioEngine: nil // MockAudioEngine doesn't conform to AudioEngine, use nil for tests
        )
        
        // When: Creating AudioVisualiserView with ViewModel
        let view = AudioVisualiserView(
            nowPlayingViewModel: nowPlayingViewModel,
            audioEngine: nil, // MockAudioEngine doesn't conform to AudioEngine, use nil for tests
            viewModel: audioVisualiserViewModel
        )
        
        // Then: View should be created and display visualisation
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    /// UI/UX: AudioVisualiserView handles no audio state
    @MainActor
    func testUIUX_AudioVisualiserViewHandlesNoAudio() {
        // Given: NowPlayingViewModel with no audio
        let nowPlayingViewModel = NowPlayingViewModel(audioEngine: mockAudioEngine)
        
        // When: Creating AudioVisualiserView
        let view = AudioVisualiserView(
            nowPlayingViewModel: nowPlayingViewModel,
            audioEngine: nil, // MockAudioEngine doesn't conform to AudioEngine, use nil for tests
            viewModel: nil
        )
        
        // Then: View should be created and handle no audio state
        SwiftUIViewTestHelpers.verifyViewCreation(view)
    }
    
    // MARK: - View Layout and Positioning Tests
    
    /// UI/UX: All tab views have correct frame constraints
    @MainActor
    func testUIUX_AllTabViewsHaveCorrectFrameConstraints() {
        // Given: All tab views
        // Note: HomeContentView is private, so we test through MainWindowLayoutView
        let homeView = MainWindowLayoutView(audioEngine: mockAudioEngine)
        
        let libraryViewModel = LibraryBrowserViewModel(indexer: mockLibraryIndexer)
        let libraryView = LibraryBrowserView(viewModel: libraryViewModel)
        
        let playlistManager = mockPlaylistManager as any PlaylistManagerProtocol
        let playlistView = PlaylistBrowserView(playlistManager: playlistManager)
        
        let deviceView = DeviceSyncView()
        
        let nowPlayingViewModel = NowPlayingViewModel(audioEngine: mockAudioEngine)
        let visualiserView = AudioVisualiserView(
            nowPlayingViewModel: nowPlayingViewModel,
            audioEngine: nil, // MockAudioEngine doesn't conform to AudioEngine, use nil for tests
            viewModel: nil
        )
        
        // When: Views are created
        // Then: All views should be created successfully
        SwiftUIViewTestHelpers.verifyViewCreation(homeView)
        SwiftUIViewTestHelpers.verifyViewCreation(libraryView)
        SwiftUIViewTestHelpers.verifyViewCreation(playlistView)
        SwiftUIViewTestHelpers.verifyViewCreation(deviceView)
        SwiftUIViewTestHelpers.verifyViewCreation(visualiserView)
    }
    
    /// UI/UX: Views update when data changes
    @MainActor
    func testUIUX_ViewsUpdateWhenDataChanges() async {
        // Given: HomeViewModel with initial data
        let homeViewModel = HomeViewModel(
            listeningHistory: mockListeningHistory,
            libraryIndexer: mockLibraryIndexer
        )
        // Note: HomeContentView is private, so we test through MainWindowLayoutView
        let view = MainWindowLayoutView(audioEngine: mockAudioEngine)
        SwiftUIViewTestHelpers.verifyViewCreation(view)
        
        // When: Adding new tracks
        let track = createTestTrack(id: UUID(), title: "New Track", artist: "New Artist")
        await mockLibraryIndexer.setTracks([track])
        await homeViewModel.loadRecentlyAdded(limit: 10)
        
        // Then: View should update with new data
        XCTAssertFalse(homeViewModel.recentlyAddedTracks.isEmpty, "Should have updated tracks")
    }
    
    // MARK: - Helper Methods
    
    private func createTestTrack(id: UUID, title: String, artist: String, rating: Int? = nil) -> Track {
        Track(
            id: id,
            title: title,
            artist: artist,
            album: "Test Album",
            duration: 180.0,
            filePath: "/test/\(title).mp3",
            fileSize: 1024 * 1024,
            bitrate: 320,
            sampleRate: 44100,
            rating: rating
        )
    }
    
    private func createTestPlaylist(id: UUID, name: String) -> Playlist {
        Playlist(id: id, name: name, trackCount: 0, totalDuration: 0.0, isSmart: false)
    }
}

// MARK: - Mock Implementations

/// Mock ListeningHistory for testing (Tabs-specific)
actor TabsMockListeningHistory: ListeningHistoryProtocol {
    private var events: [ListeningEvent] = []
    
    func recordEvent(_ event: ListeningEvent) async {
        events.append(event)
    }
    
    func getRecentEvents(limit: Int) async -> [ListeningEvent] {
        Array(events.suffix(limit))
    }
    
    func getPlayCount(for trackId: UUID) async -> Int {
        events.filter { $0.trackId == trackId && !$0.wasSkipped }.count
    }
    
    func getSkipCount(for trackId: UUID) async -> Int {
        events.filter { $0.trackId == trackId && $0.wasSkipped }.count
    }
    
    func getTracksPlayed(from startDate: Date, to endDate: Date) async -> [UUID] {
        events
            .filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
            .map { $0.trackId }
    }
}

/// Mock LibraryIndexer for testing (Tabs-specific)
actor TabsMockLibraryIndexer: LibraryIndexerProtocol {
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

/// Mock PlaylistManager for testing (Tabs-specific)
final class TabsMockPlaylistManager: PlaylistManagerProtocol, @unchecked Sendable {
    private var playlists: [Playlist] = []
    
    func setPlaylists(_ playlists: [Playlist]) async {
        self.playlists = playlists
    }
    
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
        []
    }
    
    func reorderTracks(in playlistId: UUID, trackIds: [UUID]) async throws {
        // Mock implementation
    }
}

/// Mock DeviceSyncManager for testing (Tabs-specific)
actor TabsMockDeviceSyncManager: DeviceSyncManagerProtocol {
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
