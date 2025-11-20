//
//  InMemorySyncJobQueue.swift
//  DataLayer
//
//  Simple actor-based queue for Device Sync jobs.
//

import Foundation
import Shared

public actor InMemorySyncJobQueue: SyncJobQueueProtocol {
    private var queue: [SyncJob] = []
    private var waiters: [CheckedContinuation<SyncJob?, Never>] = []
    
    public init() {}
    
    public func enqueue(_ job: SyncJob) async {
        queue.append(job)
        resumeNextWaiterIfNeeded()
    }
    
    public func dequeue() async -> SyncJob? {
        if !queue.isEmpty {
            return queue.removeFirst()
        }
        
        return await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }
    
    public func remove(jobId: UUID) async {
        queue.removeAll { $0.id == jobId }
    }
    
    public func isEmpty() async -> Bool {
        queue.isEmpty
    }
    
    public func snapshot() async -> [SyncJob] {
        queue
    }
    
    private func resumeNextWaiterIfNeeded() {
        guard !waiters.isEmpty else { return }
        let continuation = waiters.removeFirst()
        let job = queue.isEmpty ? nil : queue.removeFirst()
        continuation.resume(returning: job)
    }
}
