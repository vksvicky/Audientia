//
//  DeviceSyncManagerBDDTests.swift
//  DataLayerTests
//
//  BDD scenarios for Device Sync feature 4.1
//

@testable import DataLayer
@testable import Shared
import XCTest

final class DeviceSyncManagerBDDTests: XCTestCase {
    
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
    
    func testGivenUsbDriveWhenSyncRequestedThenProgressReachesHundredPercent() async throws {
        // Given
        let device = DeviceSyncFixtures.usbDevice(name: "Studio Drive")
        await discovery.setDevices([device])
        let tracks = DeviceSyncFixtures.tracks(count: 10)
        let request = DeviceSyncFixtures.syncRequest(device: device, tracks: tracks)
        
        // When
        let job = try await manager.startSync(request: request)
        await manager.waitForIdle()
        
        // Then
        let jobs = await manager.jobs()
        let completedJob = try XCTUnwrap(jobs.first { $0.id == job.id })
        XCTAssertEqual(completedJob.status, .completed)
        XCTAssertEqual(completedJob.progress.percentage, 1.0, accuracy: 0.001)
    }
    
    func testGivenDeviceDisconnectsWhenSyncingThenUserSeesError() async throws {
        // Given
        let device = DeviceSyncFixtures.usbDevice()
        await discovery.setDevices([device])
        await connector.setTransferDelay(0.05)
        let request = DeviceSyncFixtures.syncRequest(device: device)
        await connector.setShouldThrowTransferError(true)
        await connector.setTransferError(DeviceSyncError.deviceDisconnected)
        
        // When
        let job = try await manager.startSync(request: request)
        await manager.waitForIdle()
        
        // Then
        let jobs = await manager.jobs()
        let failedJob = try XCTUnwrap(jobs.first { $0.id == job.id })
        XCTAssertEqual(failedJob.status, .failed)
        XCTAssertEqual(failedJob.errorDescription, DeviceSyncError.deviceDisconnected.localizedDescription)
    }
    
    func testGivenInsufficientSpaceWhenSyncingThenJobFailsGracefully() async {
        // Given
        var device = DeviceSyncFixtures.usbDevice()
        device.availableSpace = 1 // Force insufficient space
        await discovery.setDevices([device])
        let tracks = DeviceSyncFixtures.tracks(count: 5)
        let request = DeviceSyncFixtures.syncRequest(
            device: device,
            tracks: tracks,
            options: .init(autoResolveConflicts: true, enforceFreeSpace: true)
        )
        
        // When & Then: startSync should throw immediately during validation
        do {
            _ = try await manager.startSync(request: request)
            XCTFail("Expected startSync to throw DeviceSyncError.insufficientSpace")
        } catch let error as DeviceSyncError {
            XCTAssertEqual(error, .insufficientSpace, "Should throw insufficientSpace error during validation")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
