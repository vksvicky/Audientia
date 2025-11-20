//
//  DeviceSyncViewBDDTests.swift
//  UITests
//
//  BDD scenarios for DeviceSyncView + ViewModel
//

@testable import Audientia
@testable import DataLayer
@testable import Shared
import XCTest

@MainActor
final class DeviceSyncViewBDDTests: XCTestCase {
    
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
    
    func testGivenTwoDevicesWhenViewAppearsThenUserSeesBothDevices() async {
        // Given
        await manager.setDevices([
            Device(id: UUID(), name: "USB Audio", type: .usb, capacity: 128_000, availableSpace: 64_000, mountPath: nil, status: .ready),
            Device(id: UUID(), name: "Studio Drive", type: .usb, capacity: 256_000, availableSpace: 128_000, mountPath: nil, status: .ready)
        ])
        
        // When
        await viewModel.refreshDevices()
        
        // Then
        XCTAssertEqual(viewModel.devices.count, 2)
        XCTAssertEqual(viewModel.devices.map(\.name), ["USB Audio", "Studio Drive"])
    }
    
    func testGivenSyncInProgressWhenConflictResolvedThenJobCompletes() async throws {
        // Given
        let device = Device(id: UUID(), name: "USB", type: .usb, capacity: 128_000, availableSpace: 64_000, mountPath: nil, status: .ready)
        await manager.setDevices([device])
        await viewModel.refreshDevices()
        await viewModel.startSync(tracks: sampleTracks(count: 1))
        var job = try XCTUnwrap(viewModel.jobs.first)
        job.status = .waitingForConflictResolution
        let conflictTrack = sampleTracks(count: 1)[0]
        let conflict = SyncConflict(track: conflictTrack, reason: .changedOnDevice)
        job.conflicts = [conflict]
        await manager.setJobs([job])
        await viewModel.reloadJobs()
        
        // When
        guard let pendingJob = viewModel.jobs.first, let pendingConflict = pendingJob.conflicts?.first else {
            XCTFail("Expected conflict to resolve")
            return
        }
        let resolution = SyncConflictResolution(conflictId: pendingConflict.id, action: .keepLibraryVersion)
        await viewModel.resolve(job: pendingJob, with: [resolution])
        
        // Then
        XCTAssertEqual(viewModel.jobs.first?.status, .queued)
    }
    
    // MARK: - Helpers
    
    private func sampleTracks(count: Int) -> [Track] {
        (0..<count).map { index in
            Track(
                title: "BDD Track \(index)",
                artist: "Artist",
                album: "Album",
                duration: 200,
                filePath: "/tmp/bdd\(index).flac",
                fileSize: 1_000_000,
                bitrate: 320,
                sampleRate: 44_100
            )
        }
    }
}
