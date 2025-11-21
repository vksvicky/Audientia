//
//  DeviceSyncManagerPersistentQueueTests.swift
//  DataLayerTests
//
//  Tests for DeviceSyncManager with persistent queue
//

@testable import DataLayer
@testable import Shared
import XCTest

final class DeviceSyncManagerPersistentQueueTests: XCTestCase {
    
    private var manager: DeviceSyncManager!
    private var discovery: MockDeviceDiscovery!
    private var connector: MockDeviceConnector!
    private var queue: PersistentSyncJobQueue!
    private var conflictDetector: MockConflictDetector!
    private var dbURL: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        let tempDir = FileManager.default.temporaryDirectory
        dbURL = tempDir.appendingPathComponent("test_queue_\(UUID().uuidString).db")
        queue = PersistentSyncJobQueue(databaseURL: dbURL)
        let persistedCount = await queue.debugJobCount()
        print("debug count after reopening queue = \(persistedCount)")
        discovery = MockDeviceDiscovery()
        connector = MockDeviceConnector()
        conflictDetector = MockConflictDetector()
        // Don't create manager in setUp - create it per test to avoid waiters
        manager = nil
    }
    
    override func tearDown() async throws {
        if let manager = manager {
            await manager.waitForIdle()
        }
        manager = nil
        discovery = nil
        connector = nil
        conflictDetector = nil
        if let queue = queue {
            await queue.close()
        }
        queue = nil
        if let dbURL = dbURL, FileManager.default.fileExists(atPath: dbURL.path) {
            try? FileManager.default.removeItem(at: dbURL)
        }
        try await super.tearDown()
    }
    
    func testGivenJobsInPersistentQueueWhenManagerInitializedThenJobsAreRestored() async throws {
        // Given: Jobs in persistent queue
        let device = DeviceSyncFixtures.usbDevice()
        await discovery.setDevices([device])
        let tracks = DeviceSyncFixtures.tracks(count: 2)
        let request = DeviceSyncFixtures.syncRequest(device: device, tracks: tracks)
        let job = DeviceSyncFixtures.syncJob(request: request, status: .queued)
        await queue.enqueue(job)
        
        // When: Create new manager instance
        let newManager = DeviceSyncManager(
            discovery: discovery,
            connector: connector,
            queue: queue,
            conflictDetector: conflictDetector
        )
        await newManager.restoreJobsFromQueue()
        
        // Then: Jobs should be restored
        let jobs = await newManager.jobs()
        XCTAssertEqual(jobs.count, 1)
        XCTAssertEqual(jobs.first?.id, job.id)
    }
    
    func testGivenJobsInProgressWhenAppRestartsThenJobsResumeProcessing() async throws {
        // Given: Job in progress in persistent queue
        let device = DeviceSyncFixtures.usbDevice()
        await discovery.setDevices([device])
        let tracks = DeviceSyncFixtures.tracks(count: 2)
        let request = DeviceSyncFixtures.syncRequest(device: device, tracks: tracks)
        var job = DeviceSyncFixtures.syncJob(request: request, status: .syncing)
        job.progress = SyncProgress(completed: 1, total: 2)
        await queue.enqueue(job)
        
        // When: Create new manager and restore
        manager = DeviceSyncManager(
            discovery: discovery,
            connector: connector,
            queue: queue,
            conflictDetector: conflictDetector
        )
        await manager.restoreJobsFromQueue()
        
        // Then: Job should be in manager's storage
        let jobs = await manager.jobs()
        XCTAssertEqual(jobs.count, 1)
        XCTAssertEqual(jobs.first?.status, .syncing)
        XCTAssertEqual(jobs.first?.progress.completed, 1)
    }
    
    func testGivenMultipleJobsWhenAppRestartsThenAllJobsAreRestored() async throws {
        // Given: Multiple jobs in persistent queue
        let testJobs = try await createTestJobs()
        _ = try await prepareQueueWithJobs(jobs: testJobs)
        
        // When: Create new manager and restore
        await recreateManagerAndRestore()
        
        // Then: All jobs should be restored
        try await verifyJobsRestored(jobs: testJobs)
    }
    
    private struct TestJobs {
        let job1: SyncJob
        let job2: SyncJob
        let job3: SyncJob
    }
    
    private func createTestJobs() async throws -> TestJobs {
        let device = DeviceSyncFixtures.usbDevice()
        await discovery.setDevices([device])
        let tracks = DeviceSyncFixtures.tracks(count: 1)
        
        let job1 = DeviceSyncFixtures.syncJob(
            request: DeviceSyncFixtures.syncRequest(device: device, tracks: tracks),
            status: .queued
        )
        let job2 = DeviceSyncFixtures.syncJob(
            request: DeviceSyncFixtures.syncRequest(device: device, tracks: tracks),
            status: .syncing
        )
        let job3 = DeviceSyncFixtures.syncJob(
            request: DeviceSyncFixtures.syncRequest(device: device, tracks: tracks),
            status: .waitingForConflictResolution
        )
        XCTAssertNotEqual(job1.id, job2.id)
        XCTAssertNotEqual(job1.id, job3.id)
        XCTAssertNotEqual(job2.id, job3.id)
        return TestJobs(job1: job1, job2: job2, job3: job3)
    }
    
    private func prepareQueueWithJobs(jobs: TestJobs) async throws -> PersistentSyncJobQueue? {
        await queue.clearWaiters()
        await queue.close()
        queue = nil
        
        var enqueueQueue: PersistentSyncJobQueue? = PersistentSyncJobQueue(databaseURL: dbURL)
        await enqueueQueue?.clearWaiters()
        await enqueueQueue?.enqueue(jobs.job1)
        await enqueueQueue?.enqueue(jobs.job2)
        await enqueueQueue?.enqueue(jobs.job3)
        
        let queueSnapshot = await enqueueQueue?.snapshot() ?? []
        XCTAssertEqual(queueSnapshot.count, 3, "Expected 3 jobs in queue")
        
        await enqueueQueue?.close()
        enqueueQueue = nil
        queue = PersistentSyncJobQueue(databaseURL: dbURL)
        return enqueueQueue
    }
    
    private func recreateManagerAndRestore() async {
        manager = DeviceSyncManager(
            discovery: discovery,
            connector: connector,
            queue: queue,
            conflictDetector: conflictDetector
        )
        await manager.restoreJobsFromQueue()
        try? await Task.sleep(nanoseconds: 50_000_000)
        await manager.waitForIdle()
    }
    
    private func verifyJobsRestored(jobs: TestJobs) async throws {
        let restoredJobs = await manager.jobs()
        _ = restoredJobs.map { $0.id }
        XCTAssertEqual(restoredJobs.count, 3, "Expected 3 jobs but got \(restoredJobs.count)")
        XCTAssertTrue(restoredJobs.contains { $0.id == jobs.job1.id }, "Job1 not found")
        XCTAssertTrue(restoredJobs.contains { $0.id == jobs.job2.id }, "Job2 not found")
        XCTAssertTrue(restoredJobs.contains { $0.id == jobs.job3.id }, "Job3 not found")
    }
}
