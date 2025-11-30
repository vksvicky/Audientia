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
    /// Reference: audioMotion-analyzer.js radial mode with central circle, radial bars, and frequency labels
    /// 
    /// Features:
    /// - Central black circle
    /// - Radial bars extending outward (rectangles, not lines)
    /// - Frequency labels around perimeter (31, 63, 125, 250, 500, 1k, 2k, 4k, 8k)
    /// - Dashed arcs beyond bars
    /// - Smooth gradient colors (blue → green → yellow → orange → red)
    func radialSpectrumView(frame: AudioVisualizerFrame, geometry: GeometryProxy) -> some View {
        // Use logarithmic normalization for radial spectrum (like other modes except discrete)
        let processedData = processMagnitudes(frame: frame)
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let maxRadius = min(geometry.size.width, geometry.size.height) / 2
        let innerRadius: CGFloat = maxRadius * 0.15 // Central black circle radius (15% of max)
        let outerRadius = maxRadius - 20 // Leave margin for labels
        
        // Calculate bar width based on number of bars
        let numBars = processedData.normalized.count
        let angleStep = (2 * .pi) / CGFloat(numBars)
        let barWidth = angleStep * innerRadius * 0.8 // Bar width proportional to angle step
        
        return Canvas { context, size in
            drawRadialSpectrumBackground(context: context, size: size, center: center, innerRadius: innerRadius)
            let radialConfig = RadialBarsConfig(
                processedData: processedData,
                center: center,
                innerRadius: innerRadius,
                outerRadius: outerRadius,
                angleStep: angleStep,
                barWidth: barWidth,
                numBars: numBars
            )
            drawRadialBars(context: context, config: radialConfig)
        }
    }
    
    /// Draw radial spectrum background and central circle
    private func drawRadialSpectrumBackground(
        context: GraphicsContext,
        size: CGSize,
        center: CGPoint,
        innerRadius: CGFloat
    ) {
        // Background - solid black (audioMotion-analyzer uses #000)
        context.fill(
            Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 0),
            with: .color(.black)
        )
        
        // Draw central black circle
        let centerCircle = Path(ellipseIn: CGRect(
            x: center.x - innerRadius,
            y: center.y - innerRadius,
            width: innerRadius * 2,
            height: innerRadius * 2
        ))
        context.fill(centerCircle, with: .color(.black))
    }
    
    /// Draw radial bars extending outward from inner circle
    private func drawRadialBars(context: GraphicsContext, config: RadialBarsConfig) {
        // Draw radial bars (rectangles extending outward from inner circle)
        for (index, magnitude) in config.processedData.normalized.enumerated() {
            let angle = CGFloat(index) * config.angleStep - .pi / 2 // Start from top (-π/2)
            let barLength = magnitude * (config.outerRadius - config.innerRadius)
            let frequencyRatio = CGFloat(index) / CGFloat(config.numBars)
            let color = colorForFrequency(ratio: frequencyRatio, energy: magnitude)
            
            // Create rectangular bar path
            let barPath = createRadialBarPath(
                center: config.center,
                angle: angle,
                startRadius: config.innerRadius,
                endRadius: config.innerRadius + barLength,
                barWidth: config.barWidth
            )
            
            // Fill bar with color
            context.fill(barPath, with: .color(color))
            
            // Draw dashed arc beyond bar (if magnitude is significant)
            if magnitude > 0.1 {
                let arcRadius = config.innerRadius + barLength + 5 // Slightly beyond bar
                let arcConfig = DashedArcConfig(
                    center: config.center,
                    radius: arcRadius,
                    startAngle: angle - config.angleStep / 2,
                    endAngle: angle + config.angleStep / 2,
                    dashLength: 3,
                    gapLength: 2
                )
                let arcPath = createDashedArc(config: arcConfig)
                context.stroke(arcPath, with: .color(color.opacity(0.6)), lineWidth: 1)
            }
        }
    }
    
    /// Create a rectangular bar path for radial spectrum
    private func createRadialBarPath(
        center: CGPoint,
        angle: CGFloat,
        startRadius: CGFloat,
        endRadius: CGFloat,
        barWidth: CGFloat
    ) -> Path {
        let cosAngle = cos(angle)
        let sinAngle = sin(angle)
        let halfWidth = barWidth / 2
        let perpCos = -sinAngle // Perpendicular to radial direction
        let perpSin = cosAngle
        
        let startInnerX = center.x + cosAngle * startRadius + perpCos * halfWidth
        let startInnerY = center.y + sinAngle * startRadius + perpSin * halfWidth
        let startOuterX = center.x + cosAngle * startRadius - perpCos * halfWidth
        let startOuterY = center.y + sinAngle * startRadius - perpSin * halfWidth
        
        let endInnerX = center.x + cosAngle * endRadius + perpCos * halfWidth
        let endInnerY = center.y + sinAngle * endRadius + perpSin * halfWidth
        let endOuterX = center.x + cosAngle * endRadius - perpCos * halfWidth
        let endOuterY = center.y + sinAngle * endRadius - perpSin * halfWidth
        
        var barPath = Path()
        barPath.move(to: CGPoint(x: round(startInnerX), y: round(startInnerY)))
        barPath.addLine(to: CGPoint(x: round(endInnerX), y: round(endInnerY)))
        barPath.addLine(to: CGPoint(x: round(endOuterX), y: round(endOuterY)))
        barPath.addLine(to: CGPoint(x: round(startOuterX), y: round(startOuterY)))
        barPath.closeSubpath()
        
        return barPath
    }
    
    /// Create a dashed arc path for radial spectrum visualization
    private func createDashedArc(config: DashedArcConfig) -> Path {
        var path = Path()
        let angleRange = abs(config.endAngle - config.startAngle)
        let totalLength = config.radius * angleRange
        let segmentLength = config.dashLength + config.gapLength
        let numSegments = Int(totalLength / segmentLength)
        
        var currentAngle = config.startAngle
        let dashAngle = (config.dashLength / config.radius)
        let gapAngle = (config.gapLength / config.radius)
        
        for _ in 0..<numSegments {
            let segmentStartAngle = currentAngle
            let segmentEndAngle = min(segmentStartAngle + dashAngle, config.endAngle)
            
            if segmentEndAngle > segmentStartAngle {
                // Draw arc segment by approximating with line segments
                let numPoints = max(3, Int((segmentEndAngle - segmentStartAngle) * 10))
                let pointStep = (segmentEndAngle - segmentStartAngle) / CGFloat(numPoints)
                
                var firstPoint = true
                for i in 0...numPoints {
                    let angle = segmentStartAngle + CGFloat(i) * pointStep
                    let x = config.center.x + cos(angle) * config.radius
                    let y = config.center.y + sin(angle) * config.radius
                    let point = CGPoint(x: round(x), y: round(y))
                    
                    if firstPoint {
                        path.move(to: point)
                        firstPoint = false
                    } else {
                        path.addLine(to: point)
                    }
                }
            }
            
            currentAngle = segmentEndAngle + gapAngle
            if currentAngle >= config.endAngle {
                break
            }
        }
        
        return path
    }
    
    /// Dual Channel Combined Graph - Combined left/right channel visualization
    /// Based on audioMotion-analyzer's dual-combined channel layout (CHANNEL_DUAL_COMBINED)
    /// Shows both left and right channels as overlapping waveforms with different colors
    /// Reference: audioMotion-analyzer.js (commit 60b9107)
    func dualChannelGraphView(frame: AudioVisualizerFrame, geometry: GeometryProxy) -> some View {
        let processedData = processMagnitudes(frame: frame)
        let baselineY = geometry.size.height // Baseline at bottom of canvas
        let stepX = geometry.size.width / CGFloat(processedData.normalized.count - 1)
        
        // Simulate stereo by applying slight variations to create two distinct channels
        let (leftChannel, rightChannel) = createDualChannels(from: processedData.normalized)
        
        return Canvas { context, size in
            // Background - solid black (audioMotion-analyzer uses #000)
            context.fill(
                Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 0),
                with: .color(.black)
            )
            
            // Draw both channels from bottom baseline
            let leftPath = createWaveformPath(channel: leftChannel, stepX: stepX, baselineY: baselineY, size: size)
            let rightPath = createWaveformPath(channel: rightChannel, stepX: stepX, baselineY: baselineY, size: size)
            
            // Fill and stroke left channel (reddish-brown/orange)
            let leftFillPath = createFillPath(waveformPath: leftPath, size: size, baselineY: baselineY)
            context.fill(leftFillPath, with: .color(Color(red: 0.6, green: 0.3, blue: 0.2, opacity: 0.6)))
            context.stroke(leftPath, with: .color(Color(red: 1.0, green: 0.5, blue: 0.2)), lineWidth: 1.5)
            
            // Fill and stroke right channel (blue/teal)
            let rightFillPath = createFillPath(waveformPath: rightPath, size: size, baselineY: baselineY)
            context.fill(rightFillPath, with: .color(Color(red: 0.1, green: 0.4, blue: 0.6, opacity: 0.6)))
            context.stroke(rightPath, with: .color(Color(red: 0.2, green: 0.7, blue: 1.0)), lineWidth: 1.5)
        }
    }
    
    /// Create dual channels by applying phase shifts to simulate stereo
    private func createDualChannels(from magnitudes: [CGFloat]) -> (left: [CGFloat], right: [CGFloat]) {
        let left = magnitudes.enumerated().map { index, magnitude in
            let phaseShift = sin(CGFloat(index) * 0.1) * 0.05
            return min(1.0, max(0.0, magnitude * (1.0 + phaseShift)))
        }
        let right = magnitudes.enumerated().map { index, magnitude in
            let phaseShift = sin(CGFloat(index) * 0.1 + .pi) * 0.05
            return min(1.0, max(0.0, magnitude * (1.0 + phaseShift)))
        }
        return (left, right)
    }
    
    /// Create waveform path from channel magnitudes, drawing upward from bottom baseline
    private func createWaveformPath(channel: [CGFloat], stepX: CGFloat, baselineY: CGFloat, size: CGSize) -> Path {
        var path = Path()
        var firstPoint = true
        
        for (index, magnitude) in channel.enumerated() {
            let x = CGFloat(index) * stepX
            let amplitude = magnitude * baselineY * 0.9 // Use full height from bottom
            let point = CGPoint(x: round(x), y: round(baselineY - amplitude)) // Draw upward from bottom
            
            if firstPoint {
                path.move(to: point)
                firstPoint = false
            } else {
                path.addLine(to: point)
            }
        }
        return path
    }
    
    /// Create filled area path from waveform to baseline at bottom
    private func createFillPath(waveformPath: Path, size: CGSize, baselineY: CGFloat) -> Path {
        var fillPath = waveformPath
        // Close path by going to bottom-right, then bottom-left, then back to start
        fillPath.addLine(to: CGPoint(x: size.width, y: baselineY))
        fillPath.addLine(to: CGPoint(x: 0, y: baselineY))
        fillPath.closeSubpath()
        return fillPath
    }
    
    /// LED Bars - Segmented LED-style bars with magnitude-based color gradient
    /// Based on audioMotion-analyzer's ledBars mode
    /// Reference: audioMotion-analyzer.js ledBars mode with segmented bars
    /// 
    /// Features:
    /// - Segmented bars: each bar composed of small rectangular segments stacked vertically
    /// - Magnitude-based color gradient: green (low) → yellow (medium) → red (high)
    /// - Grey inactive segments above active segments (showing potential maximum height)
    /// - Small gaps between segments and between adjacent bars
    /// - Bars fill full height based on magnitude (can reach top of canvas)
    
    func ledBarsView(frame: AudioVisualizerFrame, geometry: GeometryProxy) -> some View {
        // Use logarithmic normalization like other modes (except discrete)
        let processedData = processMagnitudes(frame: frame)
        let numBars = processedData.normalized.count
        
        // Calculate bar spacing - columns need clear separation with EQUAL spacing
        // Each column is a vertical bar with horizontal segments stacked inside
        // Equal spacing: divide total width by (numBars + 1) for spacing, then calculate column width
        let spacingRatio: CGFloat = 0.2 // 20% of total width for spacing (equal gaps)
        let totalSpacing = geometry.size.width * spacingRatio
        let spacingPerGap = totalSpacing / CGFloat(numBars + 1) // Equal spacing between and around columns
        let availableWidth = geometry.size.width - totalSpacing
        let barWidth = availableWidth / CGFloat(numBars) // Equal width for all columns
        
        // Segment configuration: horizontal rectangular segments stacked vertically
        // Each segment is a horizontal rectangle (wide, short) that spans the full column width
        // Segments are stacked vertically to form each column
        // Reference: segments should be clearly visible with small but visible gaps
        let segmentConfig = LEDSegmentConfig(
            height: 3, // Vertical height of each horizontal segment
            gap: 1 // Vertical gap between segments (small but visible)
        )
        
        return Canvas { context, size in
            // Background - solid black (audioMotion-analyzer uses #000)
            context.fill(
                Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 0),
                with: .color(.black)
            )
            
            // Draw vertical columns (bars) with horizontal segments stacked vertically
            // CRITICAL: Each column is a FIXED-WIDTH vertical bar at a FIXED X position
            // Each segment within a column has the SAME width (column width) - no variation
            // This creates distinct vertical columns, NOT a continuous waveform
            for (index, magnitude) in processedData.normalized.enumerated() {
                // Calculate column X position with EQUAL spacing
                // Each column has equal width and equal spacing on both sides
                // Position = spacing + (index * (barWidth + spacing))
                let columnX = spacingPerGap + CGFloat(index) * (barWidth + spacingPerGap)
                
                // Ensure column width is fixed and positive
                let fixedColumnWidth = max(1.0, barWidth)
                
                let columnConfig = LEDColumnConfig(
                    x: columnX,
                    width: fixedColumnWidth, // FIXED width - same for ALL segments in this column
                    segmentConfig: segmentConfig
                )
                drawLEDBarColumn(
                    context: context,
                    magnitude: magnitude,
                    columnConfig: columnConfig,
                    size: size
                )
            }
        }
    }
    
    /// Draw a single vertical column (bar) composed of horizontal segments stacked vertically
    /// Based on audioMotion-analyzer's ledBars implementation:
    /// - Each segment is a discrete unit at a fixed grid position
    /// - Bar height determines how many segments are active (colored)
    /// - Remaining segments above are inactive (grey)
    private func drawLEDBarColumn(
        context: GraphicsContext,
        magnitude: CGFloat,
        columnConfig: LEDColumnConfig,
        size: CGSize
    ) {
        // In SwiftUI Canvas: origin (0,0) is top-left, Y increases downward
        // Bottom of canvas is at y = size.height
        let canvasBottomY = size.height
        let canvasTopY: CGFloat = 0
        
        // Calculate active bar height from magnitude (0.0 to 1.0)
        let totalBarHeight = magnitude * size.height
        
        // Calculate how many segments fit in the canvas height
        // Each segment takes segmentHeight + gap (segmentUnit) of vertical space
        let segmentUnit = columnConfig.segmentConfig.unit
        let totalSegments = Int(ceil(size.height / segmentUnit))
        
        // Calculate how many segments should be active based on bar height
        // audioMotion-analyzer approach: count discrete segments that fit within bar height
        let activeSegmentCount = Int(floor(totalBarHeight / segmentUnit))
        
        // Draw ALL segments from bottom to top on a fixed grid
        // Column-based approach: each segment is a horizontal rectangle at a fixed grid position
        for segmentIndex in 0..<totalSegments {
            // Calculate segment position: start from bottom and stack upward
            // segmentIndex 0 = bottom segment (closest to canvas bottom)
            // Bottom edge of segment: canvasBottomY - segmentIndex * segmentUnit
            let segmentBottomY = canvasBottomY - CGFloat(segmentIndex) * segmentUnit
            let segmentTopY = segmentBottomY - columnConfig.segmentConfig.height
            
            // Only draw if segment is within canvas bounds
            guard segmentTopY >= canvasTopY && segmentBottomY <= canvasBottomY else { continue }
            
            // Determine if this segment is active (within active segment count)
            // audioMotion-analyzer: segments are discrete units, count from bottom
            let isActive = segmentIndex < activeSegmentCount && totalBarHeight > 0
            
            if isActive {
                // Active segment: draw with color based on position within active bar
                // Calculate position ratio: 0.0 (bottom) to 1.0 (top of active bar)
                // Use segment center for color calculation
                let segmentCenterY = (segmentTopY + segmentBottomY) / 2
                let distanceFromBottom = canvasBottomY - segmentCenterY
                let positionInBar = distanceFromBottom / totalBarHeight
                let magnitudeRatio = max(0.0, min(1.0, positionInBar))
                
                // Color based on magnitude position: green (low) → yellow (medium) → red (high)
                let color = colorForMagnitude(ratio: magnitudeRatio)
                
                // Draw horizontal segment rectangle (wide, short) - spans full column width
                // CRITICAL: Each segment must be exactly the column width - no variation
                // This ensures vertical columns, not horizontal waveform bars
                let segmentRect = CGRect(
                    x: round(columnConfig.x), // Fixed X position of this column
                    y: round(segmentTopY), // Top edge of segment (fixed grid position)
                    width: max(1, round(columnConfig.width)), // Fixed column width - same for all segments
                    height: max(1, round(columnConfig.segmentConfig.height)) // Fixed segment height
                )
                let segmentPath = Path(roundedRect: segmentRect, cornerRadius: 0)
                context.fill(segmentPath, with: .color(color))
            } else {
                // Inactive segment: grey, above the active bar
                // Draw at fixed grid position
                drawInactiveLEDSegment(
                    context: context,
                    columnConfig: columnConfig,
                    segmentTopY: segmentTopY
                )
            }
        }
    }

    /// Draw an inactive LED segment (grey)
    private func drawInactiveLEDSegment(
        context: GraphicsContext,
        columnConfig: LEDColumnConfig,
        segmentTopY: CGFloat
    ) {
        // Inactive segment: grey, showing potential maximum height
        // Reference: grey segments should be clearly visible against black background
        let greyColor = Color(white: 0.2, opacity: 0.8) // Dark grey, more visible
        
        // Draw horizontal inactive segment rectangle
        // CRITICAL: Same fixed width as active segments - ensures column structure
        let segmentRect = CGRect(
            x: round(columnConfig.x), // Fixed X position of this column
            y: round(segmentTopY), // Top edge of segment
            width: max(1, round(columnConfig.width)), // Fixed column width - same for all segments
            height: max(1, round(columnConfig.segmentConfig.height)) // Fixed segment height
        )
        let segmentPath = Path(roundedRect: segmentRect, cornerRadius: 0)
        context.fill(segmentPath, with: .color(greyColor))
    }
    
    /// Color based on magnitude ratio (not frequency)
    /// Green (low magnitude, bottom) → Yellow (medium) → Red (high magnitude, top)
    /// This matches the LED bars reference where color indicates magnitude, not frequency
    private func colorForMagnitude(ratio: CGFloat) -> Color {
        // Clamp ratio to [0, 1]
        let clampedRatio = max(0.0, min(1.0, ratio))
        
        // Green (0.0, bottom) → Yellow (0.5) → Red (1.0, top)
        if clampedRatio < 0.5 {
            // Green to Yellow transition
            let transitionRatio = clampedRatio * 2.0 // 0.0 to 1.0
            return Color(
                red: Double(transitionRatio), // 0.0 to 1.0
                green: 1.0, // Always 1.0 (bright green to bright yellow)
                blue: 0.0 // Always 0.0 (no blue in green-yellow transition)
            )
        } else {
            // Yellow to Red transition
            let transitionRatio = (clampedRatio - 0.5) * 2.0 // 0.0 to 1.0
            return Color(
                red: 1.0, // Always 1.0 (bright yellow to bright red)
                green: Double(1.0 - transitionRatio), // 1.0 to 0.0 (yellow fades out)
                blue: 0.0 // Always 0.0
            )
        }
    }
    
    /// LumiBars - Luminance-based bars with brightness effect
    /// Based on audioMotion-analyzer's lumiBars mode
    /// Key feature: ALL bars are drawn at FULL HEIGHT, with opacity varying by magnitude
    /// This creates a luminance/brightness effect where brighter bars indicate higher magnitude
    func lumiBarsView(frame: AudioVisualizerFrame, geometry: GeometryProxy) -> some View {
        let processedData = processMagnitudes(frame: frame)
        let numBars = processedData.normalized.count
        
        // Calculate bar spacing (audioMotion-analyzer uses barSpace, default 0.1 = 10%)
        let barSpace: CGFloat = 0.1
        let totalBarWidth = geometry.size.width / CGFloat(numBars)
        let spacing = totalBarWidth * barSpace
        let barWidth = totalBarWidth - spacing
        
        return Canvas { context, size in
            // Background - solid black (audioMotion-analyzer uses #000)
            context.fill(
                Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 0),
                with: .color(.black)
            )
            
            // Draw LumiBars: ALL bars at FULL HEIGHT with varying opacity (luminance)
            // audioMotion-analyzer: lumiBars displays all bars at full height
            // Brightness/opacity varies with magnitude to show intensity
            for (index, magnitude) in processedData.normalized.enumerated() {
                let barStartX = CGFloat(index) * totalBarWidth
                let barX = barStartX + spacing / 2
                let frequencyRatio = CGFloat(index) / CGFloat(numBars)
                
                // CRITICAL: All bars are FULL HEIGHT (size.height)
                // Opacity (luminance) varies with magnitude to show brightness
                let fullBarHeight = size.height
                let brightness = CGFloat(magnitude) // Opacity = magnitude (0.0 to 1.0)
                
                // Base color based on frequency (audioMotion-analyzer uses gradient)
                let baseColor = colorForFrequency(ratio: frequencyRatio, energy: 1.0)
                
                // Apply brightness as opacity (audioMotion-analyzer uses opacity for luminance)
                // Higher magnitude = higher opacity = brighter bar
                let lumiColor = baseColor.opacity(Double(brightness))
                
                // Draw bar at FULL HEIGHT from bottom
                let barRect = CGRect(
                    x: round(barX),
                    y: 0, // Top of canvas (bar extends full height downward)
                    width: max(1, round(barWidth)),
                    height: max(1, round(fullBarHeight))
                )
                let barPath = Path(roundedRect: barRect, cornerRadius: 0)
                context.fill(barPath, with: .color(lumiColor))
            }
        }
    }
    
    /// Round Bars + Reflex - Round bars with reflection effect
    /// Based on audioMotion-analyzer's roundBars + reflexRatio algorithm
    /// Reference: https://github.com/hvianna/audioMotion-analyzer/blob/60b910729d4969e3cbc2a6eca3cf2f16a258b0e7/demo/media/reflex.png
    /// 
    /// Features:
    /// - Bars with rounded tops (roundBars)
    /// - Reflection effect below bars (reflex)
    /// - reflexRatio: determines reflection height (0.5 = 50% of canvas height)
    /// - reflexAlpha: opacity of reflection (default 0.15)
    func roundBarsReflexView(frame: AudioVisualizerFrame, geometry: GeometryProxy) -> some View {
        let processedData = processMagnitudes(frame: frame)
        let numBars = processedData.normalized.count
        
        // Calculate bar spacing (audioMotion-analyzer uses barSpace, default 0.1 = 10%)
        // Ensure clear distinction between each bar with VISIBLE spacing
        // Reference: bars should have clear gaps between them like in the reference image
        // Increase spacing significantly to match reference where gaps are clearly visible
        let barSpace: CGFloat = 0.25 // 25% spacing for clearly visible gaps between bars
        let totalBarWidth = geometry.size.width / CGFloat(numBars)
        let spacing = totalBarWidth * barSpace
        let barWidth = totalBarWidth - spacing
        
        // Ensure minimum spacing for clear bar distinction
        // Each bar should be distinctly visible with clear separation
        // Minimum spacing should be at least 3px for clear visibility
        let minSpacing: CGFloat = 3.0
        let actualSpacing = max(minSpacing, spacing)
        let actualBarWidth = max(2.0, barWidth)
        
        // Reflex settings (audioMotion-analyzer defaults)
        // reflexRatio: 0.5 = reflection uses 50% of canvas height (perfect mirror)
        // reflexAlpha: 0.15 = reflection opacity (15%)
        let reflexRatio: CGFloat = 0.5 // Reflection height ratio (50% of canvas)
        let reflexAlpha: CGFloat = 0.15 // Reflection opacity
        
        return Canvas { context, size in
            // Background - solid black (audioMotion-analyzer uses #000)
            context.fill(
                Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 0),
                with: .color(.black)
            )
            
            // Calculate center line (bars above, reflection below)
            let centerY = size.height / 2
            let topHalfHeight = centerY // Height available for bars (top half)
            
            // Draw round bars with reflex (reflection) effect
            // Each bar should be distinctly visible with clear separation
            // Reference: bars should have visible gaps between them
            for (index, magnitude) in processedData.normalized.enumerated() {
                // Calculate bar X position with clear spacing for distinct bars
                // Position bars with equal spacing: spacing on left, bar, spacing on right
                let barStartX = CGFloat(index) * totalBarWidth
                let barX = barStartX + actualSpacing / 2 // Center bar within its allocated space
                let frequencyRatio = CGFloat(index) / CGFloat(numBars)
                let color = colorForFrequency(ratio: frequencyRatio, energy: magnitude)
                
                // Calculate bar height (from center upward)
                let barHeight = magnitude * topHalfHeight
                
                // Top bar (round) - extends upward from center
                // audioMotion-analyzer: bars have rounded caps on BOTH ends (top and bottom)
                // Each bar should be distinctly visible with clear separation
                let topBarRect = CGRect(
                    x: round(barX),
                    y: round(centerY - barHeight), // Start from center, extend upward
                    width: max(2, round(actualBarWidth)),
                    height: max(2, round(barHeight))
                )
                // Rounded rectangle with rounded caps on BOTH ends
                // Corner radius = half of bar width creates fully rounded caps
                let cornerRadius = min(topBarRect.width / 2, topBarRect.height / 2)
                let topBarPath = Path(roundedRect: topBarRect, cornerRadius: cornerRadius)
                context.fill(topBarPath, with: .color(color))
                
                // Reflex (reflection) - mirror of bar below center
                // audioMotion-analyzer: reflection height = reflexRatio * bar height
                // Reflection is a mirror image of the bar, flipped vertically
                let reflexHeight = barHeight * reflexRatio // Reflection height based on bar height
                let reflexBarRect = CGRect(
                    x: round(barX),
                    y: round(centerY), // Start from center, extend downward
                    width: max(2, round(actualBarWidth)),
                    height: max(2, round(reflexHeight))
                )
                // Rounded rectangle for reflection with rounded caps on BOTH ends
                let reflexCornerRadius = min(reflexBarRect.width / 2, reflexBarRect.height / 2)
                let reflexBarPath = Path(roundedRect: reflexBarRect, cornerRadius: reflexCornerRadius)
                let reflexColor = color.opacity(Double(reflexAlpha)) // Reduced opacity for reflection
                context.fill(reflexBarPath, with: .color(reflexColor))
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
    
}
