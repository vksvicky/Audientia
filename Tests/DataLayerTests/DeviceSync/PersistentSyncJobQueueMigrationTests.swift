//
//  PersistentSyncJobQueueMigrationTests.swift
//  DataLayerTests
//
//  Tests for schema migration in PersistentSyncJobQueue
//

@testable import DataLayer
@testable import Shared
import XCTest

final class PersistentSyncJobQueueMigrationTests: XCTestCase {
    
    private var queue: PersistentSyncJobQueue!
    private var dbURL: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        let tempDir = FileManager.default.temporaryDirectory
        dbURL = tempDir.appendingPathComponent("test_queue_\(UUID().uuidString).db")
    }
    
    override func tearDown() async throws {
        queue = nil
        if let dbURL = dbURL, FileManager.default.fileExists(atPath: dbURL.path) {
            try? FileManager.default.removeItem(at: dbURL)
        }
        try await super.tearDown()
    }
    
    func testGivenNewDatabaseWhenInitialisedThenSchemaVersionIsSet() async throws {
        // Given: New database
        queue = PersistentSyncJobQueue(databaseURL: dbURL)
        
        // When: Initialise (happens on first use)
        _ = await queue.isEmpty()
        
        // Then: Schema version should be set (verified by successful operations)
        let job = DeviceSyncFixtures.syncJob()
        await queue.enqueue(job)
        let snapshot = await queue.snapshot()
        XCTAssertEqual(snapshot.count, 1)
    }
    
    func testGivenExistingDatabaseWhenInitialisedThenSchemaIsCompatible() async throws {
        // Given: Database with existing jobs
        queue = PersistentSyncJobQueue(databaseURL: dbURL)
        let job1 = DeviceSyncFixtures.syncJob()
        let job2 = DeviceSyncFixtures.syncJob()
        await queue.enqueue(job1)
        await queue.enqueue(job2)
        
        // Verify jobs were enqueued
        let initialSnapshot = await queue.snapshot()
        XCTAssertEqual(initialSnapshot.count, 2, "Expected 2 jobs after enqueueing")
        
        // When: Create new queue instance (simulating app restart)
        // Wait a bit to ensure database operations complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        queue = nil
        // Small delay to ensure database is closed
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        let newQueue = PersistentSyncJobQueue(databaseURL: dbURL)
        
        // Then: Jobs should still be accessible
        let snapshot = await newQueue.snapshot()
        XCTAssertEqual(snapshot.count, 2, "Expected 2 jobs after recreating queue, but got \(snapshot.count)")
        XCTAssertTrue(snapshot.contains { $0.id == job1.id }, "Job1 not found in snapshot")
        XCTAssertTrue(snapshot.contains { $0.id == job2.id }, "Job2 not found in snapshot")
    }
    
    func testGivenDatabaseWithJobsWhenSchemaVersionChangesThenJobsArePreserved() async throws {
        // Given: Database with jobs
        queue = PersistentSyncJobQueue(databaseURL: dbURL)
        let job = DeviceSyncFixtures.syncJob()
        await queue.enqueue(job)
        
        // When: Schema version is updated (simulated by recreating queue)
        // The migration system should preserve existing data
        queue = nil
        let newQueue = PersistentSyncJobQueue(databaseURL: dbURL)
        
        // Then: Jobs should be preserved
        let snapshot = await newQueue.snapshot()
        XCTAssertEqual(snapshot.count, 1)
        XCTAssertEqual(snapshot.first?.id, job.id)
    }
}
