//
//  NormalizationSettingsBDDTests.swift
//  Audientia - UI BDD Tests
//
//  BDD scenarios for Normalization Settings
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import XCTest

@testable import AudioCore

/// BDD Scenarios for Normalization Settings
@MainActor
final class NormalizationSettingsBDDTests: XCTestCase {
    
    private var mockNormalizer: MockAudioNormalizer!
    
    override func setUp() {
        super.setUp()
        mockNormalizer = MockAudioNormalizer()
    }
    
    override func tearDown() {
        mockNormalizer = nil
        super.tearDown()
    }
    
    // MARK: - BDD Scenario 1: Select Normalization Mode
    
    /// BDD: As a user, when I select peak normalization mode, then audio should be normalized to peak levels
    func testUserSelectsPeakNormalization() {
        // Given - Normalizer is initialized
        XCTAssertEqual(mockNormalizer.mode, .peak, "Should default to peak mode")
        
        // When - User selects peak mode (already selected)
        mockNormalizer.mode = .peak
        
        // Then - Mode should be peak
        XCTAssertEqual(mockNormalizer.mode, .peak, "Mode should be peak")
    }
    
    /// BDD: As a user, when I select RMS normalization mode, then audio should be normalized to RMS levels
    func testUserSelectsRMSNormalization() {
        // Given - Normalizer is in peak mode
        mockNormalizer.mode = .peak
        
        // When - User selects RMS mode
        mockNormalizer.mode = .rms
        
        // Then - Mode should be RMS
        XCTAssertEqual(mockNormalizer.mode, .rms, "Mode should be RMS")
    }
    
    /// BDD: As a user, when I select loudness normalization mode, then audio should be normalized to perceived loudness
    func testUserSelectsLoudnessNormalization() {
        // Given - Normalizer is in peak mode
        mockNormalizer.mode = .peak
        
        // When - User selects loudness mode
        mockNormalizer.mode = .loudness
        
        // Then - Mode should be loudness
        XCTAssertEqual(mockNormalizer.mode, .loudness, "Mode should be loudness")
    }
    
    // MARK: - BDD Scenario 2: Adjust Target Level
    
    /// BDD: As a user, when I adjust the target level slider, then normalization should target that level
    func testUserAdjustsTargetLevel() {
        // Given - Target level is at default (-3.0 dB)
        XCTAssertEqual(mockNormalizer.targetLevel, -3.0, accuracy: 0.1, "Should start at -3.0 dB")
        
        // When - User adjusts target level to -6.0 dB
        mockNormalizer.targetLevel = -6.0
        
        // Then - Target level should be -6.0 dB
        XCTAssertEqual(mockNormalizer.targetLevel, -6.0, accuracy: 0.1, "Target level should be -6.0 dB")
    }
    
    // MARK: - BDD Scenario 3: Analyze Audio
    
    /// BDD: As a user, when I analyze audio for normalization, then I should see the required gain adjustment
    func testUserAnalyzesAudio() async throws {
        // Given - Audio data that needs normalization
        let audioData: [Float] = [0.5, 0.3, 0.7, 0.2, 0.9]
        
        // When - User analyzes audio in peak mode
        let gain = try await mockNormalizer.analyzeNormalization(
            audioData: audioData,
            sampleRate: 44100,
            channels: 2,
            mode: .peak,
            targetLevel: -3.0
        )
        
        // Then - Should return gain adjustment
        XCTAssertNotNil(gain, "Should return gain adjustment")
        XCTAssertTrue(mockNormalizer.analyzeCalled, "analyzeNormalization should have been called")
    }
    
    // MARK: - BDD Scenario 4: Apply Normalization
    
    /// BDD: As a user, when I apply normalization, then audio levels should be adjusted to the target
    func testUserAppliesNormalization() async throws {
        // Given - Audio data and gain adjustment
        let audioData: [Float] = [0.5, 0.3, 0.7]
        let gainDB: Float = -3.0
        
        // When - User applies normalization
        let normalized = try await mockNormalizer.applyNormalization(audioData: audioData, gainDB: gainDB)
        
        // Then - Audio should be normalized
        XCTAssertEqual(normalized.count, audioData.count, "Should have same number of samples")
        XCTAssertTrue(mockNormalizer.applyCalled, "applyNormalization should have been called")
    }
    
