//
//  MockDeviceSyncDependencies.swift
//  DataLayerTests
//
//  Test doubles for Device Sync
//

import Foundation
import XCTest

@testable import DataLayer
@testable import Shared

// MARK: - Mock Device Discovery

actor MockDeviceDiscovery: DeviceDiscoveryProtocol {
    var devices: [Device] = []
    private(set) var discoverCallCount = 0
    
    func currentDevices() async -> [Device] {
        discoverCallCount += 1
        return devices
    }
    
    func setDevices(_ devices: [Device]) {
        self.devices = devices
    }
}

// MARK: - Mock Device Connector

actor MockDeviceConnector: DeviceConnectorProtocol {
    var deviceSnapshots: [UUID: [DeviceTrackSnapshot]] = [:]
    var transferDelay: TimeInterval = 0.01
    var shouldThrowTransferError = false
    var transferError: Error = DeviceSyncError.transferFailed("Simulated failure")
    private(set) var transferredJobs: [UUID] = []
    private(set) var cancelledJobIds: [UUID] = []
    
    func fetchDeviceTracks(device: Device) async throws -> [DeviceTrackSnapshot] {
        deviceSnapshots[device.id] ?? []
    }
    
    func transfer(
        tracks: [Track],
        to device: Device,
        jobId: UUID,
        progress: @escaping (SyncProgress) -> Void
    ) async throws {
        if shouldThrowTransferError {
            throw transferError
        }
        
        transferredJobs.append(jobId)
        
        let total = max(tracks.count, 1)
        for index in 1...total {
            if cancelledJobIds.contains(jobId) {
                throw CancellationError()
            }
            
            try await Task.sleep(nanoseconds: UInt64(transferDelay * 1_000_000_000))
            progress(SyncProgress(completed: index, total: total))
        }
    }
    
    func cancel(jobId: UUID) async {
        cancelledJobIds.append(jobId)
    }
    
    func setTransferDelay(_ delay: TimeInterval) {
        transferDelay = delay
    }
    
    func setShouldThrowTransferError(_ flag: Bool) {
        shouldThrowTransferError = flag
    }
    
    func setTransferError(_ error: Error) {
        transferError = error
    }
    
    func transferredJobIds() -> [UUID] {
        transferredJobs
    }
    
    func cancelledJobHistory() -> [UUID] {
        cancelledJobIds
    }
}

// MARK: - Mock Job Queue

actor MockJobQueue: SyncJobQueueProtocol {
    private var jobs: [SyncJob] = []
    private var waiters: [CheckedContinuation<SyncJob?, Never>] = []
    
    func enqueue(_ job: SyncJob) async {
        jobs.append(job)
        resumeWaiterIfNeeded()
    }
    
    func dequeue() async -> SyncJob? {
        if !jobs.isEmpty {
            return jobs.removeFirst()
        }
        
        return await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }
    
    func remove(jobId: UUID) async {
        jobs.removeAll { $0.id == jobId }
    }
    
    func snapshot() async -> [SyncJob] {
        jobs
    }
    
    func isEmpty() async -> Bool {
        jobs.isEmpty
    }
    
    private func resumeWaiterIfNeeded() {
        guard !waiters.isEmpty else { return }
        let continuation = waiters.removeFirst()
        let job = jobs.isEmpty ? nil : jobs.removeFirst()
        continuation.resume(returning: job)
    }
}

// MARK: - Mock Conflict Detector

actor MockConflictDetector: SyncConflictDetectorProtocol {
    var conflictsToReturn: [SyncConflict] = []
    private(set) var detectCallCount = 0
    
    func detectConflicts(job: SyncJob, deviceTracks: [DeviceTrackSnapshot]) async -> [SyncConflict] {
        detectCallCount += 1
        return conflictsToReturn
    }
    
    func setConflicts(_ conflicts: [SyncConflict]) {
        conflictsToReturn = conflicts
    }
}
