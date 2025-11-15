//
//  ReplayGainExternalToolProtocol.swift
//  AudioCore
//
//  Protocol for external ReplayGain tool integration (e.g., foobar2000)
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Protocol for external ReplayGain analysis tools
/// Allows comparison of our ReplayGain implementation with external tools
public protocol ReplayGainExternalToolProtocol: Sendable {
    /// Analyze audio data using external tool
    /// - Parameters:
    ///   - audioData: Raw audio samples (interleaved for stereo, mono for single channel)
    ///   - sampleRate: Sample rate in Hz
    ///   - channels: Number of audio channels (1 = mono, 2 = stereo, etc.)
    /// - Returns: ReplayGain result from external tool
    /// - Throws: Error if analysis fails
    func analyzeReplayGain(
        audioData: [Float],
        sampleRate: Int,
        channels: Int
    ) async throws -> ReplayGainResult
    
    /// Name of the external tool (e.g., "foobar2000")
    var toolName: String { get }
}

/// Comparison result between our ReplayGain and external tool
public struct ReplayGainComparisonResult: Equatable, Sendable {
    /// Our ReplayGain result
    public let ourResult: ReplayGainResult
    
    /// External tool's ReplayGain result
    public let externalResult: ReplayGainResult
    
    /// Difference in track gain (dB)
    public let trackGainDifference: Float
    
    /// Difference in peak amplitude
    public let peakDifference: Float
    
    /// Whether the results are within acceptable tolerance
    public let isWithinTolerance: Bool
    
    /// Tolerance used for comparison (dB for gain, absolute for peak)
    public let tolerance: ReplayGainTolerance
    
    public init(
        ourResult: ReplayGainResult,
        externalResult: ReplayGainResult,
        tolerance: ReplayGainTolerance
    ) {
        self.ourResult = ourResult
        self.externalResult = externalResult
        self.trackGainDifference = ourResult.trackGain - externalResult.trackGain
        self.peakDifference = abs(ourResult.peak - externalResult.peak)
        
        let gainWithinTolerance = abs(self.trackGainDifference) <= tolerance.gainTolerance
        let peakWithinTolerance = self.peakDifference <= tolerance.peakTolerance
        self.isWithinTolerance = gainWithinTolerance && peakWithinTolerance
        self.tolerance = tolerance
    }
}

/// Tolerance settings for ReplayGain comparison
public struct ReplayGainTolerance: Equatable, Sendable {
    /// Maximum acceptable difference in gain (dB)
    public let gainTolerance: Float
    
    /// Maximum acceptable difference in peak amplitude (0.0 to 1.0)
    public let peakTolerance: Float
    
    public init(gainTolerance: Float = 0.5, peakTolerance: Float = 0.01) {
        self.gainTolerance = gainTolerance
        self.peakTolerance = peakTolerance
    }
    
    /// Default tolerance (0.5 dB gain, 0.01 peak)
    public static let `default` = ReplayGainTolerance()
    
    /// Strict tolerance (0.1 dB gain, 0.001 peak)
    public static let strict = ReplayGainTolerance(gainTolerance: 0.1, peakTolerance: 0.001)
    
    /// Loose tolerance (1.0 dB gain, 0.05 peak)
    public static let loose = ReplayGainTolerance(gainTolerance: 1.0, peakTolerance: 0.05)
}
