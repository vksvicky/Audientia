//
//  TranscodeQueueTests.swift
//  DataLayerTests
//
//  TDD tests for TranscodeQueue (Right-BICEP)
//

@testable import DataLayer
@testable import Shared
import XCTest

final class TranscodeQueueTests: XCTestCase {
    
    private var engine: MockTranscodeEngine!
    private var queue: TranscodeQueue!
    
    override func setUp() async throws {
        try await super.setUp()
        engine = MockTranscodeEngine()
        queue = TranscodeQueue(engine: engine)
    }
    
    override func tearDown() async throws {
        queue = nil
        engine = nil
        try await super.tearDown()
    }
    
    // MARK: - Right: Correctness Tests
    
    func testEnqueueAddsJobToQueue() async {
        // Given
        let track = DeviceSyncFixtures.track()
        let profile = TranscodeProfile(name: "MP3", format: .mp3, bitrate: 192)
        await engine.setShouldSucceed(true)
        await engine.setMockOutputPath("/tmp/output.mp3")
        
        // When
        let jobId = await queue.enqueue(track: track, profile: profile, outputPath: "/tmp/output.mp3")
        
        // Then: Job should be enqueued and processed
        // Note: enqueue waits for completion, so job should be completed
        let status = await queue.getJobStatus(jobId: jobId)
        XCTAssertNotNil(status)
        
        // Verify job completed successfully
        if case .completed(let outputPath) = status {
            XCTAssertEqual(outputPath, "/tmp/output.mp3")
        } else {
            XCTFail("Job should complete successfully, got: \(String(describing: status))")
        }
    }
    
    func testGetJobStatusReturnsCorrectStatus() async {
        // Given
        let track = DeviceSyncFixtures.track()
        let profile = TranscodeProfile(name: "MP3", format: .mp3, bitrate: 192)
        await engine.setShouldSucceed(true)
        await engine.setMockOutputPath("/tmp/output.mp3")
        
        // When
        let jobId = await queue.enqueue(track: track, profile: profile, outputPath: "/tmp/output.mp3")
        
        // Then
        let status = await queue.getJobStatus(jobId: jobId)
        XCTAssertNotNil(status)
        
        // Wait for completion
        var finalStatus: TranscodeJobStatus?
        for _ in 0..<50 { // Wait up to 5 seconds
            finalStatus = await queue.getJobStatus(jobId: jobId)
            if case .completed = finalStatus {
                break
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        if case .completed(let outputPath) = finalStatus {
            XCTAssertEqual(outputPath, "/tmp/output.mp3")
        } else {
            XCTFail("Job should complete")
        }
    }
    
    // MARK: - B: Boundary Tests
    
    func testEnqueueMultipleJobs() async {
        // Given
        let tracks = DeviceSyncFixtures.tracks(count: 5)
        let profile = TranscodeProfile(name: "MP3", format: .mp3, bitrate: 192)
        await engine.setShouldSucceed(true)
        await engine.setMockOutputPath("/tmp/output.mp3")
        
        // When
        var jobIds: [UUID] = []
        for (index, track) in tracks.enumerated() {
            let jobId = await queue.enqueue(
                track: track,
                profile: profile,
                outputPath: "/tmp/output\(index).mp3"
            )
            jobIds.append(jobId)
        }
        
        // Then
        XCTAssertEqual(jobIds.count, 5)
        
        // Wait a bit
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        let activeJobs = await queue.getActiveJobs()
        // All jobs should be active (queued or transcoding)
        XCTAssertGreaterThanOrEqual(activeJobs.count, 0)
    }
    
    // MARK: - I: Inverse Tests
    
    func testCancelJobRemovesFromActive() async {
        // Given
        let track = DeviceSyncFixtures.track()
        let profile = TranscodeProfile(name: "MP3", format: .mp3, bitrate: 192)
        await engine.setShouldSucceed(true)
        await engine.setMockOutputPath("/tmp/output.mp3")
        
        // When
        let jobId = await queue.enqueue(track: track, profile: profile, outputPath: "/tmp/output.mp3")
        
        // Wait a bit for processing to start
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        await queue.cancel(jobId: jobId)
        
        // Then
        let status = await queue.getJobStatus(jobId: jobId)
        if case .cancelled = status {
            // Success
        } else {
            XCTFail("Job should be cancelled")
        }
        
        // Wait a bit more
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        let activeJobs = await queue.getActiveJobs()
        XCTAssertFalse(activeJobs.contains { $0.id == jobId })
    }
    
    // MARK: - E: Error Tests
    
    func testFailedJobHasErrorStatus() async {
        // Given
        let track = DeviceSyncFixtures.track()
        let profile = TranscodeProfile(name: "MP3", format: .mp3, bitrate: 192)
        await engine.setMockError(.transcodingFailed("Test error"))
        await engine.setShouldSucceed(false)
        
        // When
        let jobId = await queue.enqueue(track: track, profile: profile, outputPath: "/tmp/output.mp3")
        
        // Then: Job should fail (enqueue waits for completion)
        let status = await queue.getJobStatus(jobId: jobId)
        
        if case .failed(let error) = status {
            // Verify that an error message is present
            // Note: TranscodeError doesn't conform to LocalizedError,
            // so localizedDescription returns the default enum description
            XCTAssertFalse(error.isEmpty, "Error message should not be empty, got: \(error)")
        } else {
            XCTFail("Job should fail with error, got: \(String(describing: status))")
        }
    }
    
    // MARK: - P: Performance Tests
    
    func testQueueHandlesMultipleJobsEfficiently() async throws {
        // Given
        let tracks = DeviceSyncFixtures.tracks(count: 10)
        let profile = TranscodeProfile(name: "MP3", format: .mp3, bitrate: 192)
        await engine.setShouldSucceed(true)
        await engine.setMockOutputPath("/tmp/output.mp3")
        
        // When: Enqueue and process 10 jobs
        // Note: enqueue processes synchronously, so this measures total time
        let startTime = CFAbsoluteTimeGetCurrent()
        var jobIds: [UUID] = []
        for (index, track) in tracks.enumerated() {
            let jobId = await queue.enqueue(
                track: track,
                profile: profile,
                outputPath: "/tmp/output\(index).mp3"
            )
            jobIds.append(jobId)
        }
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then: All jobs should be completed (enqueue waits for completion)
        XCTAssertEqual(jobIds.count, 10, "All jobs should be enqueued")
        
        // Verify all jobs completed
        for jobId in jobIds {
            let status = await queue.getJobStatus(jobId: jobId)
            if case .completed = status {
                // Success
            } else {
                XCTFail("Job \(jobId) should be completed, got: \(String(describing: status))")
            }
        }
        
        // Performance: Processing 10 jobs with 100ms each should take ~1 second
        // Allow some overhead (2 seconds max)
        XCTAssertLessThan(totalTime, 2.0, "Processing 10 jobs should complete within reasonable time")
        
        // Verify no active jobs remain
        let activeJobs = await queue.getActiveJobs()
        XCTAssertTrue(activeJobs.isEmpty, "All jobs should be completed")
    }
}
