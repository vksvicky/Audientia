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
    case discreteFrequencies
    case radialSpectrum
    case dualChannelGraph
    case ledBars
    case lumiBars
    case roundBarsReflex
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .discreteFrequencies:
            return "Discrete Frequencies"
        case .radialSpectrum:
            return "Radial Spectrum"
        case .dualChannelGraph:
            return "Dual Channel Graph"
        case .ledBars:
            return "LED Bars"
        case .lumiBars:
            return "LumiBars"
        case .roundBarsReflex:
            return "Round Bars + Reflex"
        }
    }
    
    public var icon: String {
        switch self {
        case .discreteFrequencies:
            return "chart.bar.xaxis"
        case .radialSpectrum:
            return "circle.grid.3x3.fill"
        case .dualChannelGraph:
            return "chart.line.uptrend.xyaxis"
        case .ledBars:
            return "lightbulb.fill"
        case .lumiBars:
            return "sun.max.fill"
        case .roundBarsReflex:
            return "circle.fill"
        }
    }
    
    public var description: String {
        switch self {
        case .discreteFrequencies:
            return "Discrete frequency bands"
        case .radialSpectrum:
            return "Circular radial spectrum"
        case .dualChannelGraph:
            return "Combined dual channel graph"
        case .ledBars:
            return "Discrete LED style bars"
        case .lumiBars:
            return "Luminance-based bars"
        case .roundBarsReflex:
            return "Round bars with reflex effect"
        }
    }
}
