//
//  AudioGainControl.swift
//  AudioCore
//
//  Audio gain control implementation (per-track and global gain adjustment)
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Audio gain control implementation
/// Manages per-track and global gain adjustments in decibels (dB)
public final class AudioGainControl: AudioGainControlProtocol, @unchecked Sendable {
    private let gainActor = GainActor()
    
    public init() {}
    
    /// Get gain for a specific track (in dB)
    /// - Parameter track: The track to get gain for
    /// - Returns: Gain in dB, or nil if no track-specific gain is set
    public func getTrackGain(for track: Shared.Track) async -> Float? {
        await gainActor.getTrackGain(for: track.id)
    }
    
    /// Set gain for a specific track (in dB)
    /// - Parameters:
    ///   - gain: Gain in dB (typically -20.0 to +20.0, but can be any value)
    ///   - track: The track to set gain for
    public func setTrackGain(_ gain: Float, for track: Shared.Track) async {
        let clampedGain = clampGain(gain)
        await gainActor.setTrackGain(clampedGain, for: track.id)
    }
    
    /// Remove track-specific gain (revert to global gain)
    /// - Parameter track: The track to remove gain for
    public func removeTrackGain(for track: Shared.Track) async {
        await gainActor.removeTrackGain(for: track.id)
    }
    
    /// Get global gain (in dB)
    /// - Returns: Global gain in dB (default: 0.0)
    public func getGlobalGain() async -> Float {
        await gainActor.getGlobalGain()
    }
    
    /// Set global gain (in dB)
    /// - Parameter gain: Global gain in dB (typically -20.0 to +20.0, but can be any value)
    public func setGlobalGain(_ gain: Float) async {
        let clampedGain = clampGain(gain)
        await gainActor.setGlobalGain(clampedGain)
    }
    
    /// Get effective gain for a track (track gain + global gain)
    /// - Parameter track: The track to get effective gain for
    /// - Returns: Effective gain in dB
    public func getEffectiveGain(for track: Shared.Track) async -> Float {
        await gainActor.getEffectiveGain(for: track.id)
    }
    
    /// Convert gain from dB to linear multiplier
    /// - Parameter gainDB: Gain in dB
    /// - Returns: Linear multiplier (e.g., 0.0 dB = 1.0, -6.0 dB = 0.5, +6.0 dB = 2.0)
    public func gainDBToLinear(_ gainDB: Float) -> Float {
        // Formula: linear = 10^(dB/20)
        if gainDB.isInfinite || gainDB.isNaN {
            return 1.0 // Default to unity gain for invalid values
        }
        return pow(10.0, gainDB / 20.0)
    }
    
    /// Convert gain from linear multiplier to dB
    /// - Parameter linear: Linear multiplier
    /// - Returns: Gain in dB
    public func linearToGainDB(_ linear: Float) -> Float {
        // Formula: dB = 20 * log10(linear)
        if linear.isNaN || linear.isInfinite {
            return 0.0 // Default to 0 dB for NaN or infinite values
        }
        if linear <= 0.0 {
            // log10(0) = -infinity, log10(negative) = NaN
            if linear == 0.0 {
                return -Float.infinity // Zero linear maps to -infinity dB
            } else {
                return Float.nan // Negative linear maps to NaN
            }
        }
        return 20.0 * log10(linear)
    }
    
    // MARK: - Private Methods
    
    /// Clamp gain value to reasonable range (prevent extreme values that could cause issues)
    /// - Parameter gain: Gain in dB
    /// - Returns: Clamped gain value
    private func clampGain(_ gain: Float) -> Float {
        if gain.isNaN {
            return 0.0
        }
        if gain.isInfinite {
            return gain > 0 ? 60.0 : -60.0 // Clamp infinity to reasonable extremes
        }
        // Allow wide range but clamp extreme values to prevent issues
        return max(-100.0, min(100.0, gain))
    }
}

/// Actor for thread-safe gain operations
private actor GainActor {
    /// Global gain in dB (default: 0.0)
    private var globalGain: Float = 0.0
    
    /// Per-track gains indexed by track ID
    private var trackGains: [UUID: Float] = [:]
    
    func getTrackGain(for trackID: UUID) -> Float? {
        trackGains[trackID]
    }
    
    func setTrackGain(_ gain: Float, for trackID: UUID) {
        trackGains[trackID] = gain
    }
    
    func removeTrackGain(for trackID: UUID) {
        trackGains.removeValue(forKey: trackID)
    }
    
    func getGlobalGain() -> Float {
        globalGain
    }
    
    func setGlobalGain(_ gain: Float) {
        globalGain = gain
    }
    
    func getEffectiveGain(for trackID: UUID) -> Float {
        let trackGain = trackGains[trackID] ?? 0.0
        return globalGain + trackGain
    }
}
