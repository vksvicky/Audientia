//
//  VisualizationMode.swift
//  Audientia
//
//  Visualization mode enum for audio visualizer
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation

/// Visualization modes inspired by audioMotion-analyzer
/// Each mode provides a unique way to visualize audio spectrum data
public enum VisualizationMode: String, CaseIterable, Identifiable {
    case bars
    case line
    case mirror
    case radial
    case luminance
    case led
    case waveform
    case circle
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .bars:
            return "Bars"
        case .line:
            return "Line"
        case .mirror:
            return "Mirror"
        case .radial:
            return "Radial"
        case .luminance:
            return "Luminance"
        case .led:
            return "LED"
        case .waveform:
            return "Waveform"
        case .circle:
            return "Circle"
        }
    }
    
    public var icon: String {
        switch self {
        case .bars:
            return "chart.bar.fill"
        case .line:
            return "chart.line.uptrend.xyaxis"
        case .mirror:
            return "arrow.up.arrow.down"
        case .radial:
            return "circle.grid.3x3.fill"
        case .luminance:
            return "sun.max.fill"
        case .led:
            return "lightbulb.fill"
        case .waveform:
            return "waveform.path"
        case .circle:
            return "circle.fill"
        }
    }
    
    public var description: String {
        switch self {
        case .bars:
            return "Classic vertical bars"
        case .line:
            return "Continuous line graph"
        case .mirror:
            return "Bars with reflection"
        case .radial:
            return "Circular spectrum"
        case .luminance:
            return "Brightness-based bars"
        case .led:
            return "Discrete LED style"
        case .waveform:
            return "Waveform visualization"
        case .circle:
            return "Circular bars"
        }
    }
}
