// AudioEngineError.swift
// Audientia - Audio Engine Error Types
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

import Foundation

/// Audio engine error types
public enum AudioEngineError: LocalizedError, Equatable {
    case noTrackLoaded
    case trackLoadFailed(String)
    case formatDetectionFailed
    case decodingFailed
    case outputInitializationFailed
    case outputWriteFailed
    case durationDetectionFailed
    case invalidSeekPosition
    case queueEmpty
    
    public var errorDescription: String? {
        switch self {
        case .noTrackLoaded:
            return "No track is currently loaded"
        case .trackLoadFailed(let reason):
            return "Failed to load track: \(reason)"
        case .formatDetectionFailed:
            return "Failed to detect audio format"
        case .decodingFailed:
            return "Failed to decode audio data"
        case .outputInitializationFailed:
            return "Failed to initialize audio output"
        case .outputWriteFailed:
            return "Failed to write audio data to output"
        case .durationDetectionFailed:
            return "Failed to detect track duration"
        case .invalidSeekPosition:
            return "Invalid seek position"
        case .queueEmpty:
            return "Playback queue is empty"
        }
    }
}
