//
//  VisualizationHelpers.swift
//  Audientia
//
//  Helper types and functions for audio visualization modes
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import SwiftUI

// MARK: - Configuration Structs

struct RadialBarsConfig {
    let processedData: (normalized: [CGFloat], colors: [Color])
    let center: CGPoint
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let angleStep: CGFloat
    let barWidth: CGFloat
    let numBars: Int
}

struct DashedArcConfig {
    let center: CGPoint
    let radius: CGFloat
    let startAngle: CGFloat
    let endAngle: CGFloat
    let dashLength: CGFloat
    let gapLength: CGFloat
}

struct LEDSegmentConfig {
    let height: CGFloat
    let gap: CGFloat
    var unit: CGFloat { height + gap }
}

struct LEDColumnConfig {
    let x: CGFloat
    let width: CGFloat
    let segmentConfig: LEDSegmentConfig
}

// MARK: - Color Utilities

/// Dynamic color based on frequency band and energy
/// Enhanced color mapping matching audioMotion-analyzer reference image
/// Reference: Deep teal/blue-green (low) → vibrant greens/lime (mid) → bright yellows/oranges (high)
func colorForFrequency(ratio: CGFloat, energy: CGFloat) -> Color {
    // Use energy directly with slight enhancement for vibrancy
    // Reference shows vibrant, saturated colors that respond to energy
    let enhancedEnergy = pow(energy, 0.7)
    
    // Low frequencies (31 Hz - ~250 Hz) - deep teal and blue-green
    if ratio < 0.25 {
        return Color(
            red: 0.0 + enhancedEnergy * 0.2,
            green: 0.4 + enhancedEnergy * 0.5,
            blue: 0.6 + enhancedEnergy * 0.4
        )
    }
    // Lower mid frequencies (~250 Hz - 500 Hz) - transitioning to vibrant greens
    else if ratio < 0.35 {
        return Color(
            red: 0.0 + enhancedEnergy * 0.3,
            green: 0.5 + enhancedEnergy * 0.5,
            blue: 0.5 + enhancedEnergy * 0.3
        )
    }
    // Mid frequencies (~500 Hz - 1 kHz) - vibrant greens and lime
    else if ratio < 0.5 {
        return Color(
            red: 0.2 + enhancedEnergy * 0.4,
            green: 0.7 + enhancedEnergy * 0.3,
            blue: 0.2 + enhancedEnergy * 0.2
        )
    }
    // Upper mid frequencies (1 kHz - 2 kHz) - bright yellows
    else if ratio < 0.65 {
        return Color(
            red: 0.7 + enhancedEnergy * 0.3,
            green: 0.8 + enhancedEnergy * 0.2,
            blue: 0.1 + enhancedEnergy * 0.1
        )
    }
    // High frequencies (2 kHz - 4 kHz) - bright oranges
    else if ratio < 0.8 {
        return Color(
            red: 0.9 + enhancedEnergy * 0.1,
            green: 0.5 + enhancedEnergy * 0.3,
            blue: 0.0 + enhancedEnergy * 0.1
        )
    }
    // Very high frequencies (4 kHz+) - reddish-orange, less intense
    else {
        return Color(
            red: 1.0,
            green: 0.3 + enhancedEnergy * 0.4,
            blue: 0.1 + enhancedEnergy * 0.2
        )
    }
}
