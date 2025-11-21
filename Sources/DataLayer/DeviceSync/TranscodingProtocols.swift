//
//  TranscodingProtocols.swift
//  DataLayer
//
//  Protocol definitions for Transcoding Pipeline (Feature 4.2)
//

import Foundation
import Shared

// MARK: - Transcode Profile
// Note: TranscodeProfile and TranscodeQuality are now in Shared/Models/DeviceSyncModels.swift
// This file re-exports them for convenience

// MARK: - Transcode Engine

/// Protocol for transcoding audio files
public protocol TranscodeEngineProtocol: Sendable {
    /// Transcode an audio file to the specified profile
    /// - Parameters:
    ///   - inputPath: Path to source audio file
    ///   - outputPath: Path where transcoded file should be written
    ///   - profile: Transcoding profile to use
    ///   - progress: Progress callback (0.0 to 1.0)
    /// - Returns: Path to transcoded file
    /// - Throws: TranscodeError if transcoding fails
    func transcode(
        inputPath: String,
        outputPath: String,
        profile: TranscodeProfile,
        progress: @escaping (Double) -> Void
    ) async throws -> String
    
    /// Check if a file needs transcoding for the given profile
    /// - Parameters:
    ///   - track: Track to check
    ///   - profile: Target profile
    /// - Returns: True if transcoding is needed
    func needsTranscoding(track: Track, profile: TranscodeProfile) async -> Bool
    
    /// Estimate output file size for transcoding
    /// - Parameters:
    ///   - track: Source track
    ///   - profile: Target profile
    /// - Returns: Estimated size in bytes
    func estimateOutputSize(track: Track, profile: TranscodeProfile) async -> Int64
}

// MARK: - Transcode Queue

/// Protocol for managing background transcoding queue
public protocol TranscodeQueueProtocol: Sendable {
    /// Add a track to the transcoding queue
    /// - Parameters:
    ///   - track: Track to transcode
    ///   - profile: Profile to use
    ///   - outputPath: Where to save transcoded file
    /// - Returns: Job ID for tracking progress
    func enqueue(track: Track, profile: TranscodeProfile, outputPath: String) async -> UUID
    
    /// Get transcoding job status
    /// - Parameter jobId: Job identifier
    /// - Returns: Job status and progress
    func getJobStatus(jobId: UUID) async -> TranscodeJobStatus?
    
    /// Cancel a transcoding job
    /// - Parameter jobId: Job identifier
    func cancel(jobId: UUID) async
    
    /// Get all active jobs
    /// - Returns: Array of active transcoding jobs
    func getActiveJobs() async -> [TranscodeJob]
}

// MARK: - Transcode Models

/// Status of a transcoding job
public enum TranscodeJobStatus: Equatable, Sendable {
    case queued
    case transcoding(progress: Double)
    case completed(outputPath: String)
    case failed(error: String)
    case cancelled
}

/// Represents a transcoding job
public struct TranscodeJob: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let track: Track
    public let profile: TranscodeProfile
    public let outputPath: String
    public let status: TranscodeJobStatus
    public let createdAt: Date
    
    public init(
        id: UUID = UUID(),
        track: Track,
        profile: TranscodeProfile,
        outputPath: String,
        status: TranscodeJobStatus = .queued,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.track = track
        self.profile = profile
        self.outputPath = outputPath
        self.status = status
        self.createdAt = createdAt
    }
}

/// Errors that can occur during transcoding
public enum TranscodeError: Error, Equatable, Sendable {
    case invalidInputFile
    case invalidOutputPath
    case unsupportedFormat
    case insufficientSpace
    case transcodingFailed(String)
    case cancelled
    case engineNotAvailable
}
