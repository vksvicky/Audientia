//
//  AudioVisualizerModes.swift
//  Audientia
//
//  Visualization mode implementations for AudioVisualizerView
//  Algorithms based on audioMotion-analyzer.js (https://github.com/hvianna/audioMotion-analyzer)
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AudioCore
import Foundation
import SwiftUI

// MARK: - Visualization Mode Extensions
extension AudioVisualizerView {
    /// Discrete Frequencies (Mode 0) - Each FFT bin as a separate bar
    /// Based on audioMotion-analyzer's discrete mode algorithm
    /// Matches the reference: https://github.com/hvianna/audioMotion-analyzer/blob/master/demo/media/discrete.png
    /// 
    /// Algorithm from audioMotion-analyzer.js:
    /// - mode: 0 (discrete)
    /// - frequencyScale: SCALE_LOG (default) - uses logarithmic frequency mapping
    /// - barSpace: 0.1 (10% spacing)
    /// - minDecibels: -85, maxDecibels: -25
    /// - Uses _normalizedB() for dB normalization
    /// - _calcBars() calculates bar positions with logarithmic frequency scaling
    func discreteFrequenciesView(frame: AudioVisualizerFrame, geometry: GeometryProxy) -> some View {
        // audioMotion-analyzer uses logarithmic frequency scaling even for discrete mode
        // The bars are positioned logarithmically, but each bar represents a single FFT bin
        let numBars = frame.magnitudes.count
        
        // Calculate bar spacing (audioMotion-analyzer uses barSpace, default 0.1 = 10%)
        let barSpace: CGFloat = 0.1 // 10% spacing between bars
        let totalWidth = geometry.size.width
        let totalBarWidth = totalWidth / CGFloat(numBars)
        
        // Calculate actual bar width and spacing
        let spacing = totalBarWidth * barSpace
        let barWidth = totalBarWidth - spacing
        
        // Normalize magnitudes using dB scale (audioMotion-analyzer's _normalizedB algorithm)
        // CRITICAL: audioMotion-analyzer uses Web Audio API's AnalyserNode.getFloatFrequencyData()
        // which returns values already in dB range. Our FFT magnitudes are linear, so we convert properly.
        //
        // audioMotion-analyzer's _normalizedB algorithm (when linearAmplitude = false):
        // 1. Input is already in dB (from getFloatFrequencyData, typically -140 to 0 dB)
        // 2. Clamp to [minDecibels, maxDecibels]
        // 3. Normalize: (dB - minDecibels) / (maxDecibels - minDecibels)
        //
        // For our linear magnitudes from vDSP FFT:
        // - Magnitudes are typically in range 0.0 to ~0.1 (after normalization by fftSize)
        // - We need to scale them properly before converting to dB
        
        let minDecibels: Float = -85.0
        let maxDecibels: Float = -25.0
        
        // Find max magnitude for relative normalization
        // CRITICAL: audioMotion-analyzer normalizes relative to maximum to ensure full dynamic range
        // This ensures the loudest frequency always maps to full height
        let maxMagnitude = frame.magnitudes.max() ?? 1.0
        
        // Normalize magnitudes relative to max, then convert to dB
        // This matches audioMotion-analyzer's approach: normalize first, then apply dB scaling
        let normalizedMagnitudes = frame.magnitudes.map { magnitude in
            // Step 1: Normalize relative to max (0.0 to 1.0)
            // This ensures full dynamic range - max magnitude = 1.0
            let relativeMagnitude = maxMagnitude > 0 ? magnitude / maxMagnitude : 0.0
            
            // Step 2: Convert to dB: 20 * log10(relativeMagnitude)
            // When relativeMagnitude = 1.0 (max), dB = 0
            // When relativeMagnitude = 0.001, dB ≈ -60
            // We need to map this to -85 to -25 dB range
            let dbValue: Float
            if relativeMagnitude > 0 {
                let rawDb = 20.0 * log10(relativeMagnitude)
                // Scale and shift to match audioMotion-analyzer's -85 to -25 dB range
                // Map 0 dB (max, relativeMagnitude = 1.0) to -25 dB
                // Map -60 dB (quiet, relativeMagnitude ≈ 0.001) to -85 dB
                // Formula: scaledDb = rawDb * scale + offset
                // When rawDb = 0: scaledDb = -25, so offset = -25
                // When rawDb = -60: scaledDb = -85, so -60 * scale - 25 = -85
                // Solving: scale = (-85 + 25) / -60 = -60 / -60 = 1.0
                // Actually, we want: 0 dB -> -25 dB, -60 dB -> -85 dB
                // So: scale = (-85 - (-25)) / (-60 - 0) = -60 / -60 = 1.0
                // But this doesn't work. Let's use a different approach:
                // Map the range [0, -60] dB to [-25, -85] dB
                // scaledDb = -25 + (rawDb / -60) * (-85 - (-25))
                // scaledDb = -25 + (rawDb / -60) * -60
                // scaledDb = -25 + rawDb
                // So we just shift by -25 dB
                dbValue = rawDb - 25.0
            } else {
                dbValue = minDecibels
            }
            
            // Step 3: Clamp to range (audioMotion-analyzer's clamp function)
            let clamped = max(minDecibels, min(maxDecibels, dbValue))
            
            // Step 4: Normalize to 0-1 range: (value - minValue) / (maxValue - minValue)
            // This matches audioMotion-analyzer's _normalizedB when linearAmplitude = false, boost = 1
            let normalized = (clamped - minDecibels) / (maxDecibels - minDecibels)
            
            // Clamp final result to [0, 1] range
            return CGFloat(max(0.0, min(1.0, normalized)))
        }
        
        return Canvas { context, size in
            // Background - solid black (audioMotion-analyzer uses #000)
            context.fill(
                Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 0),
                with: .color(.black)
            )
            
            // Draw each FFT bin as a separate bar (discrete mode)
            // audioMotion-analyzer positions bars with logarithmic frequency scaling
            // but each bar represents a single FFT bin
            for (index, normalizedMagnitude) in normalizedMagnitudes.enumerated() {
                // Calculate bar position - evenly spaced (audioMotion-analyzer's _calcBars for mode 0)
                let barStartX = CGFloat(index) * totalBarWidth
                let barX = barStartX + spacing / 2
                
                // Calculate bar height from normalized magnitude
                // audioMotion-analyzer uses normalized value directly for height
                let barHeight = normalizedMagnitude * size.height
                
                // Calculate frequency ratio for color mapping
                // Use linear position (index/numBars) for frequency ratio
                // audioMotion-analyzer uses frequency position for gradient color mapping
                let frequencyRatio = CGFloat(index) / CGFloat(numBars)
                let color = colorForFrequency(ratio: frequencyRatio, energy: normalizedMagnitude)
                
                // Draw bar with integer coordinates for crisp rendering
                let barRect = CGRect(
                    x: round(barX),
                    y: round(size.height - barHeight),
                    width: max(1, round(barWidth)),
                    height: max(1, round(barHeight))
                )
                
                let barPath = Path(roundedRect: barRect, cornerRadius: 0)
                context.fill(barPath, with: .color(color))
            }
        }
    }
    
    /// Radial Spectrum - Circular spectrum radiating from center
    /// Based on audioMotion-analyzer's radial mode algorithm
    func radialSpectrumView(frame: AudioVisualizerFrame, geometry: GeometryProxy) -> some View {
        let processedData = processMagnitudes(frame: frame)
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let radius = min(geometry.size.width, geometry.size.height) / 2 - 20
        let angleStep = (2 * .pi) / CGFloat(processedData.normalized.count)
        
        return Canvas { context, size in
            // Background
            context.fill(
                Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 0),
                with: .color(.black.opacity(0.3))
            )
            
            // Draw radial bars
            for (index, magnitude) in processedData.normalized.enumerated() {
                let angle = CGFloat(index) * angleStep - .pi / 2
                let barLength = magnitude * radius
                let frequencyRatio = CGFloat(index) / CGFloat(processedData.normalized.count)
                let color = colorForFrequency(ratio: frequencyRatio, energy: magnitude)
                
                let endX = center.x + cos(angle) * barLength
                let endY = center.y + sin(angle) * barLength
                
                var path = Path()
                path.move(to: center)
                path.addLine(to: CGPoint(x: round(endX), y: round(endY)))
                
                context.stroke(path, with: .color(color), lineWidth: 2)
            }
        }
    }
    
    /// Dual Channel Combined Graph - Combined left/right channel visualization
    /// Based on audioMotion-analyzer's dual-combined channel layout
    func dualChannelGraphView(frame: AudioVisualizerFrame, geometry: GeometryProxy) -> some View {
        let processedData = processMagnitudes(frame: frame)
        let centerY = geometry.size.height / 2
        let stepX = geometry.size.width / CGFloat(processedData.normalized.count - 1)
        
        return Canvas { context, size in
            // Background
            context.fill(
                Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 0),
                with: .color(.black.opacity(0.4))
            )
            
            // Draw combined graph path (top half)
            var topPath = Path()
            var topPoints: [CGPoint] = []
            var firstPoint = true
            
            for (index, magnitude) in processedData.normalized.enumerated() {
                let x = CGFloat(index) * stepX
                let amplitude = magnitude * centerY * 0.8
                let frequencyRatio = CGFloat(index) / CGFloat(processedData.normalized.count)
                _ = colorForFrequency(ratio: frequencyRatio, energy: magnitude)
                
                let point = CGPoint(x: round(x), y: round(centerY - amplitude))
                topPoints.append(point)
                
                if firstPoint {
                    topPath.move(to: point)
                    firstPoint = false
                } else {
                    topPath.addLine(to: point)
                }
            }
            
            // Draw bottom half (mirrored)
            var bottomPath = Path()
            var bottomPoints: [CGPoint] = []
            firstPoint = true
            
            for (index, magnitude) in processedData.normalized.enumerated() {
                let x = CGFloat(index) * stepX
                let amplitude = magnitude * centerY * 0.8
                let point = CGPoint(x: round(x), y: round(centerY + amplitude))
                bottomPoints.append(point)
                
                if firstPoint {
                    bottomPath.move(to: point)
                    firstPoint = false
                } else {
                    bottomPath.addLine(to: point)
                }
            }
            
            // Fill area between paths by creating a closed path
            var fillPath = topPath
            // Add bottom path in reverse order (from last point to first)
            for point in bottomPoints.reversed() {
                fillPath.addLine(to: point)
            }
            fillPath.closeSubpath()
            
            context.fill(fillPath, with: .color(.blue.opacity(0.3)))
            context.stroke(topPath, with: .color(.blue), lineWidth: 2)
            context.stroke(bottomPath, with: .color(.cyan), lineWidth: 2)
        }
    }
    
    /// LED Bars - Discrete LED-style bars with bright, crisp appearance
    /// Based on audioMotion-analyzer's ledBars mode
    func ledBarsView(frame: AudioVisualizerFrame, geometry: GeometryProxy) -> some View {
        let processedData = processMagnitudes(frame: frame)
        let numBars = processedData.normalized.count
        
        // Calculate bar spacing (similar to discrete but with LED styling)
        let barSpace: CGFloat = 0.05 // 5% spacing for LED bars
        let totalBarWidth = geometry.size.width / CGFloat(numBars)
        let barWidth = totalBarWidth * (1.0 - barSpace)
        
        return Canvas { context, size in
            // Background - solid black
            context.fill(
                Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 0),
                with: .color(.black)
            )
            
            // Draw LED bars
            for (index, magnitude) in processedData.normalized.enumerated() {
                let x = CGFloat(index) * totalBarWidth
                let barHeight = magnitude * size.height
                let frequencyRatio = CGFloat(index) / CGFloat(numBars)
                let color = colorForFrequency(ratio: frequencyRatio, energy: magnitude)
                
                // LED indicator at top (bright circle)
                let ledSize: CGFloat = 4
                let ledRect = CGRect(
                    x: round(x + totalBarWidth / 2 - ledSize / 2),
                    y: round(size.height - barHeight - ledSize - 2),
                    width: ledSize,
                    height: ledSize
                )
                let ledPath = Path(ellipseIn: ledRect)
                context.fill(ledPath, with: .color(color))
                
                // LED bar (rounded rectangle)
                let barRect = CGRect(
                    x: round(x + totalBarWidth * barSpace / 2),
                    y: round(size.height - barHeight),
                    width: max(2, round(barWidth)),
                    height: max(2, round(barHeight))
                )
                let barPath = Path(roundedRect: barRect, cornerRadius: barRect.width / 2)
                context.fill(barPath, with: .color(color))
            }
        }
    }
    
    /// LumiBars - Luminance-based bars with brightness effect
    /// Based on audioMotion-analyzer's lumiBars mode
    func lumiBarsView(frame: AudioVisualizerFrame, geometry: GeometryProxy) -> some View {
        let processedData = processMagnitudes(frame: frame)
        let numBars = processedData.normalized.count
        
        // Calculate bar spacing
        let barSpace: CGFloat = 0.1
        let totalBarWidth = geometry.size.width / CGFloat(numBars)
        let barWidth = totalBarWidth * (1.0 - barSpace)
        
        return Canvas { context, size in
            // Background - solid black
            context.fill(
                Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 0),
                with: .color(.black)
            )
            
            // Draw LumiBars with brightness-based opacity
            for (index, magnitude) in processedData.normalized.enumerated() {
                let x = CGFloat(index) * totalBarWidth
                let barHeight = magnitude * size.height
                let brightness = magnitude // Brightness = magnitude
                let frequencyRatio = CGFloat(index) / CGFloat(numBars)
                
                // Base color with brightness applied (audioMotion-analyzer uses opacity for luminance)
                let baseColor = colorForFrequency(ratio: frequencyRatio, energy: 1.0)
                let lumiColor = baseColor.opacity(Double(brightness))
                
                let barRect = CGRect(
                    x: round(x + totalBarWidth * barSpace / 2),
                    y: round(size.height - barHeight),
                    width: max(1, round(barWidth)),
                    height: max(1, round(barHeight))
                )
                let barPath = Path(roundedRect: barRect, cornerRadius: 0)
                context.fill(barPath, with: .color(lumiColor))
            }
        }
    }
    
    /// Round Bars + Reflex - Round bars with reflection effect
    /// Based on audioMotion-analyzer's roundBars + reflexRatio algorithm
    func roundBarsReflexView(frame: AudioVisualizerFrame, geometry: GeometryProxy) -> some View {
        let processedData = processMagnitudes(frame: frame)
        let numBars = processedData.normalized.count
        let centerY = geometry.size.height / 2
        
        // Calculate bar spacing
        let barSpace: CGFloat = 0.1
        let totalBarWidth = geometry.size.width / CGFloat(numBars)
        let barWidth = totalBarWidth * (1.0 - barSpace)
        
        // Reflex settings (audioMotion-analyzer uses reflexRatio and reflexAlpha)
        let reflexRatio: CGFloat = 0.5 // Ratio of reflex height to bar height
        let reflexAlpha: CGFloat = 0.15 // Opacity of reflex
        
        return Canvas { context, size in
            // Background
            context.fill(
                Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 0),
                with: .color(.black.opacity(0.3))
            )
            
            // Draw round bars with reflex (reflection) effect
            for (index, magnitude) in processedData.normalized.enumerated() {
                let x = CGFloat(index) * totalBarWidth + totalBarWidth / 2
                let barHeight = magnitude * centerY
                let frequencyRatio = CGFloat(index) / CGFloat(numBars)
                let color = colorForFrequency(ratio: frequencyRatio, energy: magnitude)
                
                // Top bar (round)
                let topBarRect = CGRect(
                    x: round(x - barWidth / 2),
                    y: round(centerY - barHeight),
                    width: max(2, round(barWidth)),
                    height: max(2, round(barHeight))
                )
                let topBarPath = Path(roundedRect: topBarRect, cornerRadius: topBarRect.width / 2)
                context.fill(topBarPath, with: .color(color))
                
                // Reflex (reflection) - bottom bar with reduced opacity
                let reflexHeight = barHeight * reflexRatio
                let reflexBarRect = CGRect(
                    x: round(x - barWidth / 2),
                    y: round(centerY),
                    width: max(2, round(barWidth)),
                    height: max(2, round(reflexHeight))
                )
                let reflexBarPath = Path(roundedRect: reflexBarRect, cornerRadius: reflexBarRect.width / 2)
                context.fill(reflexBarPath, with: .color(color.opacity(reflexAlpha)))
            }
        }
    }
    
    /// Process magnitudes using audioMotion-analyzer's normalization algorithm
    /// Converts raw FFT magnitudes to normalized values for visualization
    internal func processMagnitudes(frame: AudioVisualizerFrame) -> (normalized: [CGFloat], colors: [Color]) {
        // Use logarithmic normalization similar to audioMotion-analyzer
        let normalizer = SpectrumNormalizer(
            logScale: 2.0,
            minFreq: 20.0,
            maxFreq: 20000.0,
            sampleRate: frame.sampleRate,
            fftSize: frame.fftSize
        )
        let normalizedMagnitudes = normalizer.normalize(frame.magnitudes)
        let compressedMagnitudes = normalizer.compress(normalizedMagnitudes, sensitivity: 1.2)
        
        // Apply amplification factor for better visibility (2.5x as requested)
        let amplificationFactor: Float = 2.5
        let amplifiedMagnitudes = compressedMagnitudes.map { $0 * amplificationFactor }
        
        // Normalize to 0-1 range (audioMotion-analyzer uses _normalizedB for dB normalization)
        let maxMagnitude = amplifiedMagnitudes.max() ?? 1.0
        let minMagnitude = amplifiedMagnitudes.min() ?? 0.0
        let range = max(maxMagnitude - minMagnitude, 1.0)
        
        let normalized = amplifiedMagnitudes.map { magnitude in
            CGFloat((magnitude - minMagnitude) / range)
        }
        
        return (normalized, [])
    }
    
    /// Dynamic color based on frequency band and energy
    /// Enhanced color mapping matching audioMotion-analyzer reference image
    /// Reference: Deep teal/blue-green (low) → vibrant greens/lime (mid) → bright yellows/oranges (high)
    internal func colorForFrequency(ratio: CGFloat, energy: CGFloat) -> Color {
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
}
