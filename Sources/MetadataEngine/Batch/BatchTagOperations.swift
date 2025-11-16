//
//  BatchTagOperations.swift
//  MetadataEngine
//
//  Batch operations for updating multiple tracks at once
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Errors that can occur during batch tag operations
public enum BatchTagOperationsError: Error, LocalizedError, Sendable, Equatable {
    /// Arrays of tracks and file URLs have mismatched lengths
    case mismatchedArrays
    
    /// No tracks provided
    case noTracks
    
    public var errorDescription: String? {
        switch self {
        case .mismatchedArrays:
            return "Number of tracks does not match number of file URLs"
        case .noTracks:
            return "No tracks provided for batch operation"
        }
    }
}

/// Result of a batch tag operation
public struct BatchTagOperationResult: Sendable {
    /// Number of successfully updated tracks
    public let successCount: Int
    
    /// Number of failed updates
    public let failureCount: Int
    
    /// List of failures with track and error information
    public let failures: [BatchTagOperationFailure]
    
    public init(successCount: Int, failureCount: Int, failures: [BatchTagOperationFailure]) {
        self.successCount = successCount
        self.failureCount = failureCount
        self.failures = failures
    }
}

/// Information about a failed batch operation
public struct BatchTagOperationFailure: Sendable {
    /// The track that failed
    public let track: Track
    
    /// The file URL that failed
    public let fileURL: URL
    
    /// The error that occurred
    public let error: Error
    
    public init(track: Track, fileURL: URL, error: Error) {
        self.track = track
        self.fileURL = fileURL
        self.error = error
    }
}

/// Batch operations for updating multiple tracks at once
public final class BatchTagOperations: @unchecked Sendable {
    private let writer: TagWriterProtocol
    private let validator: TagValidatorProtocol
    
    /// Initialize with a tag writer and validator
    /// - Parameters:
    ///   - writer: The tag writer to use for writing tags
    ///   - validator: The tag validator to use for validating tags
    public init(writer: TagWriterProtocol, validator: TagValidatorProtocol) {
        self.writer = writer
        self.validator = validator
    }
    
    /// Update multiple tracks with their new metadata
    /// - Parameters:
    ///   - tracks: Array of tracks with updated metadata
    ///   - fileURLs: Array of file URLs corresponding to the tracks (must match length)
    /// - Returns: Result containing success count, failure count, and failure details
    /// - Throws: BatchTagOperationsError if arrays are mismatched or empty
    public func updateTracks(tracks: [Track], fileURLs: [URL]) async throws -> BatchTagOperationResult {
        // Validate input
        guard !tracks.isEmpty else {
            throw BatchTagOperationsError.noTracks
        }
        
        guard tracks.count == fileURLs.count else {
            throw BatchTagOperationsError.mismatchedArrays
        }
        
        var successCount = 0
        var failureCount = 0
        var failures: [BatchTagOperationFailure] = []
        
        // Process each track
        for (index, track) in tracks.enumerated() {
            let fileURL = fileURLs[index]
            
            // Validate track metadata
            let validationResult = validator.validate(track: track)
            if !validationResult.isValid {
                failureCount += 1
                failures.append(BatchTagOperationFailure(
                    track: track,
                    fileURL: fileURL,
                    error: validationResult.errors.first ?? TagValidationError.invalidYear(0)
                ))
                continue
            }
            
            // Write tags
            do {
                try await writer.write(track: track, to: fileURL)
                successCount += 1
            } catch {
                failureCount += 1
                failures.append(BatchTagOperationFailure(
                    track: track,
                    fileURL: fileURL,
                    error: error
                ))
            }
        }
        
        return BatchTagOperationResult(
            successCount: successCount,
            failureCount: failureCount,
            failures: failures
        )
    }
}
