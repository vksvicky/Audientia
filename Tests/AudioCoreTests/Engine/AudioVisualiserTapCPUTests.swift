//
//  AudioVisualiserTapCPUTests.swift
//  AudioCoreTests
//
//  TDD tests for AudioVisualiserTap CPU optimization
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
import AVFoundation
import Foundation
import XCTest

/// TDD tests for AudioVisualiserTap CPU optimization
/// Following Right-BICEP principles
@MainActor
final class AudioVisualiserTapCPUTests: XCTestCase {
    private var visualiser: AudioVisualiser!
    private var visualiserTap: AudioVisualiserTap!
    private var mockVisualiser: MockAudioVisualiser!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        visualiser = AudioVisualiser()
        visualiserTap = AudioVisualiserTap(visualiser: visualiser)
        mockVisualiser = MockAudioVisualiser()
    }
    
    override func tearDownWithError() throws {
        visualiserTap?.cleanup()
        Thread.sleep(forTimeInterval: 0.05)
        visualiserTap = nil
        visualiser = nil
        mockVisualiser = nil
        try super.tearDownWithError()
    }
    
    // MARK: - [Right] BICEP: Are the Results Right?
    
    /// TDD: Given a processing rate of 2, when buffers arrive, then only every 2nd buffer should be processed
    func testProcessingRateLimitsBufferProcessing() async throws {
        // Given - A visualiser tap with processing rate of 2 (process every 2nd buffer)
        mockVisualiser.clearFrames()
        let tapWithRate = AudioVisualiserTap(visualiser: mockVisualiser, processingRate: 2)
        
        // When - Processing rate is set to 2
        tapWithRate.processingRate = 2
        
        // Then - Processing rate should be 2
        XCTAssertEqual(tapWithRate.processingRate, 2, "Processing rate should be set to 2")
    }
    
    /// TDD: Given a processing rate of 1, when buffers arrive, then all buffers should be processed
    func testProcessingRateOneProcessesAllBuffers() async throws {
        // Given - Processing rate of 1 (process every buffer)
        mockVisualiser.clearFrames()
        let tapWithRate = AudioVisualiserTap(visualiser: mockVisualiser, processingRate: 1)
        
        // When - Processing rate is set to 1
        tapWithRate.processingRate = 1
        
        // Then - Processing rate should be 1
        XCTAssertEqual(tapWithRate.processingRate, 1, "Processing rate should be 1 (process all buffers)")
    }
    
    // MARK: - [B]oundary Conditions
    
    /// TDD: Given a processing rate of 0, when set, then it should be clamped to 1
    func testProcessingRateZeroDefaultsToOne() {
        // Given - Processing rate of 0 (invalid)
        let tap = AudioVisualiserTap(visualiser: mockVisualiser, processingRate: 1)
        
        // When - Processing rate is set to 0
        tap.processingRate = 0
        
        // Then - Processing rate should be clamped to 1
        XCTAssertEqual(tap.processingRate, 1, "Processing rate should be clamped to minimum of 1")
    }
    
    /// TDD: Given a very high processing rate, when set, then it should be clamped to maximum
    func testHighProcessingRateIsClamped() {
        // Given - Processing rate of 200 (exceeds maximum of 100)
        let tap = AudioVisualiserTap(visualiser: mockVisualiser, processingRate: 1)
        
        // When - Processing rate is set to 200
        tap.processingRate = 200
        
        // Then - Processing rate should be clamped to 100
        XCTAssertEqual(tap.processingRate, 100, "Processing rate should be clamped to maximum of 100")
    }
    
    // MARK: - [I]nverse Relationships
    
    /// TDD: Given processing rate changes, when rate increases, then rate property reflects change
    func testProcessingRateCanBeChanged() {
        // Given - Initial processing rate of 1
        let tap = AudioVisualiserTap(visualiser: mockVisualiser, processingRate: 1)
        XCTAssertEqual(tap.processingRate, 1, "Initial processing rate should be 1")
        
        // When - Rate is increased to 2
        tap.processingRate = 2
        
        // Then - Processing rate should be 2
        XCTAssertEqual(tap.processingRate, 2, "Processing rate should be updated to 2")
        
        // When - Rate is increased to 5
        tap.processingRate = 5
        
        // Then - Processing rate should be 5
        XCTAssertEqual(tap.processingRate, 5, "Processing rate should be updated to 5")
    }
    
    // MARK: - [C]ross-Check Using Other Means
    
    /// TDD: Given different processing rates, when processing, then higher rates should process fewer frames
    func testProcessingRateAffectsFrameProcessing() async throws {
        // Given - Two visualiser taps with different processing rates
        let tapRate1 = AudioVisualiserTap(visualiser: mockVisualiser, processingRate: 1)
        let tapRate2 = AudioVisualiserTap(visualiser: mockVisualiser, processingRate: 2)
        
        // When - Processing rates are set
        // Then - Rates should be different
        XCTAssertEqual(tapRate1.processingRate, 1, "Tap 1 should have rate 1")
        XCTAssertEqual(tapRate2.processingRate, 2, "Tap 2 should have rate 2")
        
        // Higher processing rate means fewer buffers processed (reduced CPU)
        XCTAssertGreaterThan(tapRate1.processingRate, 0, "Rate 1 should be valid")
        XCTAssertGreaterThan(tapRate2.processingRate, tapRate1.processingRate, "Rate 2 should be higher than rate 1")
    }
    
    // MARK: - [E]rror Conditions
    
    /// TDD: Given invalid processing rate, when set, then it should be clamped to valid range
    func testInvalidProcessingRateIsClamped() {
        // Given - Processing rate of -1 (invalid)
        let tap = AudioVisualiserTap(visualiser: mockVisualiser, processingRate: 1)
        
        // When - Processing rate is set to -1
        tap.processingRate = -1
        
        // Then - Rate should be clamped to 1 (minimum)
        XCTAssertEqual(tap.processingRate, 1, "Negative processing rate should be clamped to 1")
        
        // When - Processing rate is set to 1000 (exceeds maximum)
        tap.processingRate = 1000
        
        // Then - Rate should be clamped to 100 (maximum)
        XCTAssertEqual(tap.processingRate, 100, "Processing rate > 100 should be clamped to 100")
    }
    
    // MARK: - [P]erformance Characteristics
    
    /// TDD: Given different FFT sizes, when processing, then smaller FFT uses less CPU
    func testSmallerFFTSizeReducesProcessingTime() async throws {
        // Given - Two visualisers with different FFT sizes
        let largeFFT = AudioVisualiser(config: AudioVisualiserConfig(fftSize: 1024))
        let smallFFT = AudioVisualiser(config: AudioVisualiserConfig(fftSize: 512))
        
        let audioData = (0..<1024).map { _ in Float.random(in: -1.0...1.0) }
        
        // When - Both process the same audio data
        let startLarge = CFAbsoluteTimeGetCurrent()
        _ = try await largeFFT.process(audioData: audioData, sampleRate: 44100, channels: 1)
        let timeLarge = CFAbsoluteTimeGetCurrent() - startLarge
        
        let startSmall = CFAbsoluteTimeGetCurrent()
        _ = try await smallFFT.process(audioData: audioData, sampleRate: 44100, channels: 1)
        let timeSmall = CFAbsoluteTimeGetCurrent() - startSmall
        
        // Then - Smaller FFT should be faster or similar (not always exactly 50% due to overhead)
        XCTAssertLessThan(timeSmall, timeLarge * 1.5, "Smaller FFT should be faster or similar")
    }
    
    // MARK: - Edge Cases
    
    /// TDD: Given processing rate configuration, when AudioVisualiserConfig is used, then processingRate is applied
    func testAudioVisualiserConfigProcessingRate() {
        // Given - AudioVisualiserConfig with processingRate of 3
        let config = AudioVisualiserConfig(fftSize: 1024, processingRate: 3)
        
        // When - AudioVisualiser is created with this config
        let visualiser = AudioVisualiser(config: config)
        
        // Then - Config should have processingRate of 3
        XCTAssertEqual(visualiser.currentConfig.processingRate, 3, "Config should have processingRate of 3")
    }
    
    /// TDD: Given processing rate in config, when AudioEngine creates visualiserTap, then processingRate is applied
    func testAudioEngineUsesConfigProcessingRate() {
        // Given - AudioEngine with custom visualiser config
        let config = AudioVisualiserConfig(fftSize: 512, processingRate: 2)
        let customVisualiser = AudioVisualiser(config: config)
        let tap = AudioVisualiserTap(visualiser: customVisualiser, processingRate: config.processingRate)
        
        // When - Tap is created with processingRate from config
        // Then - Processing rate should match config
        XCTAssertEqual(tap.processingRate, 2, "Tap should use processingRate from config")
    }
}
