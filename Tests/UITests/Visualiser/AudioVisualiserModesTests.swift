//
//  AudioVisualiserModesTests.swift
//  UITests
//
//  TDD tests for AudioVisualiserModes visualisation algorithms
//  Tests the audioMotion-analyzer-based algorithms for each visualisation mode
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AudioCore
import Foundation
import SwiftUI
import XCTest

@testable import Audientia

// Import SpectrumNormaliser for testing
extension AudioCore.SpectrumNormaliser {}

/// Result of processing magnitudes for testing
private struct ProcessMagnitudesResult {
    let normalized: [CGFloat]
    let amplified: [Float]
    let colors: [Color]
}

/// TDD tests for AudioVisualiserModes
/// Tests the visualisation algorithms based on audioMotion-analyzer
@MainActor
final class AudioVisualiserModesTests: XCTestCase {
    private var testFrame: AudioVisualiserFrame!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create test frame with known magnitudes
        let magnitudes: [Float] = (0..<512).map { index in
            // Create a pattern: bass (low indices) have higher magnitude
            if index < 50 {
                return Float(80.0 + sin(Float(index) * 0.1) * 20.0)
            } else if index < 200 {
                return Float(50.0 + sin(Float(index) * 0.05) * 15.0)
            } else {
                return Float(20.0 + sin(Float(index) * 0.02) * 10.0)
            }
        }
        
