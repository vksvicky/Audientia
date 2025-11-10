//
//  Crossfade.swift
//  AudioCore
//
//  Crossfade between tracks implementation
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Crossfade implementation
/// Provides smooth transitions between tracks using various fade curves
public final class Crossfade: CrossfadeProtocol, @unchecked Sendable {
    
    public init() {}
    
    /// Apply crossfade between two audio buffers
    public func applyCrossfade(
        outgoingAudio: [Float],
        incomingAudio: [Float],
        sampleRate: Int,
        channels: Int,
        config: CrossfadeConfig
    ) async throws -> [Float] {
        // Validate inputs
        guard sampleRate > 0 else {
            throw CrossfadeError.invalidSampleRate
        }
        guard channels > 0 else {
            throw CrossfadeError.invalidChannelCount
        }
        guard !outgoingAudio.isEmpty && !incomingAudio.isEmpty else {
            throw CrossfadeError.invalidAudioData
        }
        guard config.duration > 0.0 else {
            throw CrossfadeError.invalidDuration
        }
        guard outgoingAudio.count == incomingAudio.count else {
            throw CrossfadeError.bufferMismatch
        }
        
        // Calculate number of samples for crossfade
        let crossfadeSamples = calculateCrossfadeSamples(
            duration: config.duration,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Limit crossfade to buffer length
        let actualCrossfadeSamples = min(crossfadeSamples, outgoingAudio.count / channels)
        
        var result = [Float]()
        result.reserveCapacity(outgoingAudio.count)
        
        // Apply crossfade
        for i in 0..<(outgoingAudio.count / channels) {
            let sampleIndex = i * channels
            
            if i < actualCrossfadeSamples {
                // Within crossfade region
                let progress = Float(i) / Float(actualCrossfadeSamples)
                let fadeOutGain = calculateFadeGain(progress: 1.0 - progress, curve: config.curve)
                let fadeInGain = calculateFadeGain(progress: progress, curve: config.curve)
                
                // Blend channels
                for channel in 0..<channels {
                    let outgoingSample = outgoingAudio[sampleIndex + channel]
                    let incomingSample = incomingAudio[sampleIndex + channel]
                    let blended = (outgoingSample * fadeOutGain) + (incomingSample * fadeInGain)
                    result.append(blended)
                }
            } else {
                // After crossfade, use incoming audio
                for channel in 0..<channels {
                    result.append(incomingAudio[sampleIndex + channel])
                }
            }
        }
        
        return result
    }
    
    /// Calculate number of samples needed for crossfade
    public func calculateCrossfadeSamples(
        duration: TimeInterval,
        sampleRate: Int,
        channels: Int
    ) -> Int {
        Int(duration * Double(sampleRate))
    }
    
    /// Apply fade out to audio samples
    public func applyFadeOut(
        audioData: [Float],
        sampleRate: Int,
        channels: Int,
        duration: TimeInterval,
        curve: CrossfadeCurve
    ) async throws -> [Float] {
        // Validate inputs
        guard sampleRate > 0 else {
            throw CrossfadeError.invalidSampleRate
        }
        guard channels > 0 else {
            throw CrossfadeError.invalidChannelCount
        }
        guard !audioData.isEmpty else {
            throw CrossfadeError.invalidAudioData
        }
        guard duration > 0.0 else {
            throw CrossfadeError.invalidDuration
        }
        
        let fadeSamples = calculateCrossfadeSamples(
            duration: duration,
            sampleRate: sampleRate,
            channels: channels
        )
        let actualFadeSamples = min(fadeSamples, audioData.count / channels)
        
        var result = [Float]()
        result.reserveCapacity(audioData.count)
        
        for i in 0..<(audioData.count / channels) {
            let sampleIndex = i * channels
            
            if i < actualFadeSamples {
                // Within fade region
                // Use (actualFadeSamples - 1) as denominator so last frame reaches 0.0
                let progress = actualFadeSamples > 1 ? Float(i) / Float(actualFadeSamples - 1) : 1.0
                let gain = calculateFadeGain(progress: 1.0 - progress, curve: curve)
                
                for channel in 0..<channels {
                    result.append(audioData[sampleIndex + channel] * gain)
                }
            } else {
                // After fade, audio is silent
                for _ in 0..<channels {
                    result.append(0.0)
                }
            }
        }
        
        return result
    }
    
    /// Apply fade in to audio samples
    public func applyFadeIn(
        audioData: [Float],
        sampleRate: Int,
        channels: Int,
        duration: TimeInterval,
        curve: CrossfadeCurve
    ) async throws -> [Float] {
        // Validate inputs
        guard sampleRate > 0 else {
            throw CrossfadeError.invalidSampleRate
        }
        guard channels > 0 else {
            throw CrossfadeError.invalidChannelCount
        }
        guard !audioData.isEmpty else {
            throw CrossfadeError.invalidAudioData
        }
        guard duration > 0.0 else {
            throw CrossfadeError.invalidDuration
        }
        
        let fadeSamples = calculateCrossfadeSamples(
            duration: duration,
            sampleRate: sampleRate,
            channels: channels
        )
        let actualFadeSamples = min(fadeSamples, audioData.count / channels)
        
        var result = [Float]()
        result.reserveCapacity(audioData.count)
        
        for i in 0..<(audioData.count / channels) {
            let sampleIndex = i * channels
            
            if i < actualFadeSamples {
                // Within fade region
                // Use (actualFadeSamples - 1) as denominator so first frame starts at 0.0
                let progress = actualFadeSamples > 1 ? Float(i) / Float(actualFadeSamples - 1) : 1.0
                let gain = calculateFadeGain(progress: progress, curve: curve)
                
                for channel in 0..<channels {
                    result.append(audioData[sampleIndex + channel] * gain)
                }
            } else {
                // After fade, use full audio
                for channel in 0..<channels {
                    result.append(audioData[sampleIndex + channel])
                }
            }
        }
        
        return result
    }
    
    // MARK: - Private Methods
    
    /// Calculate fade gain based on progress and curve
    /// - Parameters:
    ///   - progress: Fade progress (0.0 = start, 1.0 = end)
    ///   - curve: Fade curve type
    /// - Returns: Gain multiplier (0.0 to 1.0)
    private func calculateFadeGain(progress: Float, curve: CrossfadeCurve) -> Float {
        let clampedProgress = max(0.0, min(1.0, progress))
        
        switch curve {
        case .linear:
            return clampedProgress
        case .exponential:
            // Exponential: gain = (e^(x*ln(2)) - 1) / (e^ln(2) - 1)
            return (exp(clampedProgress * log(2.0)) - 1.0) / (exp(log(2.0)) - 1.0)
        case .logarithmic:
            // Logarithmic: gain = log(1 + x * (e - 1)) / log(e)
            return log(1.0 + clampedProgress * (exp(1.0) - 1.0)) / log(exp(1.0))
        case .cosine:
            // Cosine (S-curve): gain = (1 - cos(π * x)) / 2
            return (1.0 - cos(clampedProgress * Float.pi)) / 2.0
        }
    }
}
