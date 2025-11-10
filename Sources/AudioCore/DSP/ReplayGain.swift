//
//  ReplayGain.swift
//  AudioCore
//
//  ReplayGain analysis and application implementation
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// ReplayGain implementation
/// Analyzes audio to calculate ReplayGain values and applies them for volume normalization
public final class ReplayGain: ReplayGainProtocol, @unchecked Sendable {
    
    /// Target loudness level in LUFS (EBU R128 standard: -23.0 LUFS)
    private let targetLoudness: Float = -23.0
    
    public init() {}
    
    /// Analyze audio data to calculate ReplayGain values
    public func analyzeReplayGain(
        audioData: [Float],
        sampleRate: Int,
        channels: Int
    ) async throws -> ReplayGainResult {
        // Validate inputs
        guard sampleRate > 0 else {
            throw ReplayGainError.invalidSampleRate
        }
        guard channels > 0 else {
            throw ReplayGainError.invalidChannelCount
        }
        guard !audioData.isEmpty else {
            throw ReplayGainError.invalidAudioData
        }
        
        // Calculate peak amplitude
        let peak = calculatePeak(audioData: audioData)
        
        // Calculate loudness (simplified - full implementation would use EBU R128)
        let loudness = try await calculateLoudness(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Calculate track gain: gain = target - current
        let trackGain = targetLoudness - loudness
        
        // Return result (album gain calculated separately from multiple tracks)
        return ReplayGainResult(trackGain: trackGain, albumGain: nil, peak: peak)
    }
    
    /// Apply ReplayGain to audio data
    public func applyReplayGain(
        audioData: [Float],
        replayGain: ReplayGainResult,
        mode: ReplayGainMode
    ) async throws -> [Float] {
        guard !audioData.isEmpty else {
            throw ReplayGainError.invalidAudioData
        }
        
        // If mode is off, return unchanged
        if mode == .off {
            return audioData
        }
        
        // Determine which gain to use
        let gainDB: Float
        switch mode {
        case .track:
            gainDB = replayGain.trackGain
        case .album:
            guard let albumGain = replayGain.albumGain else {
                throw ReplayGainError.noAlbumGainAvailable
            }
            gainDB = albumGain
        case .off:
            return audioData // Already handled above
        }
        
        // Convert dB to linear gain
        let linearGain = pow(10.0, gainDB / 20.0)
        
        // Apply gain to audio samples
        var processed = audioData
        for i in 0..<processed.count {
            processed[i] *= linearGain
            
            // Apply peak limiting to prevent clipping
            // Use the peak value from ReplayGain result to scale appropriately
            if replayGain.peak > 0.0 {
                let maxAmplitude = 1.0 / replayGain.peak
                processed[i] = max(-maxAmplitude, min(maxAmplitude, processed[i]))
            } else {
                // Clamp to prevent clipping
                processed[i] = max(-1.0, min(1.0, processed[i]))
            }
            
            // Handle NaN and infinity
            if processed[i].isNaN || processed[i].isInfinite {
                processed[i] = 0.0
            }
        }
        
        return processed
    }
    
    /// Calculate album gain from multiple track ReplayGain results
    public func calculateAlbumGain(from trackResults: [ReplayGainResult]) async throws -> Float {
        guard !trackResults.isEmpty else {
            throw ReplayGainError.invalidTrackResults
        }
        
        // Album gain is typically the average of track gains
        let sum = trackResults.reduce(0.0) { $0 + $1.trackGain }
        let average = sum / Float(trackResults.count)
        
        return average
    }
    
    // MARK: - Private Methods
    
    /// Calculate peak amplitude
    private func calculatePeak(audioData: [Float]) -> Float {
        var peak: Float = 0.0
        for sample in audioData {
            let absValue = abs(sample)
            if absValue > peak {
                peak = absValue
            }
        }
        return peak
    }
    
    /// Calculate loudness (simplified EBU R128)
    /// Full implementation would include pre-filtering, channel weighting, and gating
    private func calculateLoudness(
        audioData: [Float],
        sampleRate: Int,
        channels: Int
    ) async throws -> Float {
        guard !audioData.isEmpty else {
            throw ReplayGainError.invalidAudioData
        }
        
        // Simplified loudness calculation using RMS
        // Full EBU R128 would require more complex processing
        var sumOfSquares: Float = 0.0
        var sampleCount = 0
        
        for sample in audioData {
            if !sample.isNaN && !sample.isInfinite {
                sumOfSquares += sample * sample
                sampleCount += 1
            }
        }
        
        guard sampleCount > 0 else {
            throw ReplayGainError.analysisFailed("No valid samples found")
        }
        
        let meanSquare = sumOfSquares / Float(sampleCount)
        let rms = sqrt(meanSquare)
        
        // Convert to LUFS (simplified)
        // Full EBU R128: LUFS = -0.691 + 10 * log10(meanSquare)
        if rms == 0.0 {
            return Float.infinity * -1.0 // Silence
        }
        
        let lufs = -0.691 + 10.0 * log10(meanSquare)
        return lufs
    }
}
