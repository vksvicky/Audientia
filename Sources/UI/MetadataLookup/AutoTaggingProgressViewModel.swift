//
//  AutoTaggingProgressViewModel.swift
//  Audientia - Metadata Lookup UI
//
//  ViewModel to track auto-tagging progress for batches of tracks
//

import Foundation

@MainActor
public final class AutoTaggingProgressViewModel: ObservableObject {
    @Published public private(set) var total: Int = 0
    @Published public private(set) var completed: Int = 0
    @Published public private(set) var currentTrackName: String = ""
    @Published public private(set) var statusMessage: String = "Idle"
    @Published public private(set) var isRunning = false
    
    public var progress: Double {
        guard total > 0 else { return 0.0 }
        return Double(completed) / Double(total)
    }
    
    public init() {}
    
    public func start(total: Int) {
        guard total > 0 else {
            reset()
            return
        }
        self.total = total
        completed = 0
        currentTrackName = ""
        statusMessage = "Starting auto-tagging..."
        isRunning = true
    }
    
    public func update(completed: Int, trackName: String) {
        guard isRunning else { return }
        self.completed = min(completed, total)
        currentTrackName = trackName
        statusMessage = "Processing \(trackName) (\(self.completed)/\(total))"
    }
    
    public func complete() {
        guard isRunning else { return }
        completed = total
        statusMessage = "Auto-tagging complete"
        isRunning = false
    }
    
    public func reset() {
        total = 0
        completed = 0
        currentTrackName = ""
        statusMessage = "Idle"
        isRunning = false
    }
}
