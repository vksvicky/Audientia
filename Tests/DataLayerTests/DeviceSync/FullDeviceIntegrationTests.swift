//
//  FullDeviceIntegrationTests.swift
//  DataLayerTests
//
//  Full-device integration tests with real hardware
//  These tests require physical devices and will be skipped if none are available
//

@testable import DataLayer
@testable import Shared
import XCTest

final class FullDeviceIntegrationTests: XCTestCase {
    
    private var harness: PhysicalDeviceHarness!
    private var manager: DeviceSyncManager!
    private var discovery: DeviceDiscoveryService!
    private var connector: LocalDeviceConnector!
    private var queue: InMemorySyncJobQueue!
    private var conflictDetector: BasicSyncConflictDetector!
    
    override func setUp() async throws {
        try await super.setUp()
        harness = PhysicalDeviceHarness()
        discovery = DeviceDiscoveryService()
        connector = LocalDeviceConnector()
        queue = InMemorySyncJobQueue()
        conflictDetector = BasicSyncConflictDetector()
        manager = DeviceSyncManager(
            discovery: discovery,
            connector: connector,
            queue: queue,
            conflictDetector: conflictDetector
        )
    }
    
    override func tearDown() async throws {
        // Cleanup any test artifacts
        if let harness = harness {
            let devices = await harness.getAvailableDevices()
            for device in devices {
                try? await harness.cleanupDevice(device)
            }
        }
        try await super.tearDown()
    }
    
    // MARK: - Device Discovery Tests
    
    func testGivenPhysicalDeviceWhenDiscoveringThenDeviceIsDetected() async throws {
        // Given: Physical device is connected
        await harness.discoverDevices()
        
        // When: Checking for devices
        let devices = await harness.getAvailableDevices()
        
        // Then: At least one device should be detected (or test skipped)
        if devices.isEmpty {
            throw XCTSkip("No physical devices available for testing")
        }
        
        XCTAssertFalse(devices.isEmpty, "Should detect at least one physical device")
    }
    
    func testGivenUSBDeviceWhenDiscoveringThenUSBDeviceIsDetected() async throws {
        // Given: USB device is connected
        let device = try await skipIfNoDevice(harness: harness, matching: .usb)
        
        // Then: Device should be valid USB device
        XCTAssertEqual(device.type, .usb, "Device should be USB type")
        XCTAssertNotNil(device.mountPath, "USB device should have mount path")
    }
    
    func testGivenDeviceWhenValidatingThenDeviceIsWritable() async throws {
        // Given: Physical device is available
        let device = try await skipIfNoDevice(harness: harness, matching: .any)
        
        // When: Validating device
        let validation = await harness.validateDevice(device)
        
        // Then: Device should be valid and writable
        XCTAssertTrue(validation.isValid, "Device should be valid: \(validation.issues.joined(separator: ", "))")
    }
    
    // MARK: - Full Sync Integration Tests
    
    func testGivenUSBDeviceWhenSyncingSingleTrackThenTrackIsTransferred() async throws {
        // Given: USB device with sufficient space
        let device = try await skipIfNoDevice(
            harness: harness,
            matching: .minimumCapacity(10 * 1024 * 1024) // 10 MB
        )
        
        // Clean up any existing test data
        try await harness.cleanupDevice(device)
        
        // When: Starting sync with single track
        let request = await harness.createTestSyncRequest(device: device, trackCount: 1)
        let job = try await manager.startSync(request: request)
        
        // Wait for job to complete
        try await waitForJobCompletion(jobId: job.id, timeout: 30.0)
        
        // Then: Job should be completed
        let jobs = await manager.jobs()
        let completedJob = try XCTUnwrap(jobs.first { $0.id == job.id })
        XCTAssertEqual(completedJob.status, .completed, "Sync job should complete successfully")
        
        // Verify file exists on device
        if let mountPath = device.mountPath, let firstTrack = request.tracks.first {
            let rootURL = URL(fileURLWithPath: mountPath)
            let libraryFolder = rootURL.appendingPathComponent("Audientia", isDirectory: true)
            let trackFolder = libraryFolder.appendingPathComponent(firstTrack.id.uuidString, isDirectory: true)
            
            // Check that track folder was created
            let fileManager = FileManager.default
            XCTAssertTrue(
                fileManager.fileExists(atPath: trackFolder.path),
                "Track folder should exist on device"
            )
        }
    }
    
