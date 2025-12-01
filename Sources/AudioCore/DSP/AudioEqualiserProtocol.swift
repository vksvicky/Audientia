//
//  AudioEqualiserProtocol.swift
//  AudioCore
//
//  Protocol for 10-band parametric equaliser
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Equaliser band configuration
/// A parametric equaliser band with frequency, gain, and Q factor
public struct EqualiserBand: Equatable, Sendable {
    /// Center frequency in Hz
    public let frequency: Float
    
    /// Gain in dB (-20.0 to +20.0 typically)
    public let gain: Float
    
    /// Q factor (bandwidth) - typically 0.1 to 10.0
    public let qualityFactor: Float
    
    public init(frequency: Float, gain: Float, qualityFactor: Float = 1.0) {
        self.frequency = frequency
        self.gain = gain
        self.qualityFactor = qualityFactor
    }
}

/// Protocol for 10-band parametric equaliser
public protocol AudioEqualiserProtocol: Sendable {
    /// Get all equaliser bands
    /// - Returns: Array of 10 equaliser bands
    func getBands() async -> [EqualiserBand]
    
    /// Set gain for a specific band
    /// - Parameters:
    ///   - bandIndex: Index of the band (0-9)
    ///   - gain: Gain in dB (-20.0 to +20.0 typically)
    /// - Throws: Error if band index is invalid
    func setBandGain(_ bandIndex: Int, gain: Float) async throws
    
    /// Get gain for a specific band
    /// - Parameter bandIndex: Index of the band (0-9)
    /// - Returns: Gain in dB
    /// - Throws: Error if band index is invalid
    func getBandGain(_ bandIndex: Int) async throws -> Float
    
    /// Reset all bands to flat (0.0 dB gain)
    func reset() async
    
    /// Apply equaliser to audio samples
    /// - Parameters:
    ///   - audioData: Raw audio samples (interleaved for stereo, mono for single channel)
    ///   - sampleRate: Sample rate in Hz
    ///   - channels: Number of audio channels (1 = mono, 2 = stereo, etc.)
    /// - Returns: Equalized audio samples
    /// - Throws: Error if processing fails
    func process(
        audioData: [Float],
        sampleRate: Int,
        channels: Int
    ) async throws -> [Float]
    
    /// Check if equaliser is enabled
    /// - Returns: true if equaliser is enabled, false if bypassed
    func isEnabled() async -> Bool
    
    /// Enable or disable the equaliser
    /// - Parameter enabled: Whether to enable the equaliser
    func setEnabled(_ enabled: Bool) async
}

/// Errors that can occur during equaliser operations
public enum AudioEqualiserError: Error, LocalizedError, Equatable {
    case invalidBandIndex(Int)
    case invalidGainValue(Float)
    case invalidSampleRate
    case invalidChannelCount
    case invalidAudioData
    case processingFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidBandIndex(let index):
            return "Invalid band index: \(index) (must be 0-9)"
        case .invalidGainValue(let value):
            return "Invalid gain value: \(value) dB"
        case .invalidSampleRate:
            return "Invalid sample rate (must be > 0)"
        case .invalidChannelCount:
            return "Invalid channel count (must be > 0)"
        case .invalidAudioData:
            return "Invalid audio data provided"
        case .processingFailed(let reason):
            return "Processing failed: \(reason)"
        }
    }
}
