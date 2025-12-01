//
//  BatchTagOperationsViewModel.swift
//  Audientia - Batch Tag Operations ViewModel
//
//  ViewModel for batch tag operations UI
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Combine
import Foundation
import MetadataEngine
import os.log
import Shared
import SwiftUI

// BatchTagOperationsProtocol is defined in MetadataEngine

/// ViewModel for batch tag operations
/// Manages batch updating of multiple tracks' metadata
@MainActor
public final class BatchTagOperationsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Result of the last batch operation
    @Published public private(set) var result: BatchTagOperationResult?
    
    /// Whether batch operation is in progress
    @Published public private(set) var isProcessing = false
    
    /// Progress (0.0 to 1.0) for batch operations
    @Published public private(set) var progress: Double = 0.0
    
    /// Last error that occurred
    @Published public private(set) var lastError: Error?
    
    // MARK: - Private Properties
    
    private let batchOperations: any BatchTagOperationsProtocol
    
    // MARK: - Initialisation
    
    /// Initialise with batch operations
    /// - Parameter batchOperations: The batch operations instance to use
    public init(batchOperations: any BatchTagOperationsProtocol) {
        self.batchOperations = batchOperations
        Logger.userInterface.info("BatchTagOperationsViewModel initialised")
    }
    
    // MARK: - Public Methods
    
    /// Update multiple tracks with new metadata
    /// - Parameters:
    ///   - tracks: Array of tracks with updated metadata
    ///   - fileURLs: Array of file URLs corresponding to the tracks
    public func updateTracks(tracks: [Shared.Track], fileURLs: [URL]) async throws {
        guard !tracks.isEmpty else {
            let error = BatchTagOperationsError.noTracks
            lastError = error
            throw error
        }
        
        guard tracks.count == fileURLs.count else {
            let error = BatchTagOperationsError.mismatchedArrays
            lastError = error
            throw error
        }
        
        isProcessing = true
        progress = 0.0
        lastError = nil
        
        do {
            // Update progress as operation progresses
            // Note: Actual progress tracking would require BatchTagOperations to support progress callbacks
            // For now, we'll set progress to 0.5 during processing and 1.0 on completion
            progress = 0.5
            
            let operationResult = try await batchOperations.updateTracks(tracks: tracks, fileURLs: fileURLs)
            
            result = operationResult
            progress = 1.0
            
            let successCount = operationResult.successCount
            let failureCount = operationResult.failureCount
            Logger.userInterface.info(
                "Batch update completed: \(successCount) successes, \(failureCount) failures"
            )
        } catch {
            lastError = error
            progress = 0.0
            throw error
        }
        
        isProcessing = false
    }
    
    /// Clear the last result
    public func clearResult() {
        result = nil
        lastError = nil
        progress = 0.0
    }
}
