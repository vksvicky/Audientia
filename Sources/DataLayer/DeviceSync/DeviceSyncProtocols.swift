//
//  DeviceSyncProtocols.swift
//  DataLayer
//
//  Protocol definitions for Device Sync components
//

import Foundation
import Shared

// MARK: - Discovery

public protocol DeviceDiscoveryProtocol: Sendable {
    func currentDevices() async -> [Device]
}

// MARK: - Connector

public protocol DeviceConnectorProtocol: Sendable {
    func fetchDeviceTracks(device: Device) async throws -> [DeviceTrackSnapshot]
    func transfer(
        tracks: [Track],
        to device: Device,
        jobId: UUID,
        options: SyncOptions,
        progress: @escaping (SyncProgress) -> Void
    ) async throws
    func cancel(jobId: UUID) async
}

// MARK: - Job Queue

public protocol SyncJobQueueProtocol: Sendable {
    func enqueue(_ job: SyncJob) async
    func dequeue() async -> SyncJob?
    func remove(jobId: UUID) async
    func isEmpty() async -> Bool
    func snapshot() async -> [SyncJob]
}

// MARK: - Conflict Detector

public protocol SyncConflictDetectorProtocol: Sendable {
    func detectConflicts(job: SyncJob, deviceTracks: [DeviceTrackSnapshot]) async -> [SyncConflict]
}

// MARK: - Device Sync Manager API

public protocol DeviceSyncManagerProtocol: AnyObject, Sendable {
    func availableDevices() async -> [Device]
    func jobs() async -> [SyncJob]
    func startSync(request: SyncRequest) async throws -> SyncJob
    func cancel(jobId: UUID) async
    func resolveConflicts(jobId: UUID, resolutions: [SyncConflictResolution]) async throws -> SyncJob
    func waitForIdle() async
}
