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
    
    /// Asset catalog image name for the visualization mode icon
    /// Falls back to SF Symbol if custom image is not available
    public var iconImageName: String {
        switch self {
        case .discreteFrequencies:
            return "VisualizationIcon.discreteFrequencies"
        case .radialSpectrum:
            return "VisualizationIcon.radialSpectrum"
        case .dualChannelGraph:
            return "VisualizationIcon.dualChannelGraph"
        case .ledBars:
            return "VisualizationIcon.ledBars"
        case .lumiBars:
            return "VisualizationIcon.lumiBars"
        case .roundBarsReflex:
            return "VisualizationIcon.roundBarsReflex"
        }
    }
    
    /// SF Symbol name as fallback when custom image is not available
    public var iconSystemName: String {
        switch self {
        case .discreteFrequencies:
            return "chart.bar.fill"
        case .radialSpectrum:
            return "waveform.circle.fill"
        case .dualChannelGraph:
            return "waveform.path"
        case .ledBars:
            return "square.stack"
        case .lumiBars:
            return "sparkles"
        case .roundBarsReflex:
            return "circle.circle"
        }
    }
    
    /// Legacy property for backward compatibility
    @available(*, deprecated, message: "Use iconImageName or iconSystemName instead")
    public var icon: String {
        iconSystemName
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
