//
//  MockTranscodeQueue.swift
//  DataLayerTests
//
//  Mock implementation of TranscodeQueueProtocol for testing
//

import Foundation

@testable import DataLayer
@testable import Shared

actor MockTranscodeQueue: TranscodeQueueProtocol {
    var jobs: [UUID: TranscodeJob] = [:]
    var shouldSucceed = true
    
    func enqueue(track: Track, profile: TranscodeProfile, outputPath: String) async -> UUID {
        let jobId = UUID()
        let job = TranscodeJob(
            id: jobId,
            track: track,
            profile: profile,
            outputPath: outputPath,
            status: .queued
        )
        jobs[jobId] = job
        return jobId
    }
    
    func getJobStatus(jobId: UUID) async -> TranscodeJobStatus? {
        jobs[jobId]?.status
    }
    
    func cancel(jobId: UUID) async {
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
        }
    }
    
    func getActiveJobs() async -> [TranscodeJob] {
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
}
