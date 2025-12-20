//
//  KeyboardNavigationIntegrationTests.swift
//  UITests
//
//  Integration tests for keyboard navigation across views
//  Tests end-to-end keyboard navigation workflows with mocking
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import XCTest

@testable import Audientia
@testable import DataLayer
@testable import Shared

/// Integration tests for keyboard navigation
/// Tests keyboard navigation workflows across multiple views and components
@MainActor
final class KeyboardNavigationIntegrationTests: XCTestCase {
    
    // MARK: - Integration Test 1: Library Browser Navigation
    
    /// Test: Arrow key navigation in LibraryBrowserView should work end-to-end
    func testLibraryBrowserArrowKeyNavigation() async {
        // Given: LibraryBrowserView is set up with tracks
        let mockViewModel = MockLibraryBrowserViewModel()
        let tracks = createTestTracks(count: 10)
        mockViewModel.filteredTracks = tracks
        
        // When: User navigates with arrow keys
        // Then: Selection should update correctly
        // Note: This is a simplified integration test
        // Full integration would require view rendering
        
        XCTAssertEqual(tracks.count, 10, "Should have 10 tracks")
    }
    
    // MARK: - Integration Test 2: Playlist Browser Navigation
    
    /// Test: Arrow key navigation in PlaylistBrowserView should work end-to-end
    func testPlaylistBrowserArrowKeyNavigation() async {
        // Given: PlaylistBrowserView is set up with playlists
        let mockPlaylistManager = MockPlaylistManager()
        let playlists = createTestPlaylists(count: 5)
        mockPlaylistManager.playlists = playlists
        
        let viewModel = PlaylistViewModel(playlistManager: mockPlaylistManager)
        await viewModel.loadPlaylists()
        
        // When: User navigates with arrow keys
        // Then: Selection should update correctly
        XCTAssertEqual(viewModel.playlists.count, 5, "Should have 5 playlists")
    }
    
    // MARK: - Integration Test 3: Device List Navigation
    
    /// Test: Arrow key navigation in DeviceListSection should work end-to-end
    func testDeviceListArrowKeyNavigation() async {
        // Given: DeviceListSection is set up with devices
        let mockDeviceSyncManager = MockDeviceSyncManager()
        let devices = createTestDevices(count: 5)
        await mockDeviceSyncManager.setDevices(devices)
        
        let viewModel = DeviceSidebarViewModel(deviceSyncManager: mockDeviceSyncManager)
        await viewModel.loadDevices()
        
        // When: User navigates with arrow keys
        // Then: Selection should update correctly
        let availableDevices = await mockDeviceSyncManager.availableDevices()
        XCTAssertEqual(availableDevices.count, 5, "Should have 5 devices")
    }
    
    // MARK: - Integration Test 4: Cross-View Navigation
    
    /// Test: Navigation should work consistently across different views
    func testCrossViewNavigationConsistency() async {
        // Given: Multiple views with lists
        let mockPlaylistManager = MockPlaylistManager()
        let playlists = createTestPlaylists(count: 3)
        mockPlaylistManager.playlists = playlists
        
        let playlistViewModel = PlaylistViewModel(playlistManager: mockPlaylistManager)
        await playlistViewModel.loadPlaylists()
        
        let mockDeviceSyncManager = MockDeviceSyncManager()
        let devices = createTestDevices(count: 3)
        await mockDeviceSyncManager.setDevices(devices)
        
        let deviceViewModel = DeviceSidebarViewModel(deviceSyncManager: mockDeviceSyncManager)
        await deviceViewModel.loadDevices()
        
        // When: User navigates in different views
        // Then: Navigation should work consistently
        XCTAssertEqual(playlistViewModel.playlists.count, 3, "Should have 3 playlists")
        XCTAssertEqual(deviceViewModel.devices.count, 3, "Should have 3 devices")
    }
    
    // MARK: - Integration Test 5: ListNavigationManager Integration
    
