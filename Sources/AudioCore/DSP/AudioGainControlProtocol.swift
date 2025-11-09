//
//  AudioGainControlProtocol.swift
//  AudioCore
//
//  Protocol for audio gain control (per-track and global gain adjustment)
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Protocol for audio gain control
/// Gain is measured in decibels (dB) and can be positive (amplification) or negative (attenuation)
public protocol AudioGainControlProtocol: Sendable {
    /// Get gain for a specific track (in dB)
    /// - Parameter track: The track to get gain for
    /// - Returns: Gain in dB, or nil if no track-specific gain is set
    func getTrackGain(for track: Track) async -> Float?
    
    /// Set gain for a specific track (in dB)
    /// - Parameters:
    ///   - gain: Gain in dB (typically -20.0 to +20.0, but can be any value)
    ///   - track: The track to set gain for
    func setTrackGain(_ gain: Float, for track: Track) async
    
    /// Remove track-specific gain (revert to global gain)
    /// - Parameter track: The track to remove gain for
    func removeTrackGain(for track: Track) async
    
    /// Get global gain (in dB)
    /// - Returns: Global gain in dB (default: 0.0)
    func getGlobalGain() async -> Float
    
    /// Set global gain (in dB)
    /// - Parameter gain: Global gain in dB (typically -20.0 to +20.0, but can be any value)
    func setGlobalGain(_ gain: Float) async
    
    /// Get effective gain for a track (track gain + global gain)
    /// - Parameter track: The track to get effective gain for
    /// - Returns: Effective gain in dB
    func getEffectiveGain(for track: Track) async -> Float
    
    /// Convert gain from dB to linear multiplier
    /// - Parameter gainDB: Gain in dB
    /// - Returns: Linear multiplier (e.g., 0.0 dB = 1.0, -6.0 dB = 0.5, +6.0 dB = 2.0)
    func gainDBToLinear(_ gainDB: Float) -> Float
    
    /// Convert gain from linear multiplier to dB
    /// - Parameter linear: Linear multiplier
    /// - Returns: Gain in dB
    func linearToGainDB(_ linear: Float) -> Float
}

/// Errors that can occur during gain control operations
public enum AudioGainControlError: Error, LocalizedError {
    case invalidGainValue(Float)
    case trackNotFound
    case gainCalculationFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidGainValue(let value):
            return "Invalid gain value: \(value) dB"
        case .trackNotFound:
            return "Track not found"
        case .gainCalculationFailed:
            return "Failed to calculate gain"
        }
    }
}
