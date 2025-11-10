//
//  AudioEqualizerProtocol.swift
//  AudioCore
//
//  Protocol for 10-band parametric equalizer
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

// swiftlint:disable identifier_name
// Q factor is a standard DSP term, so we allow single-letter 'q' parameter name

/// Equalizer band configuration
/// A parametric equalizer band with frequency, gain, and Q factor
public struct EqualizerBand: Equatable, Sendable {
    /// Center frequency in Hz
    public let frequency: Float
    
    /// Gain in dB (-20.0 to +20.0 typically)
    public let gain: Float
    
    /// Q factor (bandwidth) - typically 0.1 to 10.0
    public let q: Float
    
    public init(frequency: Float, gain: Float, q: Float = 1.0) {
        self.frequency = frequency
        self.gain = gain
        self.q = q
    }
}
// swiftlint:enable identifier_name

/// Protocol for 10-band parametric equalizer
public protocol AudioEqualizerProtocol: Sendable {
    /// Get all equalizer bands
    /// - Returns: Array of 10 equalizer bands
    func getBands() async -> [EqualizerBand]
    
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
    
    /// Apply equalizer to audio samples
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
    
    /// Check if equalizer is enabled
    /// - Returns: true if equalizer is enabled, false if bypassed
    func isEnabled() async -> Bool
    
    /// Enable or disable the equalizer
    /// - Parameter enabled: Whether to enable the equalizer
    func setEnabled(_ enabled: Bool) async
}

/// Errors that can occur during equalizer operations
public enum AudioEqualizerError: Error, LocalizedError, Equatable {
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
