//
//  DeviceSyncManager.swift
//  DataLayer
//
//  Actor-based orchestration of device sync workflows.
//

import Foundation
import os.log
import Shared

public actor DeviceSyncManager: DeviceSyncManagerProtocol {
    
    // MARK: - Dependencies
    
    private let discovery: DeviceDiscoveryProtocol
    private let connector: DeviceConnectorProtocol
    private let queue: SyncJobQueueProtocol
    private let conflictDetector: SyncConflictDetectorProtocol
    
    // MARK: - State
    
    private var jobsStorage: [UUID: SyncJob] = [:]
    private var jobOrder: [UUID] = []
    private var processorTask: Task<Void, Never>?
    private var idleContinuations: [CheckedContinuation<Void, Never>] = []
    private let logger = Logger.deviceSync
    
    // MARK: - Initialization
    
    public init(
        discovery: DeviceDiscoveryProtocol,
        connector: DeviceConnectorProtocol,
        queue: SyncJobQueueProtocol = InMemorySyncJobQueue(),
        conflictDetector: SyncConflictDetectorProtocol
    ) {
        self.discovery = discovery
        self.connector = connector
        self.queue = queue
        self.conflictDetector = conflictDetector
    }
    
    // MARK: - DeviceSyncManagerProtocol
    
    public func availableDevices() async -> [Device] {
        await discovery.currentDevices()
    }
    
    public func jobs() async -> [SyncJob] {
        jobOrder.compactMap { jobsStorage[$0] }
    }
    
    @discardableResult
    public func startSync(request: SyncRequest) async throws -> SyncJob {
        try await validate(request: request)
        let job = SyncJob(
            request: request,
            status: .queued,
            progress: SyncProgress(completed: 0, total: request.tracks.count)
        )
        jobsStorage[job.id] = job
        jobOrder.append(job.id)
        await queue.enqueue(job)
        logger.info("Queued sync job \(job.id.uuidString, privacy: .public) for device \(request.device.name, privacy: .public)")
        ensureProcessorRunning()
        return job
    }
    
    public func cancel(jobId: UUID) async {
        await queue.remove(jobId: jobId)
        if var job = jobsStorage[jobId] {
            job.status = .cancelled
            jobsStorage[jobId] = job
            logger.info("Cancelled sync job \(jobId.uuidString, privacy: .public)")
        }
        await connector.cancel(jobId: jobId)
    }
    
    @discardableResult
    public func resolveConflicts(jobId: UUID, resolutions: [SyncConflictResolution]) async throws -> SyncJob {
        guard var job = jobsStorage[jobId] else {
            throw DeviceSyncError.deviceNotFound
        }
        
        guard job.status == .waitingForConflictResolution else {
            return job
        }
        
        guard let conflicts = job.conflicts else {
            return job
        }
        
        let unresolved = conflicts.filter { conflict in
            !resolutions.contains(where: { $0.conflictId == conflict.id })
        }
        
        guard unresolved.isEmpty else {
            throw DeviceSyncError.conflictsPending
        }
        
        job.status = .queued
        job.conflicts = nil
        jobsStorage[jobId] = job
        await queue.enqueue(job)
        ensureProcessorRunning()
        return job
    }
    
    public func waitForIdle() async {
        if processorTask == nil, await queue.isEmpty() {
            return
        }
        
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            idleContinuations.append(continuation)
        }
    }
    
    // MARK: - Private
    
    private func ensureProcessorRunning() {
        guard processorTask == nil else { return }
        processorTask = Task { [weak self] in
            await self?.processJobs()
        }
    }
    
    private func processJobs() async {
        defer {
            processorTask = nil
            resumeIdleContinuationsIfNeeded()
        }
        
        while true {
            // Check if queue is empty before attempting to dequeue
            if await queue.isEmpty() {
                break
            }
            
            guard let job = await queue.dequeue() else {
                // Queue became empty between isEmpty() check and dequeue()
                break
            }
            
            guard var currentJob = jobsStorage[job.id], currentJob.status != .cancelled else {
                continue
            }
            
            await processJob(&currentJob)
        }
    }
    
    private func processJob(_ job: inout SyncJob) async {
        do {
            job.status = .analyzing
            jobsStorage[job.id] = job
            
            let deviceTracks = try await connector.fetchDeviceTracks(device: job.request.device)
            let conflicts = await conflictDetector.detectConflicts(job: job, deviceTracks: deviceTracks)
            
            if !conflicts.isEmpty, job.request.options.autoResolveConflicts == false {
                job.status = .waitingForConflictResolution
                job.conflicts = conflicts
                jobsStorage[job.id] = job
                return
            }
            
            job.status = .syncing
            job.conflicts = conflicts.isEmpty ? nil : conflicts
            jobsStorage[job.id] = job
            
            let jobId = job.id
            try await connector.transfer(
                tracks: job.request.tracks,
                to: job.request.device,
                jobId: jobId
            ) { [weak self] progress in
                Task {
                    await self?.updateProgress(jobId: jobId, progress: progress)
                }
            }
            
            job.status = .completed
            job.progress = SyncProgress(completed: job.request.tracks.count, total: job.request.tracks.count)
            jobsStorage[job.id] = job
            logger.info("Completed sync job \(jobId.uuidString, privacy: .public)")
        } catch is CancellationError {
            job.status = .cancelled
            jobsStorage[job.id] = job
        } catch let error as DeviceSyncError {
            job.status = .failed
            job.errorDescription = error.localizedDescription
            jobsStorage[job.id] = job
        } catch {
            job.status = .failed
            job.errorDescription = error.localizedDescription
            jobsStorage[job.id] = job
        }
    }
    
    private func updateProgress(jobId: UUID, progress: SyncProgress) async {
        guard var job = jobsStorage[jobId] else { return }
        job.progress = progress
        jobsStorage[jobId] = job
    }
    
    private func resumeIdleContinuationsIfNeeded() {
        guard idleContinuations.isEmpty == false else { return }
        idleContinuations.forEach { $0.resume(returning: ()) }
        idleContinuations.removeAll()
    }
    
    private func validate(request: SyncRequest) async throws {
        let devices = await discovery.currentDevices()
        guard devices.contains(where: { $0.id == request.device.id }) else {
            throw DeviceSyncError.deviceNotFound
        }
        
        if request.options.enforceFreeSpace {
            let requiredBytes = request.tracks.reduce(into: Int64(0)) { subtotal, track in
                subtotal += track.fileSize
            }
            if requiredBytes > request.device.availableSpace {
                throw DeviceSyncError.insufficientSpace
            }
        }
    }
}
