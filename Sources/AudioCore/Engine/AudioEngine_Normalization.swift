//
//  AudioEngine_Normalization.swift
//  AudioCore
//
//  Normalization extension for AudioEngine
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.

import Foundation
import os.log
import Shared

// MARK: - Normalization Extension
extension AudioEngine {
    /// Analyze normalization for the current track
    /// - Parameters:
    ///   - mode: Normalization mode
    ///   - targetLevel: Target level in dB
    ///   - audioData: Audio samples to analyze (optional, will use track if nil)
    /// - Returns: Normalization gain in dB, or nil if analysis fails
    public func analyzeNormalization(
        mode: NormalizationMode,
        targetLevel: Float,
        audioData: [Float]? = nil
    ) async -> Float? {
        guard let normaliser = normaliser, currentTrack != nil else {
            return nil
        }
        
        // For now, normalization analysis requires audio data
        // In a full implementation, this would read audio samples from the track
        guard let audioData = audioData else {
            Logger.audio.warning("Normalization analysis requires audio data")
            return nil
        }
        
        // Use detected format or defaults
        let sampleRate = detectedFormat?.sampleRate ?? 44100
        let channels = detectedFormat?.channelCount ?? 2
        
        do {
            return try await normaliser.analyzeNormalization(
                audioData: audioData,
                sampleRate: sampleRate,
                channels: channels,
                mode: mode,
                targetLevel: targetLevel
            )
        } catch {
            Logger.audio.error("Normalization analysis failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Apply normalization gain to the current track
    /// - Parameters:
    ///   - mode: Normalization mode
    ///   - targetLevel: Target level in dB
    ///   - audioData: Audio samples to analyze (optional, will use track if nil)
    /// - Returns: Applied gain in dB, or nil if normalization fails
    public func applyNormalization(
        mode: NormalizationMode,
        targetLevel: Float,
        audioData: [Float]? = nil
    ) async -> Float? {
        guard let gain = await analyzeNormalization(
            mode: mode,
            targetLevel: targetLevel,
            audioData: audioData
        ) else {
            return nil
        }
        
        // Apply the normalization gain via gain control
        guard let gainControl = gainControl, let track = currentTrack else {
            Logger.audio.warning("Cannot apply normalization: gain control or track not available")
            return nil
        }
        
        await gainControl.setTrackGain(gain, for: track)
        await updateGainMultiplier()
        
        let modeString: String
        switch mode {
        case .peak: modeString = "peak"
        case .rms: modeString = "rms"
        case .loudness: modeString = "loudness"
        }
        Logger.audio.info("Applied normalization gain: \(gain) dB (mode: \(modeString), target: \(targetLevel) dB)")
        return gain
    }
}
