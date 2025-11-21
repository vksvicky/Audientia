//
//  DeviceSyncManagerTests.swift
//  DataLayerTests
//
//  TDD coverage for DeviceSyncManager
//

import XCTest

@testable import DataLayer
@testable import Shared

final class DeviceSyncManagerTests: XCTestCase {
    
    private var discovery: MockDeviceDiscovery!
    private var connector: MockDeviceConnector!
    private var queue: MockJobQueue!
    private var conflictDetector: MockConflictDetector!
    private var manager: DeviceSyncManager!
    
    override func setUp() {
        super.setUp()
        discovery = MockDeviceDiscovery()
        connector = MockDeviceConnector()
        queue = MockJobQueue()
        conflictDetector = MockConflictDetector()
        manager = DeviceSyncManager(
            discovery: discovery,
            connector: connector,
            queue: queue,
            conflictDetector: conflictDetector
        )
    }
    
    override func tearDown() async throws {
        discovery = nil
        connector = nil
        queue = nil
        conflictDetector = nil
        manager = nil
        try await super.tearDown()
    }
    
    func testStartSyncQueuesJobAndCompletes() async throws {
        // Given
        let device = DeviceSyncFixtures.usbDevice()
        await discovery.setDevices([device])
        let tracks = DeviceSyncFixtures.tracks(count: 5)
        let request = DeviceSyncFixtures.syncRequest(device: device, tracks: tracks)
        
        // When
        let job = try await manager.startSync(request: request)
        XCTAssertEqual(job.status, .queued)
        
        await manager.waitForIdle()
        let jobs = await manager.jobs()
        let updatedJob = try XCTUnwrap(jobs.first { $0.id == job.id })
        
        // Then
        XCTAssertEqual(updatedJob.status, .completed)
        XCTAssertEqual(updatedJob.progress.completed, tracks.count)
        let transferredJobIds = await connector.transferredJobIds()
        XCTAssertEqual(transferredJobIds, [job.id])
    }
    
    func testConflictsPauseJobUntilResolved() async throws {
        // Given
        let device = DeviceSyncFixtures.usbDevice()
        await discovery.setDevices([device])
        let tracks = DeviceSyncFixtures.tracks(count: 3)
        guard let firstTrack = tracks.first else {
            XCTFail("Expected at least one track")
            return
        }
        let request = DeviceSyncFixtures.syncRequest(device: device, tracks: tracks, options: .init(autoResolveConflicts: false))
        let conflict = DeviceSyncFixtures.conflict(track: firstTrack)
        await conflictDetector.setConflicts([conflict])
        
        // When
        let job = try await manager.startSync(request: request)
        
        // Wait for job to be processed - it should transition from queued -> analyzing -> waitingForConflictResolution
        // Poll until we see the waitingForConflictResolution status
        let waitingJob = try await waitForJobStatus(job.id, expectedStatus: SyncJobStatus.waitingForConflictResolution)
        
        // Then
        XCTAssertEqual(waitingJob.status, SyncJobStatus.waitingForConflictResolution, "Job should be waiting for conflict resolution")
        XCTAssertEqual(waitingJob.conflicts?.count, 1, "Job should have one conflict")
        
        // When: Resolve conflicts
        let resolution = SyncConflictResolution(conflictId: conflict.id, action: .keepLibraryVersion)
        let resumedJob = try await manager.resolveConflicts(jobId: job.id, resolutions: [resolution])
        XCTAssertEqual(resumedJob.status, SyncJobStatus.queued, "Job should be re-queued after conflict resolution")
        
        // Clear conflicts from the mock detector so they're not detected again
        await conflictDetector.setConflicts([])
        
        // Wait for the job to complete (processor should pick it up and process it)
        let finalJob = try await waitForJobStatus(job.id, expectedStatus: SyncJobStatus.completed)
        XCTAssertEqual(finalJob.status, SyncJobStatus.completed, "Job should complete after conflicts are resolved")
        
        // Then wait for idle to ensure everything is done
        await manager.waitForIdle()
    }
    
