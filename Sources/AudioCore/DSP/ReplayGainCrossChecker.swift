//
//  ReplayGainCrossChecker.swift
//  AudioCore
//
//  Cross-checking ReplayGain implementation with external tools
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Cross-checker for comparing our ReplayGain implementation with external tools
public final class ReplayGainCrossChecker: @unchecked Sendable {
    
    private let replayGain: ReplayGainProtocol
    private let externalTool: ReplayGainExternalToolProtocol
    
    /// Initialise cross-checker with ReplayGain implementation and external tool
    /// - Parameters:
    ///   - replayGain: Our ReplayGain implementation
    ///   - externalTool: External tool for comparison (e.g., foobar2000)
    public init(
        replayGain: ReplayGainProtocol,
        externalTool: ReplayGainExternalToolProtocol
    ) {
        self.replayGain = replayGain
        self.externalTool = externalTool
    }
    
    /// Compare our ReplayGain analysis with external tool
    /// - Parameters:
    ///   - audioData: Raw audio samples (interleaved for stereo, mono for single channel)
    ///   - sampleRate: Sample rate in Hz
    ///   - channels: Number of audio channels (1 = mono, 2 = stereo, etc.)
    ///   - tolerance: Tolerance settings for comparison (default: 0.5 dB gain, 0.01 peak)
    /// - Returns: Comparison result with differences and tolerance check
    /// - Throws: Error if analysis fails for either tool
    public func compareReplayGain(
        audioData: [Float],
        sampleRate: Int,
        channels: Int,
        tolerance: ReplayGainTolerance = .default
    ) async throws -> ReplayGainComparisonResult {
        // Analyze with our implementation
        let ourResult = try await replayGain.analyzeReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Analyze with external tool
        let externalResult = try await externalTool.analyzeReplayGain(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Compare results
        return ReplayGainComparisonResult(
            ourResult: ourResult,
            externalResult: externalResult,
            tolerance: tolerance
        )
    }
    
    /// Compare multiple tracks (for album gain comparison)
    /// - Parameters:
    ///   - tracks: Array of audio data for each track
    ///   - sampleRate: Sample rate in Hz (same for all tracks)
    ///   - channels: Number of audio channels (same for all tracks)
    ///   - tolerance: Tolerance settings for comparison
    /// - Returns: Array of comparison results, one per track
    /// - Throws: Error if analysis fails for any track
    public func compareAlbumReplayGain(
        tracks: [[Float]],
        sampleRate: Int,
        channels: Int,
        tolerance: ReplayGainTolerance = .default
    ) async throws -> [ReplayGainComparisonResult] {
        var results: [ReplayGainComparisonResult] = []
        
        for trackData in tracks {
            let comparison = try await compareReplayGain(
                audioData: trackData,
                sampleRate: sampleRate,
                channels: channels,
                tolerance: tolerance
            )
            results.append(comparison)
        }
        
        return results
    }
}
