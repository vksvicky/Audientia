//
//  AudioNormalizationProtocol.swift
//  AudioCore
//
//  Protocol for audio normalization (peak, RMS, loudness)
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Normalization modes
public enum NormalizationMode: Equatable, Sendable {
    case peak          // Peak normalization (adjust to target peak level)
    case rms           // RMS normalization (adjust to target RMS level)
    case loudness      // Loudness normalization (EBU R128, ITU-R BS.1770)
}

/// Protocol for audio normalization
public protocol AudioNormalizationProtocol: Sendable {
    /// Analyze audio data to determine normalization gain
    /// - Parameters:
    ///   - audioData: Raw audio samples (interleaved for stereo, mono for single channel)
    ///   - sampleRate: Sample rate in Hz
    ///   - channels: Number of audio channels (1 = mono, 2 = stereo, etc.)
    ///   - mode: Normalization mode to use
    ///   - targetLevel: Target level in dB (e.g., -23.0 for EBU R128, -0.1 for peak normalization)
    /// - Returns: Gain adjustment in dB needed to normalize the audio
    /// - Throws: Error if analysis fails
    func analyzeNormalization(
        audioData: [Float],
        sampleRate: Int,
        channels: Int,
        mode: NormalizationMode,
        targetLevel: Float
    ) async throws -> Float
    
    /// Apply normalization gain to audio data
    /// - Parameters:
    ///   - audioData: Raw audio samples to normalize
    ///   - gainDB: Gain adjustment in dB to apply
    /// - Returns: Normalized audio samples
    /// - Throws: Error if normalization fails
    func applyNormalization(
        audioData: [Float],
        gainDB: Float
    ) async throws -> [Float]
    
    /// Calculate peak level of audio data
    /// - Parameters:
    ///   - audioData: Raw audio samples
    ///   - channels: Number of audio channels
    /// - Returns: Peak level in dB
    func calculatePeakLevel(
        audioData: [Float],
        channels: Int
    ) async -> Float
    
    /// Calculate RMS level of audio data
    /// - Parameters:
    ///   - audioData: Raw audio samples
    ///   - channels: Number of audio channels
    /// - Returns: RMS level in dB
    func calculateRMSLevel(
        audioData: [Float],
        channels: Int
    ) async -> Float
    
    /// Calculate loudness (EBU R128, ITU-R BS.1770) of audio data
    /// - Parameters:
    ///   - audioData: Raw audio samples
    ///   - sampleRate: Sample rate in Hz
    ///   - channels: Number of audio channels
    /// - Returns: Loudness in LUFS (Loudness Units relative to Full Scale)
    /// - Throws: Error if loudness calculation fails
    func calculateLoudness(
        audioData: [Float],
        sampleRate: Int,
        channels: Int
    ) async throws -> Float
}

/// Errors that can occur during normalization
public enum AudioNormalizationError: Error, LocalizedError, Equatable {
    case invalidAudioData
    case invalidSampleRate
    case invalidChannelCount
    case invalidTargetLevel
    case analysisFailed(String)
    case normalizationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidAudioData:
            return "Invalid audio data provided"
        case .invalidSampleRate:
            return "Invalid sample rate (must be > 0)"
        case .invalidChannelCount:
            return "Invalid channel count (must be > 0)"
        case .invalidTargetLevel:
            return "Invalid target level"
        case .analysisFailed(let reason):
            return "Analysis failed: \(reason)"
        case .normalizationFailed(let reason):
            return "Normalization failed: \(reason)"
        }
    }
}