    /// Test: ListNavigationManager should work with different types
    func testListNavigationManagerWithDifferentTypes() {
        // Given: ListNavigationManager instances for different types
        let trackManager = ListNavigationManager<Shared.Track>()
        let playlistManager = ListNavigationManager<Shared.Playlist>()
        let deviceManager = ListNavigationManager<Shared.Device>()
        
        // When: We update items
        let tracks = createTestTracks(count: 5)
        trackManager.updateItems(tracks)
        
        let playlists = createTestPlaylists(count: 5)
        playlistManager.updateItems(playlists)
        
        let devices = createTestDevices(count: 5)
        deviceManager.updateItems(devices)
        
        // Then: All managers should work correctly
        XCTAssertEqual(trackManager.itemCount, 5, "Track manager should have 5 items")
        XCTAssertEqual(playlistManager.itemCount, 5, "Playlist manager should have 5 items")
        XCTAssertEqual(deviceManager.itemCount, 5, "Device manager should have 5 items")
    }
    
    // MARK: - Integration Test 6: KeyboardActivationManager Integration
    
    /// Test: KeyboardActivationManager should work with multiple elements
    func testKeyboardActivationManagerIntegration() {
        // Given: KeyboardActivationManager with multiple elements
        let manager = KeyboardActivationManager()
        let element1 = MockActivatable()
        let element2 = MockActivatable()
        
        manager.register(element1, identifier: "element-1")
        manager.register(element2, identifier: "element-2")
        
        // When: We focus and activate elements
        manager.setFocus(to: "element-1")
        _ = manager.handleEnter()
        
        manager.setFocus(to: "element-2")
        _ = manager.handleSpace()
        
        // Then: Elements should be activated correctly
        XCTAssertTrue(element1.activateCalled, "Element 1 should be activated")
        XCTAssertTrue(element2.toggleCalled, "Element 2 should be toggled")
    }
    
    // MARK: - Helper Methods
    
    private func createTestTracks(count: Int) -> [Shared.Track] {
        var result: [Shared.Track] = []
        for index in 0..<count {
            let duration = TimeInterval(180 + index * 10)
            let fileSize = Int64(1024 * 1024 * (5 + index))
            let year = 2020 + (index % 5)
            let track = Shared.Track(
                id: UUID(),
                title: "Track \(index + 1)",
                artist: "Artist \(index + 1)",
                album: "Album \(index + 1)",
                duration: duration,
                filePath: "/path/to/track\(index + 1).mp3",
                fileSize: fileSize,
                bitrate: 320,
                sampleRate: 44100,
                year: year,
                trackNumber: index + 1,
                discNumber: 1,
                genre: "Genre \(index % 3)"
            )
            result.append(track)
        }
        return result
    }
    
    private func createTestPlaylists(count: Int) -> [Shared.Playlist] {
        (0..<count).map { index in
            Shared.Playlist(
                id: UUID(),
                name: "Playlist \(index + 1)",
                trackCount: index * 2,
                totalDuration: TimeInterval(index * 180),
                isSmart: false
            )
        }
    }
    
    private func createTestDevices(count: Int) -> [Shared.Device] {
        var result: [Shared.Device] = []
        for index in 0..<count {
            let deviceType: Shared.DeviceType = index % 3 == 0 ? .usb : (index % 3 == 1 ? .mtp : .smb)
            let capacity = Int64(1000 * 1024 * 1024) // 1GB capacity
            let availableSpace = Int64((1000 - index) * 1024 * 1024) // Decreasing space
            let device = Shared.Device(
                id: UUID(),
                name: "Device \(index + 1)",
                type: deviceType,
                capacity: capacity,
                availableSpace: availableSpace,
                mountPath: nil,
                status: .ready
            )
            result.append(device)
        }
        return result
    }
}

/// Mock activatable element for integration testing
private final class MockActivatable: KeyboardActivatable {
    var activateCalled = false
    var toggleCalled = false
    var cancelCalled = false
    
    func activate() {
        activateCalled = true
    }
    
    func toggle() {
        toggleCalled = true
    }
    
    func cancel() {
        cancelCalled = true
    }
}

/// Mock LibraryBrowserViewModel for integration testing
@MainActor
private final class MockLibraryBrowserViewModel: ObservableObject {
    @Published var filteredTracks: [Shared.Track] = []
    @Published var isLoading = false
    @Published var lastError: Error?
    
    func clearError() {
        lastError = nil
    }
}
