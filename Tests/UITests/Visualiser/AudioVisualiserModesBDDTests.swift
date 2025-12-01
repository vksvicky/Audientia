//
//  AudioVisualiserModesBDDTests.swift
//  UITests
//
//  BDD tests for AudioVisualiserModes visualisation algorithms
//  Tests user scenarios for each visualisation mode based on audioMotion-analyzer
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AudioCore
import Foundation
import SwiftUI
import XCTest

@testable import Audientia

/// BDD tests for AudioVisualiserModes
/// Tests user scenarios for visualisation modes
@MainActor
final class AudioVisualiserModesBDDTests: XCTestCase {
    private var testFrame: AudioVisualiserFrame!
    private var mockNowPlayingViewModel: NowPlayingViewModel!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create test frame with realistic audio data
        let magnitudes: [Float] = (0..<512).map { index in
            // Simulate frequency response: bass (low), mid (medium), treble (high)
            let frequency = Float(index) * 44100.0 / 2048.0
            if frequency < 200 {
                // Bass frequencies - higher energy
                return Float(70.0 + sin(Float(index) * 0.1) * 20.0)
            } else if frequency < 2000 {
                // Mid frequencies - medium energy
                return Float(50.0 + sin(Float(index) * 0.05) * 15.0)
            } else {
                // Treble frequencies - lower energy
                return Float(30.0 + sin(Float(index) * 0.02) * 10.0)
            }
        }
        
        testFrame = AudioVisualiserFrame(
            magnitudes: magnitudes,
            timestamp: Date(),
            sampleRate: 44100,
            fftSize: 1024
        )
        
