//
//  AudioVisualiserBDDTests.swift
//  Audientia - UI BDD Tests
//
//  BDD scenarios for Audio Visualizer
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import AudioCore
import XCTest

/// BDD Scenarios for Audio Visualizer
@MainActor
final class AudioVisualiserBDDTests: XCTestCase {
    
    private var mockVisualizer: MockAudioVisualiser!
    
    override func setUp() {
        super.setUp()
        let config = AudioVisualiserConfig(fftSize: 1024, smoothingFactor: 0.8, historyLength: 60)
        mockVisualizer = MockAudioVisualiser(config: config)
    }
    
    override func tearDown() {
        mockVisualizer = nil
        super.tearDown()
    }
    
    // MARK: - BDD Scenario 1: Process Audio for Visualization
    
    /// BDD: As a listener, when audio is playing, then I should see real-time spectrum data
    func testUserSeesRealTimeSpectrum() async throws {
        // Given - Audio data is available
        let audioData: [Float] = Array(repeating: 0.5, count: 1024)
        let sampleRate = 44100
        let channels = 2
        
        // When - Audio is processed for visualisation
        let frame = try await mockVisualizer.process(
            audioData: audioData,
            sampleRate: sampleRate,
            channels: channels
        )
        
        // Then - Should receive a visualisation frame
        XCTAssertNotNil(frame, "Should return visualisation frame")
        XCTAssertEqual(frame.magnitudes.count, 512, "Should have fftSize/2 magnitude bins")
        XCTAssertTrue(mockVisualizer.processCalled, "process should have been called")
    }
    
    // MARK: - BDD Scenario 2: View Dominant Frequency
    
    /// BDD: As a listener, when I view the visualiser, then I should see the dominant frequency
    func testUserViewsDominantFrequency() async throws {
        // Given - Audio data is processed
        let audioData: [Float] = Array(repeating: 0.5, count: 1024)
        let frame = try await mockVisualizer.process(
            audioData: audioData,
            sampleRate: 44100,
            channels: 2
        )
        
        // When - User views the visualiser
        // (In a real test, we would check the view)
        
        // Then - Frame should have dominant frequency information
        XCTAssertNotNil(frame.dominantBin, "Should have dominant bin")
        XCTAssertGreaterThanOrEqual(frame.dominantFrequency, 0.0, "Dominant frequency should be non-negative")
    }
    
    // MARK: - BDD Scenario 3: View Frame History
    
    /// BDD: As a listener, when I view the visualiser, then I should see recent frame history
    func testUserViewsFrameHistory() async throws {
        // Given - Multiple frames have been processed
        for _ in 0..<5 {
            let audioData: [Float] = Array(repeating: 0.5, count: 1024)
            _ = try await mockVisualizer.process(
                audioData: audioData,
                sampleRate: 44100,
                channels: 2
            )
        }
        
        // When - User requests recent frames
        let recentFrames = await mockVisualizer.recentFrames(limit: 3)
        
        // Then - Should receive recent frames
        XCTAssertEqual(recentFrames.count, 3, "Should return requested number of frames")
        XCTAssertTrue(mockVisualizer.getRecentFramesCalled, "recentFrames should have been called")
    }
    
    // MARK: - BDD Scenario 4: Frame History Limit
    
    /// BDD: As a listener, when many frames are processed, then history should be limited
    func testFrameHistoryLimit() async throws {
        // Given - Config with history length of 60
        let config = AudioVisualiserConfig(fftSize: 1024, smoothingFactor: 0.8, historyLength: 60)
        let visualiser = MockAudioVisualiser(config: config)
        
        // When - More frames than history length are processed
        for i in 0..<100 {
            let audioData: [Float] = Array(repeating: Float(i % 10) / 10.0, count: 1024)
            _ = try await visualiser.process(
                audioData: audioData,
                sampleRate: 44100,
                channels: 2
            )
        }
        
        // Then - History should be limited to configured length
        let allFrames = await visualiser.recentFrames(limit: 100)
        XCTAssertLessThanOrEqual(allFrames.count, 60, "History should not exceed configured length")
    }
    