    func testCancellingJobStopsTransfer() async throws {
        // Given
        let device = DeviceSyncFixtures.usbDevice()
        await discovery.setDevices([device])
        let tracks = DeviceSyncFixtures.tracks(count: 2)
        await connector.setTransferDelay(0.2)
        let request = DeviceSyncFixtures.syncRequest(device: device, tracks: tracks)
        
        let job = try await manager.startSync(request: request)
        
        // When
        try await Task.sleep(nanoseconds: 50_000_000)
        await manager.cancel(jobId: job.id)
        await manager.waitForIdle()
        let cancelledJob = try await waitForJob(job.id) { $0.status == .cancelled }
        
        // Then
        XCTAssertEqual(cancelledJob.status, .cancelled)
        let cancelledHistory = await connector.cancelledJobHistory()
        XCTAssertEqual(cancelledHistory, [job.id])
    }
    
    func testTransferFailureMarksJobFailed() async throws {
        // Given
        let device = DeviceSyncFixtures.usbDevice()
        await discovery.setDevices([device])
        let request = DeviceSyncFixtures.syncRequest(device: device)
        await connector.setShouldThrowTransferError(true)
        
        // When
        let job = try await manager.startSync(request: request)
        await manager.waitForIdle()
        
        // Then
        let failedJob = try await waitForJob(job.id) { $0.status == .failed }
        XCTAssertEqual(failedJob.status, .failed)
        XCTAssertEqual(failedJob.errorDescription, "Simulated failure")
    }
    
    func testRightBICEPPerformanceBudget() async throws {
        let device = DeviceSyncFixtures.usbDevice()
        await discovery.setDevices([device])
        let tracks = DeviceSyncFixtures.tracks(count: 50)
        let request = DeviceSyncFixtures.syncRequest(device: device, tracks: tracks)
        
        let start = Date()
        _ = try await manager.startSync(request: request)
        await manager.waitForIdle()
        let elapsed = Date().timeIntervalSince(start)
        
        XCTAssertLessThan(elapsed, 1.0, "Sync of 50 tracks should complete in < 1s in mock environment")
    }
    
    // MARK: - Helpers
    
    private func waitForJobStatus(_ jobId: UUID, expectedStatus: SyncJobStatus) async throws -> SyncJob {
        let start = Date()
        while Date().timeIntervalSince(start) < 2 {
            let jobs = await manager.jobs()
            if let job = jobs.first(where: { $0.id == jobId }) {
                if job.status == expectedStatus {
                    return job
                }
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        // Timeout - check what the actual job status is for debugging
        let jobs = await manager.jobs()
        if let job = jobs.first(where: { $0.id == jobId }) {
            XCTFail("waitForJobStatus timed out waiting for status \(expectedStatus). Job found with status: \(job.status), conflicts: \(job.conflicts?.count ?? 0)")
        } else {
            XCTFail("waitForJobStatus timed out. Job with id \(jobId) not found in jobs list")
        }
        enum WaitError: Error {
            case timedOut
        }
        throw WaitError.timedOut
    }
    
    private func waitForJob(_ jobId: UUID, predicate: @escaping (SyncJob) -> Bool) async throws -> SyncJob {
        let start = Date()
        while Date().timeIntervalSince(start) < 2 {
            let jobs = await manager.jobs()
            if let job = jobs.first(where: { $0.id == jobId }) {
                if predicate(job) {
                return job
                }
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        // Timeout - check what the actual job status is for debugging
        let jobs = await manager.jobs()
        if let job = jobs.first(where: { $0.id == jobId }) {
            XCTFail("waitForJob timed out. Job found with status: \(job.status), conflicts: \(job.conflicts?.count ?? 0)")
        } else {
            XCTFail("waitForJob timed out. Job with id \(jobId) not found in jobs list")
        }
        enum WaitError: Error {
            case timedOut
        }
        throw WaitError.timedOut
    }
}
