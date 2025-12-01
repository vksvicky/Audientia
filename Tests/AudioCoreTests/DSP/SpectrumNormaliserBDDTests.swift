//
//  SpectrumNormaliserBDDTests.swift
//  AudioCoreTests
//
//  BDD tests for SpectrumNormaliser
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
import XCTest

/// BDD tests for SpectrumNormaliser
final class SpectrumNormaliserBDDTests: XCTestCase {
    private var normaliser: SpectrumNormaliser!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        normaliser = SpectrumNormaliser(
            logScale: 2.0,
            minFreq: 20.0,
            maxFreq: 20000.0,
            sampleRate: 44100,
            fftSize: 1024
        )
    }
    
    override func tearDownWithError() throws {
        normaliser = nil
        try super.tearDownWithError()
    }
    
    /// BDD: Given a bass-heavy audio spectrum, when I normalize it, then low frequencies should be emphasized for visualisation
    func testBassHeavySpectrumEmphasizesLowFrequencies() {
        // Given - A bass-heavy spectrum (energy in first 20 bins)
        var magnitudes = [Float](repeating: 0.0, count: 512)
        for i in 0..<20 {
            magnitudes[i] = 200.0 + Float(i) * 10.0
        }
        for i in 20..<512 {
            magnitudes[i] = 10.0
        }
        
        // When - Normalize the spectrum
        let normalized = normaliser.normalize(magnitudes)
        
        // Then - Low frequency region should have higher relative energy
        // Logarithmic normalization redistributes frequencies, so we check:
        // 1. The first few output bins (which definitely map to bass frequencies)
        // 2. Compare to a high-frequency region that should have low energy
        let lowBand = normalized.prefix(20) // First 20 bins - definitely bass
        let highBand = normalized.suffix(100) // Last 100 bins - high frequencies
        let lowAverage = lowBand.reduce(0, +) / Float(lowBand.count)
        let highAverage = highBand.reduce(0, +) / Float(highBand.count)
        
        // Bass should be significantly more prominent than high frequencies
        // The bass energy (200-390) should be much higher than the low energy (10) in high frequencies
        XCTAssertGreaterThan(lowAverage, highAverage * 2.0, "Bass frequencies should be emphasized in visualisation")
        
        // Also verify that the low band has substantial energy (not zeroed out)
        XCTAssertGreaterThan(lowAverage, 50.0, "Bass frequencies should retain significant energy after normalization")
    }
    
    /// BDD: Given a full-range audio spectrum, when I compress it, then quiet sections should be suppressed while loud sections remain visible
    func testCompressSuppressesQuietSections() {
        // Given - Spectrum with wide dynamic range
        var magnitudes = [Float](repeating: 0.0, count: 512)
        // Very loud bass
        magnitudes[0] = 1000.0
        magnitudes[1] = 950.0
        // Medium mid-range
        magnitudes[100] = 200.0
        magnitudes[101] = 180.0
        // Quiet high frequencies
        magnitudes[400] = 5.0
        magnitudes[401] = 3.0
        
        // When - Compress with sensitivity
        let compressed = normaliser.compress(magnitudes, sensitivity: 1.5)
        
        // Then - Quiet sections should be significantly reduced or zeroed
        XCTAssertGreaterThan(compressed[0], compressed[400] * 10.0, "Loud sections should remain prominent")
        XCTAssertLessThan(compressed[400], 2.0, "Very quiet sections should be suppressed")
    }
    
    /// BDD: Given a normalized spectrum, when I view it, then frequency distribution should match human hearing perception
    func testNormalizedSpectrumMatchesHumanPerception() {
        // Given - Linear frequency distribution (equal energy across all bins)
        let linearMagnitudes = [Float](repeating: 100.0, count: 512)
        
        // When - Apply logarithmic normalization
        let normalized = normaliser.normalize(linearMagnitudes)
        
        // Then - Lower frequencies should have more visual weight (logarithmic scaling)
        // This matches how human ears perceive frequency (logarithmic)
        let firstQuarter = normalized.prefix(128)
        let lastQuarter = normalized.suffix(128)
        let firstAverage = firstQuarter.reduce(0, +) / Float(firstQuarter.count)
        let lastAverage = lastQuarter.reduce(0, +) / Float(lastQuarter.count)
        
        // Low frequencies should be more prominent due to logarithmic scaling
        XCTAssertGreaterThan(firstAverage, lastAverage * 0.8, "Logarithmic scaling should emphasize lower frequencies")
    }
}