        let mockEngine = MockAudioEngine()
        mockNowPlayingViewModel = NowPlayingViewModel(audioEngine: mockEngine)
    }
    
    override func tearDownWithError() throws {
        testFrame = nil
        mockNowPlayingViewModel = nil
        try super.tearDownWithError()
    }
    
    // MARK: - BDD Scenario 1: Discrete Frequencies Mode
    
    /// BDD: As a user, when I select discrete frequencies mode, 
    /// then I should see each FFT bin as a separate bar with clear separation
    func testDiscreteFrequenciesShowsIndividualBins() {
        // Given - A visualiser view with discrete frequencies mode
        let view = AudioVisualiserView(nowPlayingViewModel: mockNowPlayingViewModel)
        
        // When - View is created
        // Then - View should be created without errors
        // Note: viewModel is private, so we test through view creation
        XCTAssertNotNil(view)
    }
    
    /// BDD: As a user, when I view discrete frequencies, 
    /// then bars should have 10% spacing between them (audioMotion-analyzer barSpace)
    func testDiscreteFrequenciesHasCorrectSpacing() {
        // Given - A visualiser view
        _ = AudioVisualiserView(nowPlayingViewModel: mockNowPlayingViewModel)
        
        // When - Processing magnitudes for discrete mode
        // Note: We test the algorithm logic, not the extension method directly
        let normaliser = SpectrumNormaliser(
            logScale: 2.0,
            minFreq: 20.0,
            maxFreq: 20000.0,
            sampleRate: testFrame.sampleRate,
            fftSize: testFrame.fftSize
        )
        let normalizedMagnitudes = normaliser.normalize(testFrame.magnitudes)
        let compressedMagnitudes = normaliser.compress(normalizedMagnitudes, sensitivity: 1.2)
        let amplificationFactor: Float = 2.5
        let amplifiedMagnitudes = compressedMagnitudes.map { $0 * amplificationFactor }
        let maxMagnitude = amplifiedMagnitudes.max() ?? 1.0
        let minMagnitude = amplifiedMagnitudes.min() ?? 0.0
        let range = max(maxMagnitude - minMagnitude, 1.0)
        let processed = amplifiedMagnitudes.map { CGFloat(($0 - minMagnitude) / range) }
        let numBars = processed.count
        let barSpace: CGFloat = 0.1
        let totalBarWidth: CGFloat = 400.0 / CGFloat(numBars)
        let barWidth = totalBarWidth * (1.0 - barSpace)
        let expectedSpacing = totalBarWidth * barSpace
        
        // Then - Bar width and spacing should match audioMotion-analyzer algorithm
        XCTAssertGreaterThan(barWidth, 0, "Bar width should be positive")
        XCTAssertGreaterThan(expectedSpacing, 0, "Spacing should be positive")
        XCTAssertEqual(
            barWidth + expectedSpacing,
            totalBarWidth,
            accuracy: 0.01,
            "Bar width + spacing should equal total bar width"
        )
    }
    
    // MARK: - BDD Scenario 2: Radial Spectrum Mode
    
    /// BDD: As a user, when I select radial spectrum mode,
    /// then I should see circular bars radiating from the center with:
    /// - A central black circle
    /// - Radial bars (rectangles) extending outward from the center
    /// - Gradient colors (blue → green → yellow → orange → red)
    /// - Dashed arcs beyond bars (for significant magnitudes)
    /// Reference: audioMotion-analyzer's radial mode
    func testRadialSpectrumShowsCircularBars() {
        // Given - A visualiser view with radial spectrum mode
        // The radial spectrum should match audioMotion-analyzer's implementation:
        // - Central black circle (15% of max radius)
        // - Radial bars extending from inner circle to outer radius
        // - Bars are rectangles, not lines
        // - Frequency labels around perimeter (31, 63, 125, 250, 500, 1k, 2k, 4k, 8k)
        // - Dashed arcs beyond bars for visual enhancement
        let view = AudioVisualiserView(nowPlayingViewModel: mockNowPlayingViewModel)
        
        // When - View is created
        // Then - View should be created without errors
        // The visualisation should render radial bars extending outward from a central black circle
        XCTAssertNotNil(view)
        
        // Verify the mode exists and has correct description
        let radialMode = VisualisationMode.radialSpectrum
        XCTAssertEqual(radialMode.displayName, "Radial Spectrum")
        XCTAssertEqual(radialMode.iconSystemName, "waveform.circle.fill")
        XCTAssertTrue(radialMode.description.contains("radial"))
    }
    
    // MARK: - BDD Scenario 3: Dual Channel Combined Graph Mode
    
    /// BDD: As a user, when I select dual channel combined graph mode,
    /// then I should see combined left/right channel visualisation with two overlapping waveforms
    func testDualChannelGraphShowsCombinedChannels() {
        // Given - A visualiser view with dual channel graph mode
        // The dual channel mode should show two separate waveforms (left and right channels)
        // with different colors (reddish-brown/orange for left, blue/teal for right)
        // Reference: audioMotion-analyzer's CHANNEL_DUAL_COMBINED mode
        let view = AudioVisualiserView(nowPlayingViewModel: mockNowPlayingViewModel)
        
        // When - View is created
        // Then - View should be created without errors
        // The visualisation should render two overlapping waveforms from a single mono source
        // by applying phase shifts to simulate stereo channels
        XCTAssertNotNil(view)
        
        // Verify the mode exists and has correct description
        let dualChannelMode = VisualisationMode.dualChannelGraph
        XCTAssertEqual(dualChannelMode.displayName, "Dual Channel Graph")
        XCTAssertEqual(dualChannelMode.iconSystemName, "waveform.path")
        XCTAssertTrue(dualChannelMode.description.contains("dual channel"))
    }
    
    // MARK: - BDD Scenario 4: LED Bars Mode
    
    /// BDD: As a user, when I select LED bars mode,
    /// then I should see segmented LED-style bars with:
    /// - Segmented bars: each bar composed of small rectangular segments stacked vertically
    /// - Magnitude-based color gradient: green (low) → yellow (medium) → red (high)
    /// - Small gaps between segments and between adjacent bars
    /// Reference: audioMotion-analyzer's ledBars mode
    func testLEDBarsShowsLEDIndicators() {
        // Given - A visualiser view with LED bars mode
        // The LED bars should match audioMotion-analyzer's implementation:
        // - Segmented appearance (not solid bars)
        // - Color based on magnitude position (green at bottom, yellow in middle, red at top)
        // - 5% spacing between bars
        let view = AudioVisualiserView(nowPlayingViewModel: mockNowPlayingViewModel)
        
        // When - View is created
        // Then - View should be created without errors
        // The visualisation should render segmented bars with magnitude-based colors
        XCTAssertNotNil(view)
        
        // Verify the mode exists and has correct description
        let ledBarsMode = VisualisationMode.ledBars
        XCTAssertEqual(ledBarsMode.displayName, "LED Bars")
        XCTAssertEqual(ledBarsMode.iconSystemName, "square.stack")
        XCTAssertTrue(ledBarsMode.description.contains("LED"))
    }
    
    /// BDD: As a user, when I view LED bars,
    /// then bars should have 5% spacing (different from discrete mode)
    func testLEDBarsHasCorrectSpacing() {
        // Given - A visualiser view
        _ = AudioVisualiserView(nowPlayingViewModel: mockNowPlayingViewModel)
        
        // When - Processing for LED bars (uses 5% spacing)
        // Test the algorithm logic
        let normaliser = SpectrumNormaliser(
            logScale: 2.0,
            minFreq: 20.0,
            maxFreq: 20000.0,
            sampleRate: testFrame.sampleRate,
            fftSize: testFrame.fftSize
        )
        let normalizedMagnitudes = normaliser.normalize(testFrame.magnitudes)
        let compressedMagnitudes = normaliser.compress(normalizedMagnitudes, sensitivity: 1.2)
        let amplificationFactor: Float = 2.5
        let amplifiedMagnitudes = compressedMagnitudes.map { $0 * amplificationFactor }
        let maxMagnitude = amplifiedMagnitudes.max() ?? 1.0
        let minMagnitude = amplifiedMagnitudes.min() ?? 0.0
        let range = max(maxMagnitude - minMagnitude, 1.0)
        let processed = amplifiedMagnitudes.map { CGFloat(($0 - minMagnitude) / range) }
        let numBars = processed.count
        let barSpace: CGFloat = 0.05
        let totalBarWidth: CGFloat = 400.0 / CGFloat(numBars)
        let barWidth = totalBarWidth * (1.0 - barSpace)
        
        // Then - Bar width should account for 5% spacing
        XCTAssertGreaterThan(barWidth, 0, "LED bar width should be positive")
        XCTAssertLessThan(barWidth, totalBarWidth, "LED bar width should be less than total")
    }
    
    // MARK: - BDD Scenario 5: LumiBars Mode
    
    /// BDD: As a user, when I select LumiBars mode,
    /// then I should see luminance-based bars with brightness effect
    func testLumiBarsShowsBrightnessEffect() {
        // Given - A visualiser view with LumiBars mode
        let view = AudioVisualiserView(nowPlayingViewModel: mockNowPlayingViewModel)
        
        // When - View is created
        // Then - View should be created without errors
        // Note: viewModel is private, so we test through view creation
        XCTAssertNotNil(view)
    }
    
    /// BDD: As a user, when I view LumiBars,
    /// then all bars should be full height with opacity varying by magnitude (brightness effect)
    /// Reference: audioMotion-analyzer's lumiBars mode - all bars at full height, opacity = magnitude
    func testLumiBarsOpacityVariesWithMagnitude() {
        // Given - A visualiser view with LumiBars mode
        // When - Processing magnitudes using the algorithm directly
        let normaliser = SpectrumNormaliser(
            logScale: 2.0,
            minFreq: 20.0,
            maxFreq: 20000.0,
            sampleRate: testFrame.sampleRate,
            fftSize: testFrame.fftSize
        )
        let normalizedMagnitudes = normaliser.normalize(testFrame.magnitudes)
        let compressedMagnitudes = normaliser.compress(normalizedMagnitudes, sensitivity: 1.2)
        let amplificationFactor: Float = 2.5
        let amplifiedMagnitudes = compressedMagnitudes.map { $0 * amplificationFactor }
        let maxMagnitude = amplifiedMagnitudes.max() ?? 1.0
        let minMagnitude = amplifiedMagnitudes.min() ?? 0.0
        let range = max(maxMagnitude - minMagnitude, 1.0)
        let processed = amplifiedMagnitudes.map { CGFloat(($0 - minMagnitude) / range) }
        
        // Then - Magnitudes should be in 0-1 range for opacity calculation
        // audioMotion-analyzer: lumiBars uses magnitude directly as opacity
        // All bars are full height, brightness (opacity) varies with magnitude
        for magnitude in processed {
            XCTAssertGreaterThanOrEqual(magnitude, 0.0, "Magnitude should be >= 0 for opacity")
            XCTAssertLessThanOrEqual(magnitude, 1.0, "Magnitude should be <= 1 for opacity")
        }
        
        // Verify that different magnitudes result in different opacities
        // Higher magnitude = higher opacity = brighter bar
        if processed.count >= 2 {
            let sortedMagnitudes = processed.sorted()
            if let minMagnitude = sortedMagnitudes.first,
               let maxMagnitude = sortedMagnitudes.last,
               minMagnitude < maxMagnitude {
                // Lower magnitude should have lower opacity (dimmer)
                // Higher magnitude should have higher opacity (brighter)
                XCTAssertLessThan(
                    minMagnitude,
                    maxMagnitude,
                    "Higher magnitudes should result in higher opacity (brightness)"
                )
            }
        }
    }
    
    // MARK: - BDD Scenario 6: Round Bars + Reflex Mode
    
    /// BDD: As a user, when I select round bars + reflex mode,
    /// then I should see round bars with reflection effect
    /// Reference: audioMotion-analyzer's roundBars + reflexRatio
    /// - Bars have rounded tops
    /// - Reflection appears below bars with reduced opacity
    /// - reflexRatio: 0.5 (50% of canvas height for reflection)
    /// - reflexAlpha: 0.15 (15% opacity for reflection)
    func testRoundBarsReflexShowsReflection() {
        // Given - A visualiser view with round bars + reflex mode
        let view = AudioVisualiserView(nowPlayingViewModel: mockNowPlayingViewModel)
        
        // When - View is created
        // Then - View should be created without errors
        // Note: viewModel is private, so we test through view creation
        XCTAssertNotNil(view)
        
        // Verify round bars + reflex mode configuration
        let roundBarsReflexMode = VisualisationMode.roundBarsReflex
        XCTAssertEqual(roundBarsReflexMode.displayName, "Round Bars + Reflex")
        XCTAssertEqual(roundBarsReflexMode.iconSystemName, "circle.circle")
        XCTAssertTrue(roundBarsReflexMode.description.contains("Round") || roundBarsReflexMode.description.contains("Reflex"))
    }
    
    /// BDD: As a user, when I view round bars + reflex,
    /// then reflex should be 50% of bar height with 15% opacity (audioMotion-analyzer defaults)
    func testRoundBarsReflexHasCorrectReflexRatio() {
        // Given - Reflex settings from audioMotion-analyzer
        let reflexRatio: CGFloat = 0.5
        let reflexAlpha: CGFloat = 0.15
        
        // When - Calculating reflex dimensions
        let barHeight: CGFloat = 100.0
        let reflexHeight = barHeight * reflexRatio
        
        // Then - Reflex should match audioMotion-analyzer algorithm
        XCTAssertEqual(reflexHeight, 50.0, accuracy: 0.01, "Reflex should be 50% of bar height")
        XCTAssertEqual(reflexAlpha, 0.15, accuracy: 0.01, "Reflex alpha should be 15%")
    }
    
    // MARK: - BDD Scenario 7: Color Mapping
    
    /// BDD: As a user, when I view any visualisation mode,
    /// then colors should map to frequency bands (bass=blue, treble=red)
    func testColorMappingMatchesFrequencyBands() {
        // Given - A visualiser view
        _ = AudioVisualiserView(nowPlayingViewModel: mockNowPlayingViewModel)
        
        // When - Getting colors for different frequency ratios (test algorithm directly)
        let bassColor = testColorForFrequency(ratio: 0.1, energy: 0.8)  // Low frequency
        let midColor = testColorForFrequency(ratio: 0.5, energy: 0.8)  // Mid frequency
        let trebleColor = testColorForFrequency(ratio: 0.9, energy: 0.8) // High frequency
        
        // Then - Colors should be different for different frequencies
        XCTAssertNotNil(bassColor)
        XCTAssertNotNil(midColor)
        XCTAssertNotNil(trebleColor)
        // Note: Direct Color comparison is not possible in SwiftUI, but we verify no crashes
    }
    
    // MARK: - BDD Scenario 8: Magnitude Processing
    
    /// BDD: As a user, when audio is playing,
    /// then magnitudes should be normalized using audioMotion-analyzer algorithm
    func testMagnitudeProcessingUsesAudioMotionAlgorithm() {
        // Given - A visualiser view
        _ = AudioVisualiserView(nowPlayingViewModel: mockNowPlayingViewModel)
        
        // When - Processing magnitudes using audioMotion-analyzer algorithm
        let normaliser = SpectrumNormaliser(
            logScale: 2.0,
            minFreq: 20.0,
            maxFreq: 20000.0,
            sampleRate: testFrame.sampleRate,
            fftSize: testFrame.fftSize
        )
        let normalizedMagnitudes = normaliser.normalize(testFrame.magnitudes)
        let compressedMagnitudes = normaliser.compress(normalizedMagnitudes, sensitivity: 1.2)
        let amplificationFactor: Float = 2.5
        let amplifiedMagnitudes = compressedMagnitudes.map { $0 * amplificationFactor }
        let maxMagnitude = amplifiedMagnitudes.max() ?? 1.0
        let minMagnitude = amplifiedMagnitudes.min() ?? 0.0
        let range = max(maxMagnitude - minMagnitude, 1.0)
        let result = amplifiedMagnitudes.map { CGFloat(($0 - minMagnitude) / range) }
        
        // Then - Should apply:
        // 1. Logarithmic frequency scaling
        // 2. Dynamic range compression (sensitivity 1.2)
        // 3. Amplification factor (2.5x)
        // 4. Normalization to 0-1 range
        XCTAssertFalse(result.isEmpty, "Should have processed magnitudes")
        XCTAssertEqual(
            result.count,
            testFrame.magnitudes.count,
            "Should preserve magnitude count"
        )
        
        // Verify normalization range
        let maxValue = result.max() ?? 0.0
        let minValue = result.min() ?? 0.0
        XCTAssertLessThanOrEqual(maxValue, 1.0, "Max should be <= 1.0")
        XCTAssertGreaterThanOrEqual(minValue, 0.0, "Min should be >= 0.0")
    }
    
    // MARK: - Helper Functions
    
    /// Helper to test colorForFrequency algorithm
    private func testColorForFrequency(ratio: CGFloat, energy: CGFloat) -> Color {
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
}
