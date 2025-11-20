//
//  DeviceSyncViewModelTests.swift
//  UITests
//
//  TDD tests for DeviceSyncViewModel (Feature 4.1)
//

@testable import Audientia
@testable import DataLayer
@testable import Shared
import XCTest

@MainActor
final class DeviceSyncViewModelTests: XCTestCase {
    
    private var manager: MockDeviceSyncManager!
    private var viewModel: DeviceSyncViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        manager = MockDeviceSyncManager()
        viewModel = DeviceSyncViewModel(manager: manager)
    }
    
    override func tearDown() async throws {
        manager = nil
        viewModel = nil
        try await super.tearDown()
    }
    
    func testRefreshDevicesUpdatesPublishedList() async {
        // Given
        await manager.setDevices([
            Device(id: UUID(), name: "USB 1", type: .usb, capacity: 64 * 1024, availableSpace: 32 * 1024, mountPath: nil, status: .ready)
        ])
        
        // When
        await viewModel.refreshDevices()
        
        // Then
        XCTAssertEqual(viewModel.devices.count, 1)
        XCTAssertEqual(viewModel.selectedDevice?.name, "USB 1")
    }
    
    func testStartSyncAddsJob() async throws {
        // Given
        await manager.setDevices([sampleDevice(name: "Studio Drive")])
        await viewModel.refreshDevices()
        let tracks = sampleTracks(count: 2)
        
        // When
        await viewModel.startSync(tracks: tracks)
        
        // Then
        XCTAssertEqual(viewModel.jobs.count, 1)
        XCTAssertEqual(viewModel.jobs.first?.request.tracks.count, 2)
    }
    
    func testErrorDuringSyncSetsLastError() async {
        // Given
        await manager.setDevices([sampleDevice(name: "USB Pro")])
        await viewModel.refreshDevices()
        await manager.configureStartSyncFailure(shouldFail: true, error: DeviceSyncError.deviceDisconnected)
        
        // When
        await viewModel.startSync(tracks: sampleTracks())
        
        // Then
        XCTAssertEqual(viewModel.lastError, DeviceSyncError.deviceDisconnected.localizedDescription)
    }
    
    func testCancelJobUpdatesViewModelState() async throws {
        // Given
        await manager.setDevices([sampleDevice()])
        await viewModel.refreshDevices()
        await viewModel.startSync(tracks: sampleTracks())
        let job = try XCTUnwrap(viewModel.jobs.first)
        
        // When
        await viewModel.cancel(job: job)
        
        // Then
        XCTAssertEqual(viewModel.jobs.first?.status, .cancelled)
    }
    
    // MARK: - Helpers
    
    private func sampleDevice(name: String = "USB Drive") -> Device {
        Device(
            id: UUID(),
            name: name,
            type: .usb,
            capacity: 128 * 1024,
            availableSpace: 64 * 1024,
            mountPath: "/Volumes/\(name)",
            status: .ready
        )
    }
    
    private func sampleTracks(count: Int = 1) -> [Track] {
        (0..<count).map { index in
            Track(
                title: "Track \(index)",
                artist: "Artist",
                album: "Album",
                duration: 120,
                filePath: "/tmp/track\(index).flac",
                fileSize: 1_000_000,
                bitrate: 320,
                sampleRate: 44_100
            )
        }
    }
}