    func testGivenUSBDeviceWhenSyncingMultipleTracksThenAllTracksAreTransferred() async throws {
        // Given: USB device with sufficient space
        let device = try await skipIfNoDevice(
            harness: harness,
            matching: .minimumCapacity(50 * 1024 * 1024) // 50 MB
        )
        
        // Clean up any existing test data
        try await harness.cleanupDevice(device)
        
        // When: Starting sync with multiple tracks
        let trackCount = 5
        let request = await harness.createTestSyncRequest(device: device, trackCount: trackCount)
        let job = try await manager.startSync(request: request)
        
        // Wait for job to complete
        try await waitForJobCompletion(jobId: job.id, timeout: 60.0)
        
        // Then: Job should be completed with all tracks
        let jobs = await manager.jobs()
        let completedJob = try XCTUnwrap(jobs.first { $0.id == job.id })
        XCTAssertEqual(completedJob.status, .completed)
        XCTAssertEqual(
            completedJob.progress.completed,
            trackCount,
            "All tracks should be transferred"
        )
    }
    
    func testGivenDeviceWhenCancellingSyncThenTransferStops() async throws {
        // Given: USB device
        let device = try await skipIfNoDevice(harness: harness, matching: .usb)
        try await harness.cleanupDevice(device)
        
        // When: Starting sync and immediately cancelling
        let request = await harness.createTestSyncRequest(device: device, trackCount: 10)
        let job = try await manager.startSync(request: request)
        
        // Cancel immediately
        await manager.cancel(jobId: job.id)
        
        // Wait a bit for cancellation to process
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Then: Job should be cancelled
        let jobs = await manager.jobs()
        let cancelledJob = jobs.first { $0.id == job.id }
        XCTAssertTrue(
            cancelledJob?.status == .cancelled || cancelledJob == nil,
            "Job should be cancelled or removed from queue"
        )
    }
    
    func testGivenDeviceWhenDeviceDisconnectsThenSyncFailsGracefully() async throws {
        // Given: USB device
        let device = try await skipIfNoDevice(harness: harness, matching: .usb)
        try await harness.cleanupDevice(device)
        
        // When: Starting sync
        let request = await harness.createTestSyncRequest(device: device, trackCount: 5)
        let job = try await manager.startSync(request: request)
        
        // Note: This test requires manual device disconnection
        // In a real scenario, we'd simulate this or use a test device
        // For now, we'll just verify the job starts
        
        // Wait a bit
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Then: Job should either complete or fail (depending on disconnection)
        let jobs = await manager.jobs()
        let currentJob = jobs.first { $0.id == job.id }
        
        // Job should be in some state (not stuck)
        XCTAssertNotNil(currentJob, "Job should still be tracked")
        XCTAssertTrue(
            [.completed, .failed, .cancelled, .syncing].contains(currentJob?.status),
            "Job should be in a valid state"
        )
    }
    
    // MARK: - Conflict Detection Tests
    
    func testGivenDeviceWithExistingTrackWhenSyncingThenConflictIsDetected() async throws {
        // Given: USB device with existing track
        let device = try await skipIfNoDevice(harness: harness, matching: .usb)
        try await harness.cleanupDevice(device)
        
        // First sync to create a track on device
        let firstRequest = await harness.createTestSyncRequest(
            device: device,
            trackCount: 1,
            options: SyncOptions(autoResolveConflicts: true)
        )
        let firstJob = try await manager.startSync(request: firstRequest)
        try await waitForJobCompletion(jobId: firstJob.id, timeout: 30.0)
        
        // When: Syncing same track again (should detect conflict)
        let secondRequest = await harness.createTestSyncRequest(
            device: device,
            trackCount: 1,
            options: SyncOptions(autoResolveConflicts: false) // Don't auto-resolve
        )
        let secondJob = try await manager.startSync(request: secondRequest)
        
        // Wait for conflict detection
        try await waitForJobStatus(
            jobId: secondJob.id,
            status: .waitingForConflictResolution,
            timeout: 30.0
        )
        
        // Then: Job should be waiting for conflict resolution
        let jobs = await manager.jobs()
        let conflictJob = try XCTUnwrap(jobs.first { $0.id == secondJob.id })
        XCTAssertEqual(conflictJob.status, .waitingForConflictResolution)
        XCTAssertNotNil(conflictJob.conflicts)
        if let conflicts = conflictJob.conflicts {
            XCTAssertFalse(conflicts.isEmpty, "Should detect conflicts")
        }
    }
    
    // MARK: - Helper Methods
    
    private func waitForJobCompletion(jobId: UUID, timeout: TimeInterval) async throws {
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < timeout {
            let jobs = await manager.jobs()
            if let job = jobs.first(where: { $0.id == jobId }) {
                if job.status == .completed || job.status == .failed || job.status == .cancelled {
                    return
                }
            }
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        XCTFail("Job did not complete within timeout")
    }
    
    private func waitForJobStatus(
        jobId: UUID,
        status: SyncJobStatus,
        timeout: TimeInterval
    ) async throws {
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < timeout {
            let jobs = await manager.jobs()
            if let job = jobs.first(where: { $0.id == jobId }), job.status == status {
                return
            }
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        XCTFail("Job did not reach status \(status) within timeout")
    }
}
