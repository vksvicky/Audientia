// PlaybackState.swift
// Audientia - Audio Engine Playback State
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

import Foundation

/// Playback state enumeration
public enum PlaybackState: Equatable {
    case stopped
    case playing
    case paused
    case loading
    case error(String)
}
