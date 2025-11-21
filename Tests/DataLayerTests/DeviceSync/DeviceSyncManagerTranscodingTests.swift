//
//  DeviceSyncManagerTranscodingTests.swift
//  DataLayerTests
//
//  TDD tests for transcoding integration with DeviceSyncManager
//

@testable import DataLayer
@testable import Shared
import XCTest

final class DeviceSyncManagerTranscodingTests: XCTestCase {
    
    private var manager: DeviceSyncManager!
    private var mockDiscovery: MockDeviceDiscovery!
    private var mockConnector: MockDeviceConnector!
    private var mockQueue: MockJobQueue!
    private var mockConflictDetector: MockConflictDetector!
    private var mockTranscodeEngine: MockTranscodeEngine!
    private var mockTranscodeQueue: MockTranscodeQueue!
    
    override func setUp() async throws {
        try await super.setUp()
        mockDiscovery = MockDeviceDiscovery()
        mockConnector = MockDeviceConnector()
        mockQueue = MockJobQueue()
        mockConflictDetector = MockConflictDetector()
        mockTranscodeEngine = MockTranscodeEngine()
        mockTranscodeQueue = MockTranscodeQueue()
        
        manager = DeviceSyncManager(
            discovery: mockDiscovery,
            connector: mockConnector,
            queue: mockQueue,
            conflictDetector: mockConflictDetector,
            transcodeEngine: mockTranscodeEngine,
            transcodeQueue: mockTranscodeQueue
        )
    }
    
    override func tearDown() async throws {
        manager = nil
        mockDiscovery = nil
        mockConnector = nil
        mockQueue = nil
        mockConflictDetector = nil
        mockTranscodeEngine = nil
        mockTranscodeQueue = nil
        try await super.tearDown()
    }
    
    // MARK: - Right: Correctness Tests
    
    func testSyncWithTranscodingEnabledTranscodesTracksBeforeTransfer() async throws {
        // Given
        let device = DeviceSyncFixtures.usbDevice()
        let track = DeviceSyncFixtures.track(filePath: "/test.flac")
        let profile = TranscodeProfile(name: "MP3 192kbps", format: .mp3, bitrate: 192)
        
        let request = SyncRequest(
            device: device,
            tracks: [track],
            direction: .desktopToDevice,
            options: SyncOptions(transcodeProfile: profile)
        )
        
        await mockDiscovery.setDevices([device])
        await mockTranscodeEngine.setShouldNeedTranscoding(true)
        await mockTranscodeEngine.setShouldSucceed(true)
        
        // When
        _ = try await manager.startSync(request: request)
        
        // Wait for processing
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        let needsTranscodingCalled = await mockTranscodeEngine.needsTranscodingCalled
        let transcodeCalled = await mockTranscodeEngine.transcodeCalled
        XCTAssertTrue(needsTranscodingCalled)
        XCTAssertTrue(transcodeCalled)
    }
    
    func testSyncWithTranscodingDisabledSkipsTranscoding() async throws {
        // Given
        let device = DeviceSyncFixtures.usbDevice()
        let track = DeviceSyncFixtures.track()
        let request = SyncRequest(
            device: device,
            tracks: [track],
            direction: .desktopToDevice,
            options: SyncOptions() // No transcoding profile
        )
        
        await mockDiscovery.setDevices([device])
        
        // When
        _ = try await manager.startSync(request: request)
        
        // Wait for processing
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        let needsTranscodingCalled = await mockTranscodeEngine.needsTranscodingCalled
        let transcodeCalled = await mockTranscodeEngine.transcodeCalled
        XCTAssertFalse(needsTranscodingCalled)
        XCTAssertFalse(transcodeCalled)
    }
    
    // MARK: - B: Boundary Tests
    
    func testSyncWithAllTracksNeedingTranscoding() async throws {
        // Given
        let device = DeviceSyncFixtures.usbDevice()
        let tracks = (0..<10).map { DeviceSyncFixtures.track(filePath: "/test\($0).flac") }
        let profile = TranscodeProfile(name: "MP3", format: .mp3, bitrate: 192)
        
        let request = SyncRequest(
            device: device,
            tracks: tracks,
            direction: .desktopToDevice,
            options: SyncOptions(transcodeProfile: profile)
        )
        
        await mockDiscovery.setDevices([device])
        await mockTranscodeEngine.setShouldNeedTranscoding(true)
        await mockTranscodeEngine.setShouldSucceed(true)
        
        // When
        let job = try await manager.startSync(request: request)
        
        // Wait for job to complete or fail (with timeout)
        var jobStatus = job.status
        let maxWaitTime: TimeInterval = 5.0
        let startTime = Date()
        
        while jobStatus != .completed && jobStatus != .failed && jobStatus != .cancelled {
            if Date().timeIntervalSince(startTime) > maxWaitTime {
                XCTFail("Job did not complete within \(maxWaitTime) seconds")
                return
            }
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
            let jobs = await manager.jobs()
            if let updatedJob = jobs.first(where: { $0.id == job.id }) {
                jobStatus = updatedJob.status
            }
        }
        
        // Then
        let transcodeCallCount = await mockTranscodeEngine.transcodeCallCount
        XCTAssertEqual(transcodeCallCount, tracks.count, "Expected \(tracks.count) transcoding calls, got \(transcodeCallCount)")
    }
    
    // MARK: - E: Error Tests
    
    func testSyncHandlesTranscodingFailure() async throws {
        // Given
        let device = DeviceSyncFixtures.usbDevice()
        let track = DeviceSyncFixtures.track()
        let profile = TranscodeProfile(name: "MP3", format: .mp3, bitrate: 192)
        
        let request = SyncRequest(
            device: device,
            tracks: [track],
            direction: .desktopToDevice,
            options: SyncOptions(transcodeProfile: profile)
        )
        
        await mockDiscovery.setDevices([device])
        await mockTranscodeEngine.setShouldNeedTranscoding(true)
        await mockTranscodeEngine.setShouldSucceed(false)
        await mockTranscodeEngine.setMockError(.transcodingFailed("Transcoding failed"))
        
        // When
        let job = try await manager.startSync(request: request)
        
        // Wait for processing
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Then
        let updatedJob = await manager.jobs().first { $0.id == job.id }
        XCTAssertEqual(updatedJob?.status, .failed)
        XCTAssertNotNil(updatedJob?.errorDescription)
    }
}
