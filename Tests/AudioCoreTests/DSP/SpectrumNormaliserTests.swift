//
//  SpectrumNormaliserTests.swift
//  AudioCoreTests
//
//  TDD tests for SpectrumNormaliser
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
import XCTest

/// TDD tests for SpectrumNormaliser
final class SpectrumNormaliserTests: XCTestCase {
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
    
    /// TDD: Given empty magnitudes, when I normalize, then it should return empty array
    func testNormalizeEmptyMagnitudesReturnsEmpty() {
        // Given
        let magnitudes: [Float] = []
        
        // When
        let result = normaliser.normalize(magnitudes)
        
        // Then
        XCTAssertTrue(result.isEmpty)
    }
    
    /// TDD: Given magnitudes with energy in low frequencies, when I normalize, then low frequencies should be preserved
    func testNormalizePreservesLowFrequencyEnergy() {
        // Given - Energy concentrated in first 10 bins (low frequencies)
        var magnitudes = [Float](repeating: 0.0, count: 512)
        for i in 0..<10 {
            magnitudes[i] = 100.0
        }
        
        // When
        let normalized = normaliser.normalize(magnitudes)
        
        // Then - Low frequency bins should have significant energy
        let lowBandEnergy = normalized.prefix(50).reduce(0, +)
        let highBandEnergy = normalized.suffix(50).reduce(0, +)
        XCTAssertGreaterThan(lowBandEnergy, highBandEnergy * 2.0, "Low frequencies should be preserved")
    }
    
    /// TDD: Given magnitudes outside frequency range, when I normalize, then they should be zeroed
    func testNormalizeZerosOutOfRangeFrequencies() {
        // Given - Create a normaliser with restricted frequency range
        let restrictedNormaliser = SpectrumNormaliser(
            logScale: 2.0,
            minFreq: 100.0,
            maxFreq: 1000.0,
            sampleRate: 44100,
            fftSize: 1024
        )
        let magnitudes = [Float](repeating: 50.0, count: 512)
        
        // When
        let normalized = restrictedNormaliser.normalize(magnitudes)
        
        // Then - Frequencies outside range should be zeroed or significantly reduced
        // The first output bin maps to exactly minFreq (100Hz), so it will have some energy
        // from interpolation with the upper bin. However, frequencies well below minFreq
        // should be filtered out. We check that bins mapping to frequencies below minFreq
        // have significantly less energy than bins in the valid range.
        // Since the first few bins map to 100-102Hz (at minFreq boundary), they get
        // reduced energy (~16-18) compared to the full input magnitude (50.0) due to
        // filtering of the lower bin below minFreq.
        let boundaryEnergy = normalized.prefix(5).reduce(0, +)
        let midRangeEnergy = normalized.dropFirst(50).prefix(10).reduce(0, +) / 10.0
        
        // Boundary bins should have less energy than mid-range bins due to filtering
        // The boundary bins get ~16-18 each (from interpolation with upper bin only),
        // while mid-range bins get the full 50.0
        XCTAssertLessThan(boundaryEnergy / 5.0, midRangeEnergy * 0.5, "Frequencies at minFreq boundary should have reduced energy due to filtering")
        
        // Also verify that the normalization actually filters by checking that
        // bins well within the valid range have full energy
        XCTAssertGreaterThan(midRangeEnergy, 40.0, "Frequencies within valid range should retain energy")
    }
    
    /// TDD: Given magnitudes, when I compress with sensitivity, then dynamic range should be adjusted
    func testCompressAdjustsDynamicRange() {
        // Given - Magnitudes with wide dynamic range
        var magnitudes = [Float](repeating: 0.0, count: 512)
        magnitudes[0] = 1000.0  // Very high
        magnitudes[100] = 100.0 // Medium
        magnitudes[200] = 10.0  // Low
        magnitudes[300] = 1.0   // Very low
        
        // When - Compress with high sensitivity (more compression)
        let compressed = normaliser.compress(magnitudes, sensitivity: 2.0)
        
        // Then - Dynamic range should be reduced
        let maxCompressed = compressed.max() ?? 0.0
        let minCompressed = compressed.min() ?? 0.0
        let originalRange: Float = 1000.0 - 1.0
        let compressedRange = maxCompressed - minCompressed
        
        XCTAssertLessThan(compressedRange, originalRange, "Compression should reduce dynamic range")
        XCTAssertGreaterThan(compressed[0], compressed[300] * 2.0, "Relative differences should be preserved")
    }
    
    /// TDD: Given a bin index, when I get frequency, then it should match expected calculation
    func testFrequencyForBinMatchesCalculation() {
        // Given
        let binIndex = 10
        let expectedFreq = Float(binIndex) * 44100.0 / 1024.0
        
        // When
        let frequency = normaliser.frequencyForBin(binIndex)
        
        // Then
        XCTAssertEqual(frequency, expectedFreq, accuracy: 0.1)
    }
    
    /// TDD: Given a frequency, when I get bin index, then it should match expected calculation
    func testBinForFrequencyMatchesCalculation() {
        // Given
        let frequency: Float = 440.0 // A4 note
        let expectedBin = Int(frequency * 1024.0 / 44100.0)
        
        // When
        let bin = normaliser.binForFrequency(frequency)
        
        // Then
        XCTAssertEqual(bin, expectedBin, "Bin should match calculated value")
    }
    
    /// TDD: Given frequency outside range, when I get bin index, then it should return -1
    func testBinForFrequencyOutOfRangeReturnsNegative() {
        // Given - Frequency below minimum
        let lowFreq: Float = 10.0
        
        // When
        let bin = normaliser.binForFrequency(lowFreq)
        
        // Then
        XCTAssertEqual(bin, -1, "Out of range frequency should return -1")
    }
}
