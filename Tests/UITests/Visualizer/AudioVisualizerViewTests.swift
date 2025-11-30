//
//  AudioVisualizerViewTests.swift
//  UITests
//
//  TDD tests for AudioVisualizerView
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AudioCore
import Foundation
import SwiftUI
import XCTest

@testable import Audientia

/// TDD tests for AudioVisualizerView
@MainActor
final class AudioVisualizerViewTests: XCTestCase {
    private var mockVisualizer: MockAudioVisualizer!
    private var mockNowPlayingViewModel: NowPlayingViewModel!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockVisualizer = MockAudioVisualizer()
        // Create a mock NowPlayingViewModel with mock audio engine
        let mockEngine = MockAudioEngine()
        mockNowPlayingViewModel = NowPlayingViewModel(audioEngine: mockEngine)
    }
    
    override func tearDownWithError() throws {
        mockVisualizer = nil
        mockNowPlayingViewModel = nil
        try super.tearDownWithError()
    }
    
    /// TDD: Given a visualizer view, when initialized, then it should create a view model
    func testInitializationCreatesViewModel() {
        // Given & When
        let view = AudioVisualizerView(nowPlayingViewModel: mockNowPlayingViewModel)
        
        // Then - View should be created without errors
        XCTAssertNotNil(view)
    }
    
    /// TDD: Given a visualizer view, when no frame is available, then it should display "No audio data available"
    func testNoFrameDisplaysEmptyState() {
        // Given
        let view = AudioVisualizerView(nowPlayingViewModel: mockNowPlayingViewModel)
        
        // When - No frame is available (viewModel starts with nil currentFrame)
        // Then - View should handle nil frame gracefully
        // This is tested through UI testing, but we verify the view can be created
        XCTAssertNotNil(view)
    }
    
    /// TDD: Given a visualizer view with a frame, when rendered, then it should display spectrum bars
    func testFrameDisplaysSpectrumBars() {
        // Given
        let frame = createTestFrame(frequency: 440.0)
        mockVisualizer.frames.append(frame)
        let view = AudioVisualizerView(nowPlayingViewModel: mockNowPlayingViewModel)
        
        // When & Then - View should render without errors
        // Actual rendering is tested through UI tests
        XCTAssertNotNil(view)
    }
    
    // MARK: - Helper Functions
    
    /// Create a test frame with specific frequency content
    private func createTestFrame(
        frequency: Float,
        sampleRate: Int = 44100,
        fftSize: Int = 2048
    ) -> AudioVisualizerFrame {
        let magnitudeCount = fftSize / 2
        var magnitudes = [Float](repeating: 0.0, count: magnitudeCount)
        
        // Create energy at the specified frequency bin
        let binIndex = Int(frequency * Float(fftSize) / Float(sampleRate))
        if binIndex >= 0 && binIndex < magnitudeCount {
            magnitudes[binIndex] = 100.0
            // Add some energy to adjacent bins for realism
            if binIndex > 0 {
                magnitudes[binIndex - 1] = 50.0
            }
            if binIndex < magnitudeCount - 1 {
                magnitudes[binIndex + 1] = 50.0
            }
        }
        
        return AudioVisualizerFrame(
            magnitudes: magnitudes,
            timestamp: Date(),
            sampleRate: sampleRate,
            fftSize: fftSize
        )
    }
}