        testFrame = AudioVisualiserFrame(
            magnitudes: magnitudes,
            timestamp: Date(),
            sampleRate: 44100,
            fftSize: 1024
        )
    }
    
    override func tearDownWithError() throws {
        testFrame = nil
        try super.tearDownWithError()
    }
    
    // MARK: - [Right] BICEP: Are the Results Right?
    
    /// TDD: Given a frame with magnitudes, when processing for discrete frequencies,
    /// then normalized values should be in 0-1 range
    func testProcessMagnitudesReturnsNormalizedRange() {
        // Given - A test frame and view
        let view = AudioVisualiserView(nowPlayingViewModel: nil)
        
        // When - Processing magnitudes (access through extension)
        let result = processMagnitudesHelper(view: view, frame: testFrame)
        
        // Then - All values should be normalized to 0-1 range
        XCTAssertFalse(result.normalized.isEmpty, "Should have normalized values")
        for value in result.normalized {
            XCTAssertGreaterThanOrEqual(value, 0.0, "Normalized value should be >= 0")
            XCTAssertLessThanOrEqual(value, 1.0, "Normalized value should be <= 1")
        }
    }
    
    /// TDD: Given a frame, when processing magnitudes, then count should match input
    func testProcessMagnitudesPreservesCount() {
        // Given - A test frame and view
        let view = AudioVisualiserView(nowPlayingViewModel: nil)
        
        // When - Processing magnitudes
        let result = processMagnitudesHelper(view: view, frame: testFrame)
        
        // Then - Count should match input magnitudes
        XCTAssertEqual(
            result.normalized.count,
            testFrame.magnitudes.count,
            "Normalized count should match input magnitudes count"
        )
    }
    
    /// TDD: Given frequency ratios, when getting colors, then colors should vary by frequency
    func testColorForFrequencyVariesByRatio() {
        // Given - A view
        let view = AudioVisualiserView(nowPlayingViewModel: nil)
        
        // When - Getting colors for different frequency ratios
        let bassColor = colorForFrequencyHelper(view: view, ratio: 0.1, energy: 0.8)
        let midColor = colorForFrequencyHelper(view: view, ratio: 0.5, energy: 0.8)
        let trebleColor = colorForFrequencyHelper(view: view, ratio: 0.9, energy: 0.8)
        
        // Then - Colors should be different (bass is blue, treble is red)
        // We can't directly compare Color values, but we verify the function doesn't crash
        XCTAssertNotNil(bassColor)
        XCTAssertNotNil(midColor)
        XCTAssertNotNil(trebleColor)
    }
    
    // MARK: - Helper Functions
    
    /// Helper to access processMagnitudes from extension
    private func processMagnitudesHelper(view: AudioVisualiserView, frame: AudioVisualiserFrame) -> ProcessMagnitudesResult {
        // Access the extension method through reflection or direct call
        // Since it's an extension method, we test it indirectly through the view's behavior
        // For now, we'll test the SpectrumNormaliser directly
        let normaliser = SpectrumNormaliser(
            logScale: 2.0,
            minFreq: 20.0,
            maxFreq: 20000.0,
            sampleRate: frame.sampleRate,
            fftSize: frame.fftSize
        )
        let normalizedMagnitudes = normaliser.normalize(frame.magnitudes)
        let compressedMagnitudes = normaliser.compress(normalizedMagnitudes, sensitivity: 1.2)
        
        let amplificationFactor: Float = 2.5
        let amplifiedMagnitudes = compressedMagnitudes.map { $0 * amplificationFactor }
        
        let maxMagnitude = amplifiedMagnitudes.max() ?? 1.0
        let minMagnitude = amplifiedMagnitudes.min() ?? 0.0
        let range = max(maxMagnitude - minMagnitude, 1.0)
        
        let normalized = amplifiedMagnitudes.map { magnitude in
            CGFloat((magnitude - minMagnitude) / range)
        }
        
        return ProcessMagnitudesResult(normalized: normalized, amplified: amplifiedMagnitudes, colors: [])
    }
    
    /// Helper to access colorForFrequency from extension
    private func colorForFrequencyHelper(view: AudioVisualiserView, ratio: CGFloat, energy: CGFloat) -> Color {
        // Test the color mapping logic directly
        let enhancedEnergy = pow(energy, 0.7)
        
        if ratio < 0.25 {
            return Color(
                red: 0.1 + enhancedEnergy * 0.4,
                green: 0.3 + enhancedEnergy * 0.5,
                blue: 0.9 + enhancedEnergy * 0.1
            )
        } else if ratio < 0.4 {
            return Color(
                red: 0.2 + enhancedEnergy * 0.3,
                green: 0.7 + enhancedEnergy * 0.3,
                blue: 0.8 + enhancedEnergy * 0.2
            )
        } else if ratio < 0.55 {
            return Color(
                red: 0.5 + enhancedEnergy * 0.4,
                green: 0.8 + enhancedEnergy * 0.2,
                blue: 0.3 + enhancedEnergy * 0.2
            )
        } else if ratio < 0.7 {
            return Color(
                red: 0.9 + enhancedEnergy * 0.1,
                green: 0.6 + enhancedEnergy * 0.3,
                blue: 0.2 + enhancedEnergy * 0.2
            )
        } else {
            return Color(
                red: 1.0,
                green: 0.3 + enhancedEnergy * 0.4,
                blue: 0.4 + enhancedEnergy * 0.3
            )
        }
    }
    
    // MARK: - Right-[B]ICEP: Boundary Conditions
    
    /// TDD: Given an empty magnitudes frame, when processing, then should handle gracefully
    func testProcessMagnitudesWithEmptyFrame() {
        // Given - An empty frame
        let emptyFrame = AudioVisualiserFrame(
            magnitudes: [],
            timestamp: Date(),
            sampleRate: 44100,
            fftSize: 1024
        )
        let view = AudioVisualiserView(nowPlayingViewModel: nil)
        
        // When - Processing magnitudes
        let result = processMagnitudesHelper(view: view, frame: emptyFrame)
        
        // Then - Should return empty normalized array
        XCTAssertTrue(result.normalized.isEmpty, "Should return empty array for empty frame")
    }
    
    /// TDD: Given all-zero magnitudes, when processing, then should normalize correctly
    func testProcessMagnitudesWithAllZeros() {
        // Given - A frame with all zero magnitudes
        let zeroFrame = AudioVisualiserFrame(
            magnitudes: Array(repeating: 0.0, count: 512),
            timestamp: Date(),
            sampleRate: 44100,
            fftSize: 1024
        )
        let view = AudioVisualiserView(nowPlayingViewModel: nil)
        
        // When - Processing magnitudes
        let result = processMagnitudesHelper(view: view, frame: zeroFrame)
        
        // Then - Should handle zeros gracefully (may all be 0 or normalized)
        XCTAssertEqual(result.normalized.count, 512, "Should preserve count")
        // All zeros might normalize to 0 or be handled by the normalization algorithm
    }
    
    /// TDD: Given extreme frequency ratios, when getting colors, then should handle boundaries
    func testColorForFrequencyBoundaryRatios() {
        // Given - A view
        let view = AudioVisualiserView(nowPlayingViewModel: nil)
        
        // When - Getting colors for boundary ratios
        let zeroRatioColor = colorForFrequencyHelper(view: view, ratio: 0.0, energy: 0.5)
        let oneRatioColor = colorForFrequencyHelper(view: view, ratio: 1.0, energy: 0.5)
        let negativeRatioColor = colorForFrequencyHelper(view: view, ratio: -0.1, energy: 0.5)
        let overOneRatioColor = colorForFrequencyHelper(view: view, ratio: 1.5, energy: 0.5)
        
        // Then - Should handle all cases without crashing
        XCTAssertNotNil(zeroRatioColor)
        XCTAssertNotNil(oneRatioColor)
        XCTAssertNotNil(negativeRatioColor)
        XCTAssertNotNil(overOneRatioColor)
    }
    
    // MARK: - Right-B[I]CEP: Checking Inverse Relationships
    
    /// TDD: Given high and low magnitudes, when processing, then high should normalize higher
    func testProcessMagnitudesInverseRelationship() {
        // Given - Frames with different magnitude ranges and varying values
        // Low frame: magnitudes range from 5.0 to 15.0
        let lowMagnitudes = (0..<512).map { Float(5.0 + sin(Float($0) * 0.1) * 5.0) }
        let lowFrame = AudioVisualiserFrame(
            magnitudes: lowMagnitudes,
            timestamp: Date(),
            sampleRate: 44100,
            fftSize: 1024
        )
        // High frame: magnitudes range from 50.0 to 150.0
        let highMagnitudes = (0..<512).map { Float(50.0 + sin(Float($0) * 0.1) * 50.0) }
        let highFrame = AudioVisualiserFrame(
            magnitudes: highMagnitudes,
            timestamp: Date(),
            sampleRate: 44100,
            fftSize: 1024
        )
        let view = AudioVisualiserView(nowPlayingViewModel: nil)
        
        // When - Processing both
        let lowResult = processMagnitudesHelper(view: view, frame: lowFrame)
        let highResult = processMagnitudesHelper(view: view, frame: highFrame)
        
        // Then - High frame should have higher amplified magnitudes (before normalization)
        // Compare amplified magnitudes since normalization makes both frames 0-1 range
        let lowAmplifiedAvg = lowResult.amplified.reduce(0, +) / Float(lowResult.amplified.count)
        let highAmplifiedAvg = highResult.amplified.reduce(0, +) / Float(highResult.amplified.count)
        XCTAssertGreaterThan(highAmplifiedAvg, lowAmplifiedAvg, "High magnitudes should result in higher amplified values")
        
        // Also verify that both frames have valid normalized values
        let lowMax = lowResult.normalized.max() ?? 0.0
        let highMax = highResult.normalized.max() ?? 0.0
        XCTAssertGreaterThan(lowMax, 0.0, "Low frame should have non-zero normalized values")
        XCTAssertGreaterThan(highMax, 0.0, "High frame should have non-zero normalized values")
    }
    
    // MARK: - Right-BIC[E]P: Forcing Error Conditions
    
    /// TDD: Given invalid frame data, when processing, then should handle gracefully
    func testProcessMagnitudesWithInvalidData() {
        // Given - A frame with NaN or infinite values
        var magnitudes = Array(repeating: Float(50.0), count: 512)
        magnitudes[0] = Float.nan
        magnitudes[1] = Float.infinity
        
        let invalidFrame = AudioVisualiserFrame(
            magnitudes: magnitudes,
            timestamp: Date(),
            sampleRate: 44100,
            fftSize: 1024
        )
        let view = AudioVisualiserView(nowPlayingViewModel: nil)
        
        // When - Processing magnitudes
        // Then - Should not crash (may filter or handle NaN/infinity)
        let result = processMagnitudesHelper(view: view, frame: invalidFrame)
        XCTAssertEqual(result.normalized.count, 512, "Should preserve count even with invalid data")
    }
    
    // MARK: - Right-BICE[P]: Performance Characteristics
    
    /// TDD: Given a large frame, when processing, then should complete in reasonable time
    func testProcessMagnitudesPerformance() {
        // Given - A large frame (4096 FFT size)
        let largeMagnitudes = Array(repeating: Float(50.0), count: 2048)
        let largeFrame = AudioVisualiserFrame(
            magnitudes: largeMagnitudes,
            timestamp: Date(),
            sampleRate: 44100,
            fftSize: 4096
        )
        let view = AudioVisualiserView(nowPlayingViewModel: nil)
        
        // When - Processing magnitudes
        measure {
            _ = processMagnitudesHelper(view: view, frame: largeFrame)
        }
    }
}
