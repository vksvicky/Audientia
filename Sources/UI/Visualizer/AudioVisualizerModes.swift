//
//  AudioVisualizerModes.swift
//  Audientia
//
//  Visualization mode implementations for AudioVisualizerView
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AudioCore
import SwiftUI

// MARK: - Visualization Mode Extensions
extension AudioVisualizerView {
    func spectrumLineView(frame: AudioVisualizerFrame, geometry: GeometryProxy) -> some View {
        let processedData = processMagnitudes(frame: frame)
        let path = createLinePath(magnitudes: processedData.normalized, geometry: geometry)
        
        return ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.4),
                    Color.black.opacity(0.1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Line path
            path
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue,
                            Color.cyan,
                            Color.green,
                            Color.yellow,
                            Color.orange,
                            Color.red
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
            
            // Filled area under curve
            path
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.3),
                            Color.cyan.opacity(0.2),
                            Color.green.opacity(0.1),
                            Color.clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }
    
    func spectrumMirrorView(frame: AudioVisualizerFrame, geometry: GeometryProxy) -> some View {
        let barWidth = geometry.size.width / CGFloat(frame.magnitudes.count)
        let processedData = processMagnitudes(frame: frame)
        let centerY = geometry.size.height / 2
        
        return ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.4),
                    Color.black.opacity(0.1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Top bars
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(Array(processedData.normalized.enumerated()), id: \.offset) { index, magnitude in
                    let barHeight = magnitude * centerY
                    let frequencyRatio = CGFloat(index) / CGFloat(processedData.normalized.count)
                    let color = colorForFrequency(ratio: frequencyRatio, energy: magnitude)
                    
                    VStack(spacing: 0) {
                        Spacer()
                        spectrumBar(barWidth: barWidth, barHeight: barHeight, color: color)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            
            // Bottom bars (mirrored)
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(processedData.normalized.enumerated()), id: \.offset) { index, magnitude in
                    let barHeight = magnitude * centerY
                    let frequencyRatio = CGFloat(index) / CGFloat(processedData.normalized.count)
                    let color = colorForFrequency(ratio: frequencyRatio, energy: magnitude)
                    
                    VStack(spacing: 0) {
                        spectrumBar(barWidth: barWidth, barHeight: barHeight, color: color)
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
    
    func spectrumRadialView(frame: AudioVisualizerFrame, geometry: GeometryProxy) -> some View {
        let processedData = processMagnitudes(frame: frame)
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let radius = min(geometry.size.width, geometry.size.height) / 2 - 20
        let angleStep = (2 * .pi) / CGFloat(processedData.normalized.count)
        
        return ZStack {
            // Background
            Color.black.opacity(0.3)
            
            // Radial bars
            ForEach(Array(processedData.normalized.enumerated()), id: \.offset) { index, magnitude in
                let angle = CGFloat(index) * angleStep - .pi / 2
                let barLength = magnitude * radius
                let frequencyRatio = CGFloat(index) / CGFloat(processedData.normalized.count)
                let color = colorForFrequency(ratio: frequencyRatio, energy: magnitude)
                
                Path { path in
                    path.move(to: center)
                    let endX = center.x + cos(angle) * barLength
                    let endY = center.y + sin(angle) * barLength
                    path.addLine(to: CGPoint(x: endX, y: endY))
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
        }
    }
    
    func spectrumLuminanceView(frame: AudioVisualizerFrame, geometry: GeometryProxy) -> some View {
        let barWidth = geometry.size.width / CGFloat(frame.magnitudes.count)
        let processedData = processMagnitudes(frame: frame)
        
        return ZStack {
            // Background
            Color.black
            
            // Luminance bars (brightness based on energy)
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(Array(processedData.normalized.enumerated()), id: \.offset) { index, magnitude in
                    let barHeight = magnitude * geometry.size.height
                    let brightness = magnitude
                    let frequencyRatio = CGFloat(index) / CGFloat(processedData.normalized.count)
                    
                    // White to colored based on frequency, brightness based on energy
                    let baseColor = colorForFrequency(ratio: frequencyRatio, energy: 1.0)
                    // Use opacity for luminance effect since we can't directly access color components
                    let luminanceColor = baseColor.opacity(Double(brightness))
                    
                    VStack(spacing: 0) {
                        Spacer()
                        RoundedRectangle(cornerRadius: max(1, barWidth * 0.3))
                            .fill(luminanceColor)
                            .frame(
                                width: max(1, barWidth - 1),
                                height: max(2, barHeight)
                            )
                            .shadow(color: luminanceColor.opacity(0.8), radius: 3, x: 0, y: -2)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }
    
    func spectrumLEDView(frame: AudioVisualizerFrame, geometry: GeometryProxy) -> some View {
        let barWidth = geometry.size.width / CGFloat(frame.magnitudes.count)
        let processedData = processMagnitudes(frame: frame)
        
        return ZStack {
            // Background
            Color.black
            
            // LED bars (discrete, rounded, bright)
            HStack(alignment: .bottom, spacing: 1) {
                ForEach(Array(processedData.normalized.enumerated()), id: \.offset) { index, magnitude in
                    let barHeight = magnitude * geometry.size.height
                    let frequencyRatio = CGFloat(index) / CGFloat(processedData.normalized.count)
                    let color = colorForFrequency(ratio: frequencyRatio, energy: magnitude)
                    
                    VStack(spacing: 0) {
                        Spacer()
                        Circle()
                            .fill(color)
                            .frame(
                                width: max(3, barWidth - 2),
                                height: max(3, barWidth - 2)
                            )
                            .shadow(color: color.opacity(0.9), radius: 4, x: 0, y: 0)
                        
                        // LED bar
                        RoundedRectangle(cornerRadius: barWidth / 2)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        color.opacity(0.9),
                                        color.opacity(0.6)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(
                                width: max(2, barWidth - 2),
                                height: max(2, barHeight)
                            )
                            .shadow(color: color.opacity(0.8), radius: 2, x: 0, y: -1)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }
    
    func spectrumWaveformView(frame: AudioVisualizerFrame, geometry: GeometryProxy) -> some View {
        let processedData = processMagnitudes(frame: frame)
        let centerY = geometry.size.height / 2
        
        return ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.4),
                    Color.black.opacity(0.1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Waveform path (both positive and negative)
            Path { path in
                let stepX = geometry.size.width / CGFloat(processedData.normalized.count)
                var x: CGFloat = 0
                
                path.move(to: CGPoint(x: 0, y: centerY))
                
                for (index, magnitude) in processedData.normalized.enumerated() {
                    let frequencyRatio = CGFloat(index) / CGFloat(processedData.normalized.count)
                    _ = colorForFrequency(ratio: frequencyRatio, energy: magnitude)
                    let amplitude = magnitude * centerY * 0.8
                    
                    path.addLine(to: CGPoint(x: x, y: centerY - amplitude))
                    x += stepX
                }
                
                // Return path
                for magnitude in processedData.normalized.reversed() {
                    let amplitude = magnitude * centerY * 0.8
                    x -= geometry.size.width / CGFloat(processedData.normalized.count)
                    path.addLine(to: CGPoint(x: x, y: centerY + amplitude))
                }
                
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.6),
                        Color.cyan.opacity(0.4),
                        Color.green.opacity(0.3)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
    
    func spectrumCircleView(frame: AudioVisualizerFrame, geometry: GeometryProxy) -> some View {
        let processedData = processMagnitudes(frame: frame)
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let baseRadius = min(geometry.size.width, geometry.size.height) / 4
        let angleStep = (2 * .pi) / CGFloat(processedData.normalized.count)
        
        return ZStack {
            // Background
            Color.black.opacity(0.3)
            
            // Circular bars
            ForEach(Array(processedData.normalized.enumerated()), id: \.offset) { index, magnitude in
                let angle = CGFloat(index) * angleStep - .pi / 2
                let radius = baseRadius + magnitude * baseRadius * 1.5
                let frequencyRatio = CGFloat(index) / CGFloat(processedData.normalized.count)
                let color = colorForFrequency(ratio: frequencyRatio, energy: magnitude)
                
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                color.opacity(0.9),
                                color.opacity(0.3)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 5
                        )
                    )
                    .frame(width: 8, height: 8)
                    .position(
                        x: center.x + cos(angle) * radius,
                        y: center.y + sin(angle) * radius
                    )
                    .shadow(color: color.opacity(0.8), radius: 3, x: 0, y: 0)
            }
        }
    }
    
    func processMagnitudes(frame: AudioVisualizerFrame) -> (normalized: [CGFloat], colors: [Color]) {
        let normalizer = SpectrumNormalizer(
            logScale: 2.0,
            minFreq: 20.0,
            maxFreq: 20000.0,
            sampleRate: frame.sampleRate,
            fftSize: frame.fftSize
        )
        let normalizedMagnitudes = normalizer.normalize(frame.magnitudes)
        let compressedMagnitudes = normalizer.compress(normalizedMagnitudes, sensitivity: 1.2)
        
        let amplificationFactor: Float = 2.5
        let amplifiedMagnitudes = compressedMagnitudes.map { $0 * amplificationFactor }
        
        let maxMagnitude = amplifiedMagnitudes.max() ?? 1.0
        let minMagnitude = amplifiedMagnitudes.min() ?? 0.0
        let range = max(maxMagnitude - minMagnitude, 1.0)
        
        let normalized = amplifiedMagnitudes.map { magnitude in
            CGFloat((magnitude - minMagnitude) / range)
        }
        
        return (normalized, [])
    }
    
    func createLinePath(magnitudes: [CGFloat], geometry: GeometryProxy) -> Path {
        var path = Path()
        guard !magnitudes.isEmpty else { return path }
        
        let stepX = geometry.size.width / CGFloat(magnitudes.count - 1)
        let maxHeight = geometry.size.height
        
        path.move(to: CGPoint(x: 0, y: maxHeight - magnitudes[0] * maxHeight))
        
        for (index, magnitude) in magnitudes.enumerated() where index > 0 {
            let x = CGFloat(index) * stepX
            let y = maxHeight - magnitude * maxHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // Close path for fill
        path.addLine(to: CGPoint(x: geometry.size.width, y: maxHeight))
        path.addLine(to: CGPoint(x: 0, y: maxHeight))
        path.closeSubpath()
        
        return path
    }
    
    // Dynamic color based on frequency band and energy
    // Enhanced color mapping similar to audioMotion-analyzer with better visual response
    func colorForFrequency(ratio: CGFloat, energy: CGFloat) -> Color {
        // Use gamma correction for better visual energy response
        let enhancedEnergy = pow(energy, 0.7)
        
        // Low frequencies (bass) - deep blue to cyan
        if ratio < 0.25 {
            return Color(
                red: 0.1 + enhancedEnergy * 0.4,
                green: 0.3 + enhancedEnergy * 0.5,
                blue: 0.9 + enhancedEnergy * 0.1
            )
        }
        // Lower mid frequencies - cyan to green
        else if ratio < 0.4 {
            return Color(
                red: 0.2 + enhancedEnergy * 0.3,
                green: 0.7 + enhancedEnergy * 0.3,
                blue: 0.8 + enhancedEnergy * 0.2
            )
        }
        // Mid frequencies - green to yellow
        else if ratio < 0.55 {
            return Color(
                red: 0.5 + enhancedEnergy * 0.4,
                green: 0.8 + enhancedEnergy * 0.2,
                blue: 0.3 + enhancedEnergy * 0.2
            )
        }
        // Upper mid frequencies - yellow to orange
        else if ratio < 0.7 {
            return Color(
                red: 0.9 + enhancedEnergy * 0.1,
                green: 0.6 + enhancedEnergy * 0.3,
                blue: 0.2 + enhancedEnergy * 0.2
            )
        }
        // High frequencies - orange to red/pink
        else {
            return Color(
                red: 1.0,
                green: 0.3 + enhancedEnergy * 0.4,
                blue: 0.4 + enhancedEnergy * 0.3
            )
        }
    }
}
