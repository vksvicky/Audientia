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
    private let transcodeEngine: TranscodeEngineProtocol?
    private let transcodeQueue: TranscodeQueueProtocol?
    
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
        conflictDetector: SyncConflictDetectorProtocol,
        transcodeEngine: TranscodeEngineProtocol? = nil,
        transcodeQueue: TranscodeQueueProtocol? = nil
    ) {
        self.discovery = discovery
        self.connector = connector
        self.queue = queue
        self.conflictDetector = conflictDetector
        self.transcodeEngine = transcodeEngine
        self.transcodeQueue = transcodeQueue
    }
    
    // MARK: - Job Restoration
    
    public func restoreJobsFromQueue() async {
        // Get snapshot BEFORE starting processor to ensure we capture all jobs
        let snapshot = await queue.snapshot()
        logger.info("Restoring \(snapshot.count) jobs from queue")
        
        // Add all jobs to storage first, before starting processor
        for job in snapshot {
            // Always update jobsStorage with the restored job, preserving its status
            jobsStorage[job.id] = job
            if !jobOrder.contains(job.id) {
                jobOrder.append(job.id)
            }
        let statusString = String(describing: job.status)
        let jobIdString = job.id.uuidString
        let message = "Restored job \(jobIdString) with status \(statusString)"
        logger.info("\(message, privacy: .public)")
        }
        
        // Resume processing if there are queued jobs
        // Only process jobs that are in a processable state (not waitingForConflictResolution)
        // Note: Jobs are already in jobsStorage, so even if they're dequeued, they'll remain in storage
        if !snapshot.isEmpty {
            ensureProcessorRunning()
        }
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
        logger.info(
            "Queued sync job \(job.id.uuidString, privacy: .public) for device \(request.device.name, privacy: .public)"
        )
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
            
            guard let dequeuedJob = await queue.dequeue() else {
                // Queue became empty between isEmpty() check and dequeue()
                break
            }
            
            // Use the job from jobsStorage (which may have been updated) rather than the dequeued copy
            // This ensures we process jobs with their current state, including restored statuses
            // If job not found in storage, add the dequeued job to storage (shouldn't happen after restoration)
            if jobsStorage[dequeuedJob.id] == nil {
                jobsStorage[dequeuedJob.id] = dequeuedJob
                if !jobOrder.contains(dequeuedJob.id) {
                    jobOrder.append(dequeuedJob.id)
                }
            }
            
            guard var currentJob = jobsStorage[dequeuedJob.id], currentJob.status != .cancelled else {
                // If job is cancelled, skip it but keep it in storage and jobOrder
                continue
            }
            
            // Only process jobs that are ready to be processed
            // Jobs in .waitingForConflictResolution should not be processed until conflicts are resolved
            // They remain in jobsStorage but are not re-enqueued to avoid infinite loops
            if currentJob.status == .waitingForConflictResolution {
                // Skip processing - job will be re-enqueued when conflicts are resolved via resolveConflicts()
                // Job remains in jobsStorage and jobOrder
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
            
            // Transcode tracks if needed
            let tracksToTransfer = try await transcodeTracksIfNeeded(
                tracks: job.request.tracks,
                profile: job.request.options.transcodeProfile,
                jobId: job.id
            )
            
            let jobId = job.id
            try await connector.transfer(
                tracks: tracksToTransfer,
                to: job.request.device,
                jobId: jobId,
                options: job.request.options
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
    
    // MARK: - Transcoding
    
    private func transcodeTracksIfNeeded(
        tracks: [Track],
        profile: TranscodeProfile?,
        jobId: UUID
    ) async throws -> [Track] {
        guard let profile = profile,
              let engine = transcodeEngine else {
            // No transcoding needed or engine not available
            return tracks
        }
        
        var transcodedTracks: [Track] = []
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("transcode_\(jobId.uuidString)")
        
        // Create temp directory
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        for track in tracks {
            // Check if transcoding is needed
            let needsTranscoding = await engine.needsTranscoding(track: track, profile: profile)
            
            if needsTranscoding {
                // Generate output path
                let outputExtension = profile.format.rawValue
                let outputFileName = (track.filePath as NSString).lastPathComponent
                    .replacingOccurrences(of: (track.filePath as NSString).pathExtension, with: outputExtension)
                let outputPath = tempDir.appendingPathComponent(outputFileName).path
                
                // Transcode
                do {
                    let transcodedPath = try await engine.transcode(
                        inputPath: track.filePath,
                        outputPath: outputPath,
                        profile: profile,
                        progress: { _ in } // Progress is tracked at sync level
                    )
                    
                    // Create new track with transcoded path
                    let fileSize = (try? FileManager.default.attributesOfItem(
                        atPath: transcodedPath
                    )[.size] as? Int64) ?? track.fileSize
                    
                    let transcodedTrack = Track(
                        title: track.title,
                        artist: track.artist,
                        album: track.album,
                        duration: track.duration,
                        filePath: transcodedPath,
                        fileSize: fileSize,
                        bitrate: profile.bitrate,
                        sampleRate: profile.sampleRate ?? track.sampleRate
                    )
                    transcodedTracks.append(transcodedTrack)
                } catch {
                    let errorMessage = error.localizedDescription
                    logger.error(
                        "Failed to transcode \(track.filePath, privacy: .public): \(errorMessage, privacy: .public)"
                    )
                    throw DeviceSyncError.transferFailed(
                        "Transcoding failed: \(errorMessage)"
                    )
                }
            } else {
                // No transcoding needed, use original track
                transcodedTracks.append(track)
            }
        }
        
        return transcodedTracks
    }
}
