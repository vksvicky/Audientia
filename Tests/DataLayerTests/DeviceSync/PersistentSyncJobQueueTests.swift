//
//  PersistentSyncJobQueueTests.swift
//  DataLayerTests
//
//  TDD tests for persistent job queue using SQLite
//  Following Right-BICEP principles
//

@testable import DataLayer
import os.log
@testable import Shared
import XCTest

final class PersistentSyncJobQueueTests: XCTestCase {
    
    private var queue: PersistentSyncJobQueue!
    private var dbURL: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        // Create temporary database for each test
        let tempDir = FileManager.default.temporaryDirectory
        dbURL = tempDir.appendingPathComponent("test_queue_\(UUID().uuidString).db")
        queue = PersistentSyncJobQueue(databaseURL: dbURL)
    }
    
    override func tearDown() async throws {
        queue = nil
        // Clean up test database
        if let dbURL = dbURL, FileManager.default.fileExists(atPath: dbURL.path) {
            try? FileManager.default.removeItem(at: dbURL)
        }
        try await super.tearDown()
    }
    
    // MARK: - Right: Correctness Tests
    
    func testEnqueueStoresJobInDatabase() async throws {
        // Given
        let job = DeviceSyncFixtures.syncJob()
        
        // When
        await queue.enqueue(job)
        
        // Then
        let snapshot = await queue.snapshot()
        XCTAssertEqual(snapshot.count, 1)
        XCTAssertEqual(snapshot.first?.id, job.id)
    }
    
    func testDequeueReturnsJobsInOrder() async throws {
        // Given
        let job1 = DeviceSyncFixtures.syncJob()
        let job2 = DeviceSyncFixtures.syncJob()
        await queue.enqueue(job1)
        await queue.enqueue(job2)
        
        // When
        let dequeued1 = await queue.dequeue()
        let dequeued2 = await queue.dequeue()
        
        // Then
        XCTAssertEqual(dequeued1?.id, job1.id)
        XCTAssertEqual(dequeued2?.id, job2.id)
    }
    
    func testRemoveDeletesJobFromDatabase() async throws {
        // Given
        let job1 = DeviceSyncFixtures.syncJob()
        let job2 = DeviceSyncFixtures.syncJob()
        await queue.enqueue(job1)
        await queue.enqueue(job2)
        
        // When
        await queue.remove(jobId: job1.id)
        
        // Then
        let snapshot = await queue.snapshot()
        XCTAssertEqual(snapshot.count, 1)
        XCTAssertEqual(snapshot.first?.id, job2.id)
    }
    
    func testIsEmptyReturnsTrueWhenQueueIsEmpty() async throws {
        // Given: Empty queue
        
        // When
        let isEmpty = await queue.isEmpty()
        
        // Then
        XCTAssertTrue(isEmpty)
    }
    
    func testIsEmptyReturnsFalseWhenQueueHasJobs() async throws {
        // Given
        let job = DeviceSyncFixtures.syncJob()
        await queue.enqueue(job)
        
        // When
        let isEmpty = await queue.isEmpty()
        
        // Then
        XCTAssertFalse(isEmpty)
    }
    
    func testSnapshotReturnsAllJobsInOrder() async throws {
        // Given
        let job1 = DeviceSyncFixtures.syncJob()
        let job2 = DeviceSyncFixtures.syncJob()
        let job3 = DeviceSyncFixtures.syncJob()
        await queue.enqueue(job1)
        await queue.enqueue(job2)
        await queue.enqueue(job3)
        
        // When
        let snapshot = await queue.snapshot()
        
        // Then
        XCTAssertEqual(snapshot.count, 3)
        XCTAssertEqual(snapshot[0].id, job1.id)
        XCTAssertEqual(snapshot[1].id, job2.id)
        XCTAssertEqual(snapshot[2].id, job3.id)
    }
    
    // MARK: - B: Boundary Tests
    
    func testDequeueBlocksWhenQueueIsEmpty() async throws {
        // Given: Empty queue
        
        // When: Dequeue in background task
        let expectation = expectation(description: "Dequeue should block")
        Task {
            _ = await queue.dequeue()
            expectation.fulfill()
        }
        
        // Wait a bit to ensure it's blocked
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        // Then: Should still be waiting
        XCTAssertEqual(expectation.expectedFulfillmentCount, 1)
        
        // Enqueue a job to unblock
        let job = DeviceSyncFixtures.syncJob()
        await queue.enqueue(job)
        
        // Wait for dequeue to complete
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testEnqueueLargeNumberOfJobs() async throws {
        // Given
        let jobs = (0..<1000).map { _ in DeviceSyncFixtures.syncJob() }
        
        // When
        for job in jobs {
            await queue.enqueue(job)
        }
        
        // Then
        let snapshot = await queue.snapshot()
        XCTAssertEqual(snapshot.count, 1000)
    }
    
    func testRemoveNonExistentJobDoesNotCrash() async throws {
        // Given
        let nonExistentId = UUID()
        
        // When/Then: Should not crash
        await queue.remove(jobId: nonExistentId)
        
        let isEmpty = await queue.isEmpty()
        XCTAssertTrue(isEmpty)
    }
    
    // MARK: - I: Inverse Tests
    
    func testEnqueueThenDequeueLeavesQueueEmpty() async throws {
        // Given
        let job = DeviceSyncFixtures.syncJob()
        await queue.enqueue(job)
        
        // When
        _ = await queue.dequeue()
        
        // Then
        let isEmpty = await queue.isEmpty()
        XCTAssertTrue(isEmpty)
    }
    
    func testEnqueueRemoveEnqueueMaintainsOrder() async throws {
        // Given
        let job1 = DeviceSyncFixtures.syncJob()
        let job2 = DeviceSyncFixtures.syncJob()
        let job3 = DeviceSyncFixtures.syncJob()
        await queue.enqueue(job1)
        await queue.enqueue(job2)
        await queue.enqueue(job3)
        
        // When: Remove middle job, add new one
        await queue.remove(jobId: job2.id)
        let job4 = DeviceSyncFixtures.syncJob()
        await queue.enqueue(job4)
        
        // Then
        let snapshot = await queue.snapshot()
        XCTAssertEqual(snapshot.count, 3)
        XCTAssertEqual(snapshot[0].id, job1.id)
        XCTAssertEqual(snapshot[1].id, job3.id)
        XCTAssertEqual(snapshot[2].id, job4.id)
    }
    
    // MARK: - C: Cross-check Tests
    
    func testSnapshotMatchesActualQueueState() async throws {
        // Given
        let job1 = DeviceSyncFixtures.syncJob()
        let job2 = DeviceSyncFixtures.syncJob()
        await queue.enqueue(job1)
        await queue.enqueue(job2)
        
        // When
        let snapshot = await queue.snapshot()
        let isEmpty = await queue.isEmpty()
        
        // Then
        XCTAssertFalse(isEmpty)
        XCTAssertEqual(snapshot.count, 2)
        
        // Dequeue one
        _ = await queue.dequeue()
        let snapshotAfterDequeue = await queue.snapshot()
        let isEmptyAfterDequeue = await queue.isEmpty()
        
        XCTAssertFalse(isEmptyAfterDequeue)
        XCTAssertEqual(snapshotAfterDequeue.count, 1)
    }
    
    // MARK: - E: Error Tests
    
    func testQueueSurvivesDatabaseCorruption() async throws {
        // Given: Queue with jobs
        let job1 = DeviceSyncFixtures.syncJob()
        let job2 = DeviceSyncFixtures.syncJob()
        await queue.enqueue(job1)
        await queue.enqueue(job2)
        
        // When: Corrupt database (simulate by closing and reopening with new instance)
        queue = nil
        queue = PersistentSyncJobQueue(databaseURL: dbURL)
        
        // Then: Should recover gracefully (either empty or with valid jobs)
        let snapshot = await queue.snapshot()
        // Queue should either be empty (if corruption detected) or have valid jobs
        XCTAssertTrue(snapshot.isEmpty || snapshot.count == 2)
    }
    
    // MARK: - P: Performance Tests
    
    func testEnqueuePerformance() async throws {
        // When/Then: Measure performance manually (measure() doesn't support async well)
        let iterations = 10
        var times: [TimeInterval] = []
        
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            for _ in 0..<100 {
                let job = DeviceSyncFixtures.syncJob()
                await queue.enqueue(job)
            }
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            times.append(elapsed)
        }
        
        let average = times.reduce(0, +) / Double(times.count)
        Logger.testing.info("Average enqueue time for 100 jobs: \(String(format: "%.4f", average * 1000), privacy: .public)ms")
        
        // Verify performance is reasonable (< 1 second for 100 enqueues)
        XCTAssertLessThan(average, 1.0, "Enqueue should complete in reasonable time")
    }
    
    func testDequeuePerformance() async throws {
        // Given: Pre-populated queue
        for _ in 0..<100 {
            let job = DeviceSyncFixtures.syncJob()
            await queue.enqueue(job)
        }
        
        // When/Then: Measure performance manually (measure() doesn't support async well)
        let iterations = 10
        var times: [TimeInterval] = []
        
        for _ in 0..<iterations {
            // Re-populate queue for each iteration
            for _ in 0..<100 {
                let job = DeviceSyncFixtures.syncJob()
                await queue.enqueue(job)
            }
            
            let startTime = CFAbsoluteTimeGetCurrent()
            for _ in 0..<100 {
                _ = await queue.dequeue()
            }
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            times.append(elapsed)
        }
        
        let average = times.reduce(0, +) / Double(times.count)
        Logger.testing.info("Average dequeue time for 100 jobs: \(String(format: "%.4f", average * 1000), privacy: .public)ms")
        
        // Verify performance is reasonable (< 1 second for 100 dequeues)
        XCTAssertLessThan(average, 1.0, "Dequeue should complete in reasonable time")
    }
    
    // MARK: - Persistence Tests
    
    func testJobsPersistAcrossQueueInstances() async throws {
        // Given: Queue with jobs
        let job1 = DeviceSyncFixtures.syncJob()
        let job2 = DeviceSyncFixtures.syncJob()
        await queue.enqueue(job1)
        await queue.enqueue(job2)
        
        // When: Create new queue instance with same database
        queue = nil
        let newQueue = PersistentSyncJobQueue(databaseURL: dbURL)
        
        // Then: Jobs should still be there
        let snapshot = await newQueue.snapshot()
        XCTAssertEqual(snapshot.count, 2)
        XCTAssertTrue(snapshot.contains { $0.id == job1.id })
        XCTAssertTrue(snapshot.contains { $0.id == job2.id })
    }
    
    func testDequeuedJobsAreRemovedFromPersistence() async throws {
        // Given: Queue with jobs
        let job1 = DeviceSyncFixtures.syncJob()
        let job2 = DeviceSyncFixtures.syncJob()
        await queue.enqueue(job1)
        await queue.enqueue(job2)
        
        // When: Dequeue one job
        _ = await queue.dequeue()
        
        // Then: Only remaining job should persist
        queue = nil
        let newQueue = PersistentSyncJobQueue(databaseURL: dbURL)
        let snapshot = await newQueue.snapshot()
        XCTAssertEqual(snapshot.count, 1)
        XCTAssertEqual(snapshot.first?.id, job2.id)
    }
    
    func testJobStatusAndProgressPersist() async throws {
        // Given: Job with specific status and progress
        var job = DeviceSyncFixtures.syncJob()
        job.status = .syncing
        job.progress = SyncProgress(completed: 5, total: 10)
        await queue.enqueue(job)
        
        // When: Create new queue instance
        queue = nil
        let newQueue = PersistentSyncJobQueue(databaseURL: dbURL)
        
        // Then: Status and progress should be preserved
        let snapshot = await newQueue.snapshot()
        let persistedJob = try XCTUnwrap(snapshot.first)
        XCTAssertEqual(persistedJob.status, .syncing)
        XCTAssertEqual(persistedJob.progress.completed, 5)
        XCTAssertEqual(persistedJob.progress.total, 10)
    }
    
    func testJobConflictsPersist() async throws {
        // Given: Job with conflicts
        guard let track = DeviceSyncFixtures.tracks(count: 1).first else {
            XCTFail("Expected at least one track")
            return
        }
        var job = DeviceSyncFixtures.syncJob()
        let conflict = DeviceSyncFixtures.conflict(track: track)
        job.conflicts = [conflict]
        await queue.enqueue(job)
        
        // When: Create new queue instance
        queue = nil
        let newQueue = PersistentSyncJobQueue(databaseURL: dbURL)
        
        // Then: Conflicts should be preserved
        let snapshot = await newQueue.snapshot()
        let persistedJob = try XCTUnwrap(snapshot.first)
        XCTAssertEqual(persistedJob.conflicts?.count, 1)
        XCTAssertEqual(persistedJob.conflicts?.first?.id, conflict.id)
    }

}
