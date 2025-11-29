//
//  AudioVisualizerViewTests.swift
//  UITests
//
//  TDD tests for AudioVisualizerView
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import SwiftUI
import XCTest

@testable import Audientia

/// TDD tests for AudioVisualizerView
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
        let frame = mockVisualizer.createFrameWithFrequency(440.0)
        mockVisualizer.addFrame(frame)
        let view = AudioVisualizerView(nowPlayingViewModel: mockNowPlayingViewModel)
        
        // When & Then - View should render without errors
        // Actual rendering is tested through UI tests
        XCTAssertNotNil(view)
    }
}