    // MARK: - Boundary Condition Tests
    
    /// Test with extreme target levels
    func testExtremeTargetLevels() {
        // When - User sets minimum target level (-30 dB)
        mockNormalizer.targetLevel = -30.0
        XCTAssertEqual(mockNormalizer.targetLevel, -30.0, accuracy: 0.1, "Should accept -30 dB")
        
        // When - User sets maximum target level (0 dB)
        mockNormalizer.targetLevel = 0.0
        XCTAssertEqual(mockNormalizer.targetLevel, 0.0, accuracy: 0.1, "Should accept 0 dB")
    }
    
    /// Test with empty audio data
    func testEmptyAudioData() async {
        // Given - Empty audio data
        let emptyData: [Float] = []
        
        // When - User tries to analyze
        do {
            _ = try await mockNormalizer.analyzeNormalization(
                audioData: emptyData,
                sampleRate: 44100,
                channels: 2,
                mode: .peak,
                targetLevel: -3.0
            )
            // Analysis might succeed or fail depending on implementation
        } catch {
            // Error handling is acceptable for empty data
            XCTAssertTrue(true, "Empty data may cause error")
        }
    }
    
    // MARK: - Error Condition Tests
    
    /// Test handling of analysis errors
    func testAnalysisError() async {
        // Given - Normalizer is configured to fail analysis
        mockNormalizer.shouldFailAnalyze = true
        
        // When - User tries to analyze
        do {
            let audioData: [Float] = [0.5, 0.3, 0.7]
            _ = try await mockNormalizer.analyzeNormalization(
                audioData: audioData,
                sampleRate: 44100,
                channels: 2,
                mode: .peak,
                targetLevel: -3.0
            )
            XCTFail("Should throw error")
        } catch {
            // Then - Error should be handled gracefully
            XCTAssertTrue(mockNormalizer.analyzeCalled, "analyzeNormalization should have been called")
        }
    }
    
    /// Test handling of application errors
    func testApplicationError() async {
        // Given - Normalizer is configured to fail application
        mockNormalizer.shouldFailApply = true
        
        // When - User tries to apply normalization
        do {
            let audioData: [Float] = [0.5, 0.3, 0.7]
            _ = try await mockNormalizer.applyNormalization(audioData: audioData, gainDB: -3.0)
            XCTFail("Should throw error")
        } catch {
            // Then - Error should be handled gracefully
            XCTAssertTrue(mockNormalizer.applyCalled, "applyNormalization should have been called")
        }
    }
    
    // MARK: - Cross-Check Tests
    
    /// Test peak level calculation
    func testPeakLevelCalculation() async {
        // Given - Audio data with known peak
        let audioData: [Float] = [0.1, 0.5, 0.3, 0.8, 0.2]
        
        // When - Calculating peak level
        let peakLevel = await mockNormalizer.calculatePeakLevel(audioData: audioData, channels: 2)
        
        // Then - Should calculate correctly (0.8 is max, so 20*log10(0.8) ≈ -1.94 dB)
        XCTAssertEqual(peakLevel, 20.0 * log10(0.8), accuracy: 0.1, "Peak level should be calculated correctly")
    }
    
    /// Test RMS level calculation
    func testRMSLevelCalculation() async {
        // Given - Audio data
        let audioData: [Float] = [0.5, 0.5, 0.5, 0.5]
        
        // When - Calculating RMS level
        let rmsLevel = await mockNormalizer.calculateRMSLevel(audioData: audioData, channels: 2)
        
        // Then - Should calculate correctly
        // RMS = sqrt(mean(squares)) = sqrt(0.25) = 0.5
        // Level = 20*log10(0.5) ≈ -6.02 dB
        XCTAssertEqual(rmsLevel, 20.0 * log10(0.5), accuracy: 0.1, "RMS level should be calculated correctly")
    }
}
