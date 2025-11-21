//
//  DeviceSyncViewModel.swift
//  UI
//
//  ViewModel for Device Sync (Feature 4.1)
//

import DataLayer
import Foundation
import os.log
import Shared

@MainActor
public final class DeviceSyncViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published public private(set) var devices: [Device] = []
    @Published public var selectedDevice: Device?
    @Published public private(set) var jobs: [SyncJob] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var lastError: String?
    @Published public private(set) var infoMessage: String?
    
    // MARK: - Dependencies
    
    let manager: DeviceSyncManagerProtocol
    private let logger = Logger.userInterface
    
    // MARK: - Init
    
    public init(manager: DeviceSyncManagerProtocol) {
        self.manager = manager
    }
    
    // MARK: - Public API
    
    public func refreshDevices() async {
        isLoading = true
        defer { isLoading = false }
        let fetched = await manager.availableDevices()
        devices = fetched
        if let selectedDevice, !fetched.contains(where: { $0.id == selectedDevice.id }) {
            self.selectedDevice = fetched.first
        } else if selectedDevice == nil {
            selectedDevice = fetched.first
        }
    }
    
    public func reloadJobs() async {
        jobs = await manager.jobs()
    }
    
    public func startSync(
        tracks: [Track],
        direction: SyncDirection = .desktopToDevice,
        options: SyncOptions = .default
    ) async {
        guard let device = selectedDevice else {
            lastError = "Select a device before starting sync."
            return
        }
        
        lastError = nil
        infoMessage = nil
        
        do {
            let request = SyncRequest(device: device, tracks: tracks, direction: direction, options: options)
            let job = try await manager.startSync(request: request)
            logger.info("Started sync job \(job.id.uuidString, privacy: .public) for \(device.name, privacy: .public)")
            await reloadJobs()
            infoMessage = "Sync started for \(device.name)"
        } catch {
            lastError = error.localizedDescription
            logger.error("Failed to start sync: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    public func cancel(job: SyncJob) async {
        await manager.cancel(jobId: job.id)
        await reloadJobs()
        infoMessage = "Cancelled \(job.request.device.name)"
    }
    
    public func resolve(job: SyncJob, with resolutions: [SyncConflictResolution]) async {
        do {
            _ = try await manager.resolveConflicts(jobId: job.id, resolutions: resolutions)
            await reloadJobs()
            infoMessage = "Conflicts resolved for \(job.request.device.name)"
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    public func clearError() {
        lastError = nil
    }
    
    public func clearMessage() {
        infoMessage = nil
    }
}
