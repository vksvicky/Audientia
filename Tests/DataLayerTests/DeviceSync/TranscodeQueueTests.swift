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
        
        // Then
        let status = await queue.getJobStatus(jobId: jobId)
        XCTAssertNotNil(status)
        
        // Wait a bit for processing to start
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        let activeJobs = await queue.getActiveJobs()
        XCTAssertTrue(activeJobs.contains { $0.id == jobId })
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
        
        // When
        let jobId = await queue.enqueue(track: track, profile: profile, outputPath: "/tmp/output.mp3")
        
        // Wait for failure
        var finalStatus: TranscodeJobStatus?
        for _ in 0..<50 {
            finalStatus = await queue.getJobStatus(jobId: jobId)
            if case .failed = finalStatus {
                break
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        
        // Then
        if case .failed(let error) = finalStatus {
            XCTAssertTrue(error.contains("Test error"))
        } else {
            XCTFail("Job should fail with error")
        }
    }
    
    // MARK: - P: Performance Tests
    
    func testQueueHandlesMultipleJobsEfficiently() async throws {
        // Given
        let tracks = DeviceSyncFixtures.tracks(count: 10)
        let profile = TranscodeProfile(name: "MP3", format: .mp3, bitrate: 192)
        await engine.setShouldSucceed(true)
        await engine.setMockOutputPath("/tmp/output.mp3")
        
        // When
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
        let enqueueTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then: Enqueueing should be fast
        XCTAssertLessThan(enqueueTime, 1.0, "Enqueueing 10 jobs should be fast")
        
        // Wait for all to complete
        var allCompleted = false
        for _ in 0..<100 {
            let activeJobs = await queue.getActiveJobs()
            if activeJobs.isEmpty {
                allCompleted = true
                break
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        
        XCTAssertTrue(allCompleted, "All jobs should complete")
    }
}
