//
//  ReplayGainProtocol.swift
//  AudioCore
//
//  Protocol for ReplayGain analysis and application
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// ReplayGain analysis result
public struct ReplayGainResult: Equatable, Sendable {
    /// Track gain in dB (for individual track normalization)
    public let trackGain: Float
    
    /// Album gain in dB (for album normalization)
    public let albumGain: Float?
    
    /// Peak amplitude (0.0 to 1.0)
    public let peak: Float
    
    public init(trackGain: Float, albumGain: Float? = nil, peak: Float) {
        self.trackGain = trackGain
        self.albumGain = albumGain
        self.peak = peak
    }
}

/// Protocol for ReplayGain analysis and application
public protocol ReplayGainProtocol: Sendable {
    /// Analyze audio data to calculate ReplayGain values
    /// - Parameters:
    ///   - audioData: Raw audio samples (interleaved for stereo, mono for single channel)
    ///   - sampleRate: Sample rate in Hz
    ///   - channels: Number of audio channels (1 = mono, 2 = stereo, etc.)
    /// - Returns: ReplayGain result with track gain, album gain (optional), and peak amplitude
    /// - Throws: Error if analysis fails
    func analyzeReplayGain(
        audioData: [Float],
        sampleRate: Int,
        channels: Int
    ) async throws -> ReplayGainResult
    
    /// Apply ReplayGain to audio data
    /// - Parameters:
    ///   - audioData: Raw audio samples to process
    ///   - replayGain: ReplayGain result to apply
    ///   - mode: Whether to use track gain or album gain
    /// - Returns: Processed audio samples with ReplayGain applied
    /// - Throws: Error if application fails
    func applyReplayGain(
        audioData: [Float],
        replayGain: ReplayGainResult,
        mode: ReplayGainMode
    ) async throws -> [Float]
    
    /// Calculate album gain from multiple track ReplayGain results
    /// - Parameter trackResults: Array of ReplayGain results for tracks in an album
    /// - Returns: Album gain in dB
    /// - Throws: Error if calculation fails
    func calculateAlbumGain(from trackResults: [ReplayGainResult]) async throws -> Float
}

/// ReplayGain application mode
public enum ReplayGainMode: Equatable, Sendable {
    case track    // Use track gain
    case album    // Use album gain (if available)
    case off      // Don't apply ReplayGain
}

/// Errors that can occur during ReplayGain operations
public enum ReplayGainError: Error, LocalizedError, Equatable {
    case invalidAudioData
    case invalidSampleRate
    case invalidChannelCount
    case analysisFailed(String)
    case applicationFailed(String)
    case noAlbumGainAvailable
    case invalidTrackResults
    
    public var errorDescription: String? {
        switch self {
        case .invalidAudioData:
            return "Invalid audio data provided"
        case .invalidSampleRate:
            return "Invalid sample rate (must be > 0)"
        case .invalidChannelCount:
            return "Invalid channel count (must be > 0)"
        case .analysisFailed(let reason):
            return "Analysis failed: \(reason)"
        case .applicationFailed(let reason):
            return "Application failed: \(reason)"
        case .noAlbumGainAvailable:
            return "Album gain not available"
        case .invalidTrackResults:
            return "Invalid track results for album gain calculation"
        }
    }
}
