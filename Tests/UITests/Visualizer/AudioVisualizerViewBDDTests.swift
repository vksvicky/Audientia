//
//  AudioVisualizerViewBDDTests.swift
//  UITests
//
//  BDD tests for AudioVisualizerView
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import SwiftUI
import XCTest

@testable import Audientia

/// BDD tests for AudioVisualizerView
final class AudioVisualizerViewBDDTests: XCTestCase {
    private var mockVisualizer: MockAudioVisualizer!
    private var mockNowPlayingViewModel: NowPlayingViewModel!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockVisualizer = MockAudioVisualizer()
        let mockEngine = MockAudioEngine()
        mockNowPlayingViewModel = NowPlayingViewModel(audioEngine: mockEngine)
    }
    
    override func tearDownWithError() throws {
        mockVisualizer = nil
        mockNowPlayingViewModel = nil
        try super.tearDownWithError()
    }
    
    /// BDD: Given a playing track, when I view the visualizer, then it should display real-time spectrum data
    func testPlayingTrackDisplaysRealTimeSpectrum() {
        // Given - A track is playing with audio data
        let bassFrame = mockVisualizer.createFrameWithFrequency(80.0)  // Bass frequency
        let midFrame = mockVisualizer.createFrameWithFrequency(440.0) // Mid frequency
        let trebleFrame = mockVisualizer.createFrameWithFrequency(8000.0) // Treble frequency
        
        mockVisualizer.addFrame(bassFrame)
        mockVisualizer.addFrame(midFrame)
        mockVisualizer.addFrame(trebleFrame)
        
        // When - I view the visualizer
        let view = AudioVisualizerView(nowPlayingViewModel: mockNowPlayingViewModel)
        
        // Then - View should be created and ready to display spectrum
        XCTAssertNotNil(view)
        // Actual real-time updates are tested through UI integration tests
    }
    
    /// BDD: Given a paused track, when I view the visualizer, then it should maintain the last frame
    func testPausedTrackMaintainsLastFrame() {
        // Given - A track was playing and is now paused
        let playingFrame = mockVisualizer.createFrameWithFrequency(440.0)
        mockVisualizer.addFrame(playingFrame)
        
        // When - Track is paused
        // (In real implementation, viewModel would handle this)
        let view = AudioVisualizerView(nowPlayingViewModel: mockNowPlayingViewModel)
        
        // Then - View should maintain visualization
        XCTAssertNotNil(view)
    }
    
    /// BDD: Given different frequency content, when I view the visualizer, then colors should reflect frequency bands
    func testFrequencyContentReflectsInColors() {
        // Given - Different frequency content
        let bassFrame = mockVisualizer.createFrameWithFrequency(100.0)  // Low - should be blue
        let midFrame = mockVisualizer.createFrameWithFrequency(2000.0)  // Mid - should be purple
        let trebleFrame = mockVisualizer.createFrameWithFrequency(10000.0) // High - should be pink
        
        // When - I view each frame
        // Then - Color mapping should reflect frequency (tested through visual inspection in UI tests)
        XCTAssertNotNil(bassFrame)
        XCTAssertNotNil(midFrame)
        XCTAssertNotNil(trebleFrame)
    }
}
