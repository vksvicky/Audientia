//
//  MockDeviceSyncManager.swift
//  UITests
//
//  Mock implementation of DeviceSyncManagerProtocol for UI tests.
//

import Foundation

@testable import DataLayer
@testable import Shared

actor MockDeviceSyncManager: DeviceSyncManagerProtocol {
    private var devices: [Device] = []
    private var jobsList: [SyncJob] = []
    private var shouldThrowOnStart = false
    private var startSyncError: Error = DeviceSyncError.deviceNotFound
    private(set) var startSyncRequests: [SyncRequest] = []
    
    func availableDevices() async -> [Device] {
        devices
    }
    
    func jobs() async -> [SyncJob] {
        jobsList
    }
    
    func startSync(request: SyncRequest) async throws -> SyncJob {
        if shouldThrowOnStart {
            throw startSyncError
        }
        startSyncRequests.append(request)
        var job = SyncJob(request: request, status: .queued, progress: SyncProgress(completed: 0, total: request.tracks.count))
        job.progress = SyncProgress(completed: 0, total: request.tracks.count)
        jobsList.append(job)
        return job
    }
    
    func cancel(jobId: UUID) async {
        if let index = jobsList.firstIndex(where: { $0.id == jobId }) {
            jobsList[index].status = .cancelled
        }
    }
    
    func resolveConflicts(jobId: UUID, resolutions: [SyncConflictResolution]) async throws -> SyncJob {
        guard let index = jobsList.firstIndex(where: { $0.id == jobId }) else {
            throw DeviceSyncError.deviceNotFound
        }
        jobsList[index].status = .queued
        return jobsList[index]
    }
    
    func waitForIdle() async {}

    // MARK: - Test Helpers
    
    func setDevices(_ devices: [Device]) {
        self.devices = devices
    }
    
    func setJobs(_ jobs: [SyncJob]) {
        jobsList = jobs
    }
    
    func configureStartSyncFailure(shouldFail: Bool, error: Error = DeviceSyncError.deviceNotFound) {
        shouldThrowOnStart = shouldFail
        startSyncError = error
    }
}
