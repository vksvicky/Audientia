//
//  PhysicalDeviceHarnessBDDTests.swift
//  DataLayerTests
//
//  BDD scenarios for physical device harness
//

@testable import DataLayer
@testable import Shared
import XCTest

final class PhysicalDeviceHarnessBDDTests: XCTestCase {
    
    private var harness: PhysicalDeviceHarness!
    private var manager: DeviceSyncManager!
    
    override func setUp() async throws {
        try await super.setUp()
        harness = PhysicalDeviceHarness()
        let discovery = DeviceDiscoveryService()
        let connector = LocalDeviceConnector()
        let queue = InMemorySyncJobQueue()
        let conflictDetector = BasicSyncConflictDetector()
        manager = DeviceSyncManager(
            discovery: discovery,
            connector: connector,
            queue: queue,
            conflictDetector: conflictDetector
        )
    }
    
    override func tearDown() async throws {
        if let harness = harness {
            let devices = await harness.getAvailableDevices()
            for device in devices {
                try? await harness.cleanupDevice(device)
            }
        }
        try await super.tearDown()
    }
    
    func testGivenUSBDeviceConnectedWhenUserStartsSyncThenTracksAreTransferred() async throws {
        // Scenario: As a user, I want to sync tracks to my USB device
        
        // Given: USB device is connected
        let device = try await skipIfNoDevice(harness: harness, matching: .usb)
        try await harness.cleanupDevice(device)
        
        // When: User starts sync
        let request = await harness.createTestSyncRequest(device: device, trackCount: 3)
        let job = try await manager.startSync(request: request)
        
        // Wait for completion
        var completed = false
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < 60.0 {
            let jobs = await manager.jobs()
            if let currentJob = jobs.first(where: { $0.id == job.id }),
               currentJob.status == .completed {
                completed = true
                break
            }
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
        
        // Then: Tracks should be transferred
        XCTAssertTrue(completed, "Sync should complete successfully")
        
        let finalJobs = await manager.jobs()
        let finalJob = try XCTUnwrap(finalJobs.first { $0.id == job.id })
        XCTAssertEqual(finalJob.status, .completed)
        XCTAssertEqual(finalJob.progress.completed, 3)
    }
    
    func testGivenDeviceWithInsufficientSpaceWhenUserStartsSyncThenSyncFailsGracefully() async throws {
        // Scenario: As a user, I want sync to fail gracefully if device has no space
        
        // Given: Device with very little space (if we can find one)
        // Note: This test may skip if no small device is available
        let device = try await skipIfNoDevice(harness: harness, matching: .any)
        
        // Check if device has very little space
        guard device.availableSpace < 1 * 1024 * 1024 else {
            throw XCTSkip("No device with insufficient space available for testing")
        }
        
        // When: User tries to sync large number of tracks
        let request = await harness.createTestSyncRequest(
            device: device,
            trackCount: 100,
            options: SyncOptions(enforceFreeSpace: true)
        )
        
        // Then: Sync should fail with insufficient space error
        do {
            _ = try await manager.startSync(request: request)
            XCTFail("Expected sync to fail with insufficient space")
        } catch let error as DeviceSyncError {
            XCTAssertEqual(error, .insufficientSpace, "Should fail with insufficient space error")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testGivenDeviceWhenUserCancelsSyncThenTransferStopsImmediately() async throws {
        // Scenario: As a user, I want to cancel a sync in progress
        
        // Given: Device and sync in progress
        let device = try await skipIfNoDevice(harness: harness, matching: .usb)
        try await harness.cleanupDevice(device)
        
        let request = await harness.createTestSyncRequest(device: device, trackCount: 10)
        let job = try await manager.startSync(request: request)
        
        // When: User cancels sync
        await manager.cancel(jobId: job.id)
        
        // Wait a bit
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Then: Sync should be cancelled
        let jobs = await manager.jobs()
        let cancelledJob = jobs.first { $0.id == job.id }
        XCTAssertTrue(
            cancelledJob?.status == .cancelled || cancelledJob == nil,
            "Sync should be cancelled or removed"
        )
    }
    
    func testGivenDeviceWithConflictsWhenUserResolvesConflictsThenSyncContinues() async throws {
        // Scenario: As a user, I want to resolve conflicts and continue sync
        
        // Given: Device with existing tracks (potential conflicts)
        let device = try await skipIfNoDevice(harness: harness, matching: .usb)
        try await harness.cleanupDevice(device)
        
        // First sync
        let firstRequest = await harness.createTestSyncRequest(
            device: device,
            trackCount: 1,
            options: SyncOptions(autoResolveConflicts: true)
        )
        let firstJob = try await manager.startSync(request: firstRequest)
        
        // Wait for first sync to complete
        let firstCompleted = try await waitForJobCompletion(jobId: firstJob.id, timeout: 30.0)
        guard firstCompleted else {
            throw XCTSkip("First sync did not complete, cannot test conflict resolution")
        }
        
        // When: Syncing again without auto-resolve
        let secondRequest = await harness.createTestSyncRequest(
            device: device,
            trackCount: 1,
            options: SyncOptions(autoResolveConflicts: false)
        )
        let secondJob = try await manager.startSync(request: secondRequest)
        
        // Wait for conflict detection and resolve
        let conflictDetected = try await waitForConflictAndResolve(jobId: secondJob.id, timeout: 30.0)
        
        // Then: Conflicts should be resolved and sync should continue
        XCTAssertTrue(conflictDetected, "Conflicts should be detected")
        
        // Wait for final completion
        let finalCompleted = try await waitForJobCompletion(jobId: secondJob.id, timeout: 30.0)
        XCTAssertTrue(finalCompleted, "Sync should complete after conflict resolution")
    }
    
    private func waitForJobCompletion(jobId: UUID, timeout: TimeInterval) async throws -> Bool {
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < timeout {
            let jobs = await manager.jobs()
            if let job = jobs.first(where: { $0.id == jobId }),
               job.status == .completed {
                return true
            }
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        return false
    }
    
    private func waitForConflictAndResolve(jobId: UUID, timeout: TimeInterval) async throws -> Bool {
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < timeout {
            let jobs = await manager.jobs()
            if let job = jobs.first(where: { $0.id == jobId }),
               job.status == .waitingForConflictResolution {
                // Resolve conflicts
                if let conflicts = job.conflicts {
                    let resolutions = conflicts.map {
                        SyncConflictResolution(conflictId: $0.id, action: .keepLibraryVersion)
                    }
                    _ = try await manager.resolveConflicts(jobId: job.id, resolutions: resolutions)
                }
                return true
            }
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        return false
    }
}
