//
//  AudioNormaliser.swift
//  AudioCore
//
//  Audio normalization implementation (peak, RMS, loudness)
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Audio normalization implementation
/// Supports peak normalization, RMS normalization, and loudness normalization (EBU R128)
public final class AudioNormaliser: AudioNormalisationProtocol, @unchecked Sendable {
    
    public init() {}
    
    /// Analyze audio data to determine normalization gain
    public func analyzeNormalization(
        audioData: [Float],
        sampleRate: Int,
        channels: Int,
        mode: NormalizationMode,
        targetLevel: Float
    ) async throws -> Float {
        // Validate inputs
        guard sampleRate > 0 else {
            throw AudioNormalisationError.invalidSampleRate
        }
        guard channels > 0 else {
            throw AudioNormalisationError.invalidChannelCount
        }
        guard !audioData.isEmpty else {
            throw AudioNormalisationError.invalidAudioData
        }
        
        let currentLevel: Float
        
        switch mode {
        case .peak:
            currentLevel = await calculatePeakLevel(audioData: audioData, channels: channels)
        case .rms:
            currentLevel = await calculateRMSLevel(audioData: audioData, channels: channels)
        case .loudness:
            currentLevel = try await calculateLoudness(
                audioData: audioData,
                sampleRate: sampleRate,
                channels: channels
            )
        }
        
        // If current level is -infinity (silence), return 0 dB gain
        if currentLevel.isInfinite && currentLevel < 0 {
            return 0.0
        }
        
        // Calculate gain needed: gain = target - current
        let gainDB = targetLevel - currentLevel
        
        return gainDB
    }
    
    /// Apply normalization gain to audio data
    public func applyNormalization(
        audioData: [Float],
        gainDB: Float
    ) async throws -> [Float] {
        guard !audioData.isEmpty else {
            throw AudioNormalisationError.invalidAudioData
        }
        
        // Convert dB to linear gain
        let linearGain = pow(10.0, gainDB / 20.0)
        
        // Apply gain to each sample
        return audioData.map { sample in
            let normalized = sample * linearGain
            // Clamp to prevent extreme values (though clipping is allowed)
            if normalized.isNaN {
                return 0.0
            }
            if normalized.isInfinite {
                return normalized > 0 ? 1.0 : -1.0
            }
            return normalized
        }
    }
    
    /// Calculate peak level of audio data
    public func calculatePeakLevel(
        audioData: [Float],
        channels: Int
    ) async -> Float {
        guard !audioData.isEmpty, channels > 0 else {
            return Float.infinity * -1.0 // Return -infinity for invalid input
        }
        
        // Find maximum absolute value across all channels
        var peak: Float = 0.0
        for sample in audioData {
            let absValue = abs(sample)
            if absValue > peak {
                peak = absValue
            }
        }
        
        // Convert to dB: 20 * log10(peak)
        if peak == 0.0 {
            return Float.infinity * -1.0 // -infinity for silence
        }
        
        return 20.0 * log10(peak)
    }
    
    /// Calculate RMS level of audio data
    public func calculateRMSLevel(
        audioData: [Float],
        channels: Int
    ) async -> Float {
        guard !audioData.isEmpty, channels > 0 else {
            return Float.infinity * -1.0 // Return -infinity for invalid input
        }
        
        // Calculate RMS: sqrt(sum(samples^2) / count)
        var sumOfSquares: Float = 0.0
        var sampleCount = 0
        
        for sample in audioData {
            if !sample.isNaN && !sample.isInfinite {
                sumOfSquares += sample * sample
                sampleCount += 1
            }
        }
        
        guard sampleCount > 0 else {
            return Float.infinity * -1.0 // -infinity for all invalid samples
        }
        
        let meanSquare = sumOfSquares / Float(sampleCount)
        let rms = sqrt(meanSquare)
        
        // Convert to dB: 20 * log10(rms)
        if rms == 0.0 {
            return Float.infinity * -1.0 // -infinity for silence
        }
        
        return 20.0 * log10(rms)
    }
    
    /// Calculate loudness (EBU R128, ITU-R BS.1770) of audio data
    /// Simplified implementation - full EBU R128 requires pre-filtering and gating
    public func calculateLoudness(
        audioData: [Float],
        sampleRate: Int,
        channels: Int
    ) async throws -> Float {
        guard sampleRate > 0 else {
            throw AudioNormalisationError.invalidSampleRate
        }
        guard channels > 0 else {
            throw AudioNormalisationError.invalidChannelCount
        }
        guard !audioData.isEmpty else {
            throw AudioNormalisationError.invalidAudioData
        }
        
        // Simplified loudness calculation
        // Full EBU R128 requires:
        // 1. Pre-filtering (high-pass at 80 Hz, low-pass at 20 kHz)
        // 2. Channel weighting (L, R, C, Ls, Rs)
        // 3. Mean square calculation
        // 4. Gating (removing silent segments)
        // 5. Relative threshold unit (LUFS)
        
        // For now, we'll use a simplified approach based on RMS with channel weighting
        // This is a placeholder - full implementation would require DSP filters
        
        var sumOfSquares: Float = 0.0
        var sampleCount = 0
        
        // Process samples (interleaved for multi-channel)
        var channelIndex = 0
        for sample in audioData {
            if !sample.isNaN && !sample.isInfinite {
                // Channel weighting (simplified - full implementation would use proper weights)
                let weightedSample = sample
                sumOfSquares += weightedSample * weightedSample
                sampleCount += 1
            }
            channelIndex = (channelIndex + 1) % channels
        }
        
        guard sampleCount > 0 else {
            throw AudioNormalisationError.analysisFailed("No valid samples found")
        }
        
        let meanSquare = sumOfSquares / Float(sampleCount)
        let rms = sqrt(meanSquare)
        
        // Convert to LUFS (Loudness Units relative to Full Scale)
        // LUFS = -0.691 + 10 * log10(meanSquare)
        // This is a simplified formula - full EBU R128 uses more complex calculation
        if rms == 0.0 {
            return Float.infinity * -1.0 // -infinity for silence
        }
        
        let lufs = -0.691 + 10.0 * log10(meanSquare)
        return lufs
    }
}
