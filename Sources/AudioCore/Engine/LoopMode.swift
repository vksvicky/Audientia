// LoopMode.swift
// Audientia - Playback Loop Mode
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

import Foundation

/// Playback loop mode
public enum LoopMode: Equatable, CustomStringConvertible {
    /// No looping - playback stops at end
    case none
    
    /// Loop current track - replay when track finishes
    case track
    
    /// Loop entire queue - restart from first track when queue finishes
    case queue
    
    public var description: String {
        switch self {
        case .none:
            return "none"
        case .track:
            return "track"
        case .queue:
            return "queue"
        }
    }
}
