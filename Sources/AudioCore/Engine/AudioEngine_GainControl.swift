//
//  AudioEngine_GainControl.swift
//  AudioCore
//
//  Gain control extension for AudioEngine
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.

import Foundation
import os.log
import Shared

// MARK: - Gain Control Extension
extension AudioEngine {
    /// Refresh gain multiplier (call this when gain changes externally)
    /// NOTE: This only updates volume/gain, it does NOT trigger playback
    public func refreshGain() async {
        // CRITICAL: Only update gain/volume, never trigger playback
        // This ensures gain control doesn't cause duplicate playback
        await updateGainMultiplier()
        Logger.audio.debug("Gain refreshed - volume updated, no playback triggered")
    }
    
    /// Get current effective gain for the loaded track
    /// - Returns: Effective gain in dB, or nil if no track loaded or no gain control
    public func getEffectiveGain() async -> Float? {
        guard let gainControl = gainControl, let track = currentTrack else {
            return nil
        }
        return await gainControl.getEffectiveGain(for: track)
    }
}
