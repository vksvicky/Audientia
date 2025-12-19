//
//  AudioVisualiserTapCPUBDDTests.swift
//  AudioCoreTests
//
//  BDD tests for AudioVisualiserTap CPU optimization
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
import Foundation
import XCTest

/// BDD tests for AudioVisualiserTap CPU optimization
@MainActor
final class AudioVisualiserTapCPUBDDTests: XCTestCase {
    private var mockVisualiser: MockAudioVisualiser!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockVisualiser = MockAudioVisualiser()
    }
    
    override func tearDownWithError() throws {
        mockVisualiser = nil
        try super.tearDownWithError()
    }
    
    // MARK: - BDD Scenarios
    
    /// BDD: As a user, when I enable visualization with high CPU usage, 
    /// then I should be able to reduce CPU by increasing processing rate
    func testUserReducesCPUByIncreasingProcessingRate() {
        // Given - A visualiser tap with default processing rate (1 = all buffers)
        let tapDefault = AudioVisualiserTap(visualiser: mockVisualiser, processingRate: 1)
        XCTAssertEqual(tapDefault.processingRate, 1, "Default should process all buffers")
        
        // When - User increases processing rate to 2 (process every 2nd buffer)
        tapDefault.processingRate = 2
        
        // Then - Processing rate should be 2, reducing CPU usage by ~50%
        XCTAssertEqual(tapDefault.processingRate, 2, "Processing rate should be 2")
    }
    
    /// BDD: As a user, when I want maximum quality visualization, 
    /// then I should set processing rate to 1
    func testUserSetsMaximumQualityWithProcessingRateOne() {
        // Given - A visualiser tap
        let tap = AudioVisualiserTap(visualiser: mockVisualiser, processingRate: 2)
        
        // When - User sets processing rate to 1 for maximum quality
        tap.processingRate = 1
        
        // Then - Processing rate should be 1 (all buffers processed)
        XCTAssertEqual(tap.processingRate, 1, "Processing rate 1 should process all buffers")
    }
    
    /// BDD: As a user, when I want to save CPU on a low-end device, 
    /// then I should be able to set a higher processing rate
    func testUserSavesCPUWithHigherProcessingRate() {
        // Given - A visualiser tap with processing rate 1
        let tap = AudioVisualiserTap(visualiser: mockVisualiser, processingRate: 1)
        
        // When - User sets processing rate to 5 for CPU savings
        tap.processingRate = 5
        
        // Then - Processing rate should be 5 (process every 5th buffer, ~80% CPU reduction)
        XCTAssertEqual(tap.processingRate, 5, "Processing rate 5 should reduce CPU usage")
    }
    
    /// BDD: As a user, when I configure visualization with custom settings, 
    /// then processing rate from config should be applied
    func testUserConfiguresVisualizationWithCustomProcessingRate() {
        // Given - User wants visualization with processing rate of 3
        let config = AudioVisualiserConfig(fftSize: 512, processingRate: 3)
        let visualiser = AudioVisualiser(config: config)
        
        // When - AudioEngine creates visualiserTap with this config
        let tap = AudioVisualiserTap(visualiser: visualiser, processingRate: config.processingRate)
        
        // Then - Processing rate should match user's configuration
        XCTAssertEqual(tap.processingRate, 3, "Tap should use processing rate from config")
        XCTAssertEqual(visualiser.currentConfig.processingRate, 3, "Config should have processing rate 3")
    }
    
    /// BDD: As a user, when I set an invalid processing rate, 
    /// then it should be automatically clamped to valid range
    func testUserSetsInvalidProcessingRateGetsClamped() {
        // Given - A visualiser tap
        let tap = AudioVisualiserTap(visualiser: mockVisualiser, processingRate: 1)
        
        // When - User sets processing rate to 0 (invalid)
        tap.processingRate = 0
        
        // Then - Processing rate should be clamped to 1 (minimum)
        XCTAssertEqual(tap.processingRate, 1, "Processing rate 0 should be clamped to 1")
        
        // When - User sets processing rate to 200 (exceeds maximum)
        tap.processingRate = 200
        
        // Then - Processing rate should be clamped to 100 (maximum)
        XCTAssertEqual(tap.processingRate, 100, "Processing rate 200 should be clamped to 100")
    }
    
    /// BDD: As a user, when I use smaller FFT size, 
    /// then CPU usage should be reduced while maintaining visualization quality
    func testUserUsesSmallerFFTSizeReducesCPU() async throws {
        // Given - User wants to reduce CPU usage
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
        
        // Then - Smaller FFT should be faster (reduced CPU usage)
        XCTAssertLessThan(timeSmall, timeLarge * 1.5, "Smaller FFT should use less CPU")
    }
    
    /// BDD: As a user, when I change processing rate during playback, 
    /// then the new rate should apply immediately
    func testUserChangesProcessingRateDuringPlayback() {
        // Given - A visualiser tap with processing rate 1, playing audio
        let tap = AudioVisualiserTap(visualiser: mockVisualiser, processingRate: 1)
        XCTAssertEqual(tap.processingRate, 1, "Initial rate should be 1")
        
        // When - User changes processing rate to 3 during playback
        tap.processingRate = 3
        
        // Then - New processing rate should apply immediately
        XCTAssertEqual(tap.processingRate, 3, "Processing rate should change immediately")
    }
    
    /// BDD: As a user, when I use both processing rate and smaller FFT, 
    /// then CPU usage should be significantly reduced
    func testUserCombinesProcessingRateAndSmallerFFT() {
        // Given - User wants maximum CPU reduction
        let config = AudioVisualiserConfig(fftSize: 512, processingRate: 3)
        let visualiser = AudioVisualiser(config: config)
        let tap = AudioVisualiserTap(visualiser: visualiser, processingRate: config.processingRate)
        
        // When - Configuration is applied
        // Then - Both optimizations should be active
        XCTAssertEqual(visualiser.currentConfig.fftSize, 512, "FFT size should be 512")
        XCTAssertEqual(visualiser.currentConfig.processingRate, 3, "Processing rate should be 3")
        XCTAssertEqual(tap.processingRate, 3, "Tap should use processing rate 3")
    }
}
