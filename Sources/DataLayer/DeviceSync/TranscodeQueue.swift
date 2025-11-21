//
//  TranscodeQueue.swift
//  DataLayer
//
//  Background transcoding queue implementation
//

import Foundation
import os.log
import Shared

/// Actor-based background transcoding queue
public actor TranscodeQueue: TranscodeQueueProtocol {
    
    private let engine: TranscodeEngineProtocol
    private var jobs: [UUID: TranscodeJob] = [:]
    private var activeTasks: [UUID: Task<Void, Never>] = [:]
    private let logger = Logger.deviceSync
    
    public init(engine: TranscodeEngineProtocol) {
        self.engine = engine
    }
    
    public func enqueue(track: Track, profile: TranscodeProfile, outputPath: String) async -> UUID {
        let jobId = UUID()
        let job = TranscodeJob(
            id: jobId,
            track: track,
            profile: profile,
            outputPath: outputPath,
            status: .queued
        )
        
        jobs[jobId] = job
        let jobIdString = jobId.uuidString
        let trackTitle = track.title
        let message = "Enqueued transcoding job \(jobIdString) for \(trackTitle)"
        logger.info("\(message, privacy: .public)")
        
        // Start processing immediately
        await processJob(jobId: jobId)
        
        return jobId
    }
    
    public func getJobStatus(jobId: UUID) async -> TranscodeJobStatus? {
        jobs[jobId]?.status
    }
    
    public func cancel(jobId: UUID) async {
        // Cancel the active task
        activeTasks[jobId]?.cancel()
        activeTasks.removeValue(forKey: jobId)
        
        // Update job status
        if var job = jobs[jobId] {
            job = TranscodeJob(
                id: job.id,
                track: job.track,
                profile: job.profile,
                outputPath: job.outputPath,
                status: .cancelled,
                createdAt: job.createdAt
            )
            jobs[jobId] = job
            logger.info("Cancelled transcoding job \(jobId.uuidString, privacy: .public)")
        }
    }
    
    public func getActiveJobs() async -> [TranscodeJob] {
        Array(jobs.values).filter { job in
            if case .queued = job.status {
                true
            } else if case .transcoding = job.status {
                true
            } else {
                false
            }
        }
    }
    
    // MARK: - Private
    
    private func processJob(jobId: UUID) async {
        guard let job = jobs[jobId],
              case .queued = job.status else {
            return
        }
        
        // Update status to transcoding
        var updatedJob = TranscodeJob(
            id: job.id,
            track: job.track,
            profile: job.profile,
            outputPath: job.outputPath,
            status: .transcoding(progress: 0.0),
            createdAt: job.createdAt
        )
        jobs[jobId] = updatedJob
        
        // Create processing task
        let task = Task {
            do {
                var lastProgress: Double = 0.0
                
                let outputPath = try await engine.transcode(
                    inputPath: job.track.filePath,
                    outputPath: job.outputPath,
                    profile: job.profile,
                    progress: { progress in
                        lastProgress = progress
                        // Update job status with progress
                        Task {
                            await self.updateJobProgress(jobId: jobId, progress: progress)
                        }
                    }
                )
                
                // Update to completed
                await self.completeJob(jobId: jobId, outputPath: outputPath)
            } catch {
                await self.failJob(jobId: jobId, error: error)
            }
        }
        
        activeTasks[jobId] = task
        
        // Wait for task to complete (or be cancelled)
        await task.value
        activeTasks.removeValue(forKey: jobId)
    }
    
    private func updateJobProgress(jobId: UUID, progress: Double) async {
        guard var job = jobs[jobId] else { return }
        
        job = TranscodeJob(
            id: job.id,
            track: job.track,
            profile: job.profile,
            outputPath: job.outputPath,
            status: .transcoding(progress: progress),
            createdAt: job.createdAt
        )
        jobs[jobId] = job
    }
    
    private func completeJob(jobId: UUID, outputPath: String) async {
        guard var job = jobs[jobId] else { return }
        
        job = TranscodeJob(
            id: job.id,
            track: job.track,
            profile: job.profile,
            outputPath: outputPath,
            status: .completed(outputPath: outputPath),
            createdAt: job.createdAt
        )
        jobs[jobId] = job
        logger.info("Completed transcoding job \(jobId.uuidString, privacy: .public)")
    }
    
    private func failJob(jobId: UUID, error: Error) async {
        guard var job = jobs[jobId] else { return }
        
        let errorMessage = error.localizedDescription
        job = TranscodeJob(
            id: job.id,
            track: job.track,
            profile: job.profile,
            outputPath: job.outputPath,
            status: .failed(error: errorMessage),
            createdAt: job.createdAt
        )
        jobs[jobId] = job
        logger.error("Failed transcoding job \(jobId.uuidString, privacy: .public): \(errorMessage, privacy: .public)")
    }
}