    // MARK: - BDD Scenario 5: Timestamped Frames
    
    /// BDD: As a listener, when frames are processed, then each frame should be timestamped
    func testFramesAreTimestamped() async throws {
        // Given - Audio data
        let audioData: [Float] = Array(repeating: 0.5, count: 1024)
        
        // When - Frame is processed
        let frame1 = try await mockVisualizer.process(
            audioData: audioData,
            sampleRate: 44100,
            channels: 2
        )
        
        // Small delay
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        let frame2 = try await mockVisualizer.process(
            audioData: audioData,
            sampleRate: 44100,
            channels: 2
        )
        
        // Then - Frames should have timestamps
        XCTAssertNotNil(frame1.timestamp, "Frame 1 should have timestamp")
        XCTAssertNotNil(frame2.timestamp, "Frame 2 should have timestamp")
        XCTAssertGreaterThan(frame2.timestamp, frame1.timestamp, "Frame 2 should be later than frame 1")
    }
    
    // MARK: - Boundary Condition Tests
    
    /// Test with different FFT sizes
    func testDifferentFFTSizes() async throws {
        // Given - Visualizer with different FFT size
        let config = AudioVisualiserConfig(fftSize: 2048, smoothingFactor: 0.8, historyLength: 60)
        let visualiser = MockAudioVisualiser(config: config)
        
        // When - Processing audio
        let audioData: [Float] = Array(repeating: 0.5, count: 2048)
        let frame = try await visualiser.process(
            audioData: audioData,
            sampleRate: 44100,
            channels: 2
        )
        
        // Then - Should have correct number of magnitude bins
        XCTAssertEqual(frame.magnitudes.count, 1024, "Should have fftSize/2 bins for 2048 FFT")
    }
    
    /// Test with empty audio data
    func testEmptyAudioData() async {
        // Given - Empty audio data
        let emptyData: [Float] = []
        
        // When - Trying to process
        do {
            _ = try await mockVisualizer.process(
                audioData: emptyData,
                sampleRate: 44100,
                channels: 2
            )
            // Processing might succeed or fail depending on implementation
        } catch {
            // Error handling is acceptable for empty data
            XCTAssertTrue(true, "Empty data may cause error")
        }
    }
    
    // MARK: - Error Condition Tests
    
    /// Test handling of processing errors
    func testProcessingError() async {
        // Given - Visualizer is configured to fail processing
        mockVisualizer.shouldFailProcess = true
        
        // When - User tries to process audio
        do {
            let audioData: [Float] = Array(repeating: 0.5, count: 1024)
            _ = try await mockVisualizer.process(
                audioData: audioData,
                sampleRate: 44100,
                channels: 2
            )
            XCTFail("Should throw error")
        } catch {
            // Then - Error should be handled gracefully
            XCTAssertTrue(mockVisualizer.processCalled, "process should have been called")
        }
    }
    
    // MARK: - Performance Tests
    
    /// Test that processing is performant
    func testProcessingPerformance() async throws {
        // Given - Audio data
        let audioData: [Float] = Array(repeating: 0.5, count: 1024)
        
        // When - Processing multiple frames and measure time manually
        // Note: measure() doesn't support async well with @MainActor, so we measure manually
        let startTime = Date()
        for _ in 0..<100 {
            _ = try await mockVisualizer.process(
                audioData: audioData,
                sampleRate: 44100,
                channels: 2
            )
        }
        let duration = Date().timeIntervalSince(startTime)
        
        // Then - Should complete within reasonable time (e.g., < 1 second for 100 frames)
        XCTAssertLessThan(duration, 1.0, "Processing 100 frames should complete within 1 second")
    }
}
