//
//  PlaybackSpeed.swift
//  Shared
//
//  Playback speed enumeration for audio playback
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation

/// Playback speed options for audio playback
/// BDD: As a user, I want to control playback speed from 0.5x to 4x
public enum PlaybackSpeed: Double, CaseIterable, Codable, Equatable, Sendable {
    case half = 0.5
    case threeQuarter = 0.75
    case normal = 1.0
    case oneAndHalf = 1.5
    case double = 2.0
    case quadruple = 4.0
    
    /// Display name for the speed
    public var displayName: String {
        switch self {
        case .half: return "0.5x"
        case .threeQuarter: return "0.75x"
        case .normal: return "1x"
        case .oneAndHalf: return "1.5x"
        case .double: return "2x"
        case .quadruple: return "4x"
        }
    }
    
    /// Default playback speed
    public static let `default`: PlaybackSpeed = .normal
}
