//
//  CrossfadeProtocol.swift
//  AudioCore
//
//  Protocol for crossfade between tracks
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Crossfade configuration
public struct CrossfadeConfig: Equatable, Sendable {
    /// Crossfade duration in seconds
    public let duration: TimeInterval
    
    /// Fade curve type
    public let curve: CrossfadeCurve
    
    public init(duration: TimeInterval, curve: CrossfadeCurve = .linear) {
        self.duration = duration
        self.curve = curve
    }
}

/// Crossfade curve types
public enum CrossfadeCurve: Equatable, Sendable {
    case linear      // Linear fade
    case exponential // Exponential fade
    case logarithmic // Logarithmic fade
    case cosine      // Cosine (S-curve) fade
}

/// Protocol for crossfade between tracks
public protocol CrossfadeProtocol: Sendable {
    /// Apply crossfade between two audio buffers
    /// - Parameters:
    ///   - outgoingAudio: Audio samples from the outgoing track (fading out)
    ///   - incomingAudio: Audio samples from the incoming track (fading in)
    ///   - sampleRate: Sample rate in Hz
    ///   - channels: Number of audio channels
    ///   - config: Crossfade configuration
    /// - Returns: Crossfaded audio samples
    /// - Throws: Error if crossfade fails
    func applyCrossfade(
        outgoingAudio: [Float],
        incomingAudio: [Float],
        sampleRate: Int,
        channels: Int,
        config: CrossfadeConfig
    ) async throws -> [Float]
    
    /// Calculate number of samples needed for crossfade
    /// - Parameters:
    ///   - duration: Crossfade duration in seconds
    ///   - sampleRate: Sample rate in Hz
    ///   - channels: Number of audio channels
    /// - Returns: Number of samples needed (per channel)
    func calculateCrossfadeSamples(
        duration: TimeInterval,
        sampleRate: Int,
        channels: Int
    ) -> Int
    
    /// Apply fade out to audio samples
    /// - Parameters:
    ///   - audioData: Audio samples to fade out
    ///   - sampleRate: Sample rate in Hz
    ///   - channels: Number of audio channels
    ///   - duration: Fade out duration in seconds
    ///   - curve: Fade curve type
    /// - Returns: Faded out audio samples
    /// - Throws: Error if fade fails
    func applyFadeOut(
        audioData: [Float],
        sampleRate: Int,
        channels: Int,
        duration: TimeInterval,
        curve: CrossfadeCurve
    ) async throws -> [Float]
    
    /// Apply fade in to audio samples
    /// - Parameters:
    ///   - audioData: Audio samples to fade in
    ///   - sampleRate: Sample rate in Hz
    ///   - channels: Number of audio channels
    ///   - duration: Fade in duration in seconds
    ///   - curve: Fade curve type
    /// - Returns: Faded in audio samples
    /// - Throws: Error if fade fails
    func applyFadeIn(
        audioData: [Float],
        sampleRate: Int,
        channels: Int,
        duration: TimeInterval,
        curve: CrossfadeCurve
    ) async throws -> [Float]
}

/// Errors that can occur during crossfade operations
public enum CrossfadeError: Error, LocalizedError, Equatable {
    case invalidAudioData
    case invalidSampleRate
    case invalidChannelCount
    case invalidDuration
    case bufferMismatch
    case crossfadeFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidAudioData:
            return "Invalid audio data provided"
        case .invalidSampleRate:
            return "Invalid sample rate (must be > 0)"
        case .invalidChannelCount:
            return "Invalid channel count (must be > 0)"
        case .invalidDuration:
            return "Invalid duration (must be > 0)"
        case .bufferMismatch:
            return "Outgoing and incoming audio buffers must have same length"
        case .crossfadeFailed(let reason):
            return "Crossfade failed: \(reason)"
        }
    }
}
