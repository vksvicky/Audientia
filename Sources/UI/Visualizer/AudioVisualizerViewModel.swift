//
//  AudioVisualizerViewModel.swift
//  Audientia
//
//  ViewModel for Audio Visualizer
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AudioCore
import Foundation
import SwiftUI

/// ViewModel for Audio Visualizer
@MainActor
final class AudioVisualizerViewModel: ObservableObject {
    @Published var currentFrame: AudioVisualizerFrame?
    @Published var fftSize: Int = 1024
    @Published var visualizationMode: VisualizationMode = .discreteFrequencies
    @Published var visualizationVolume: Float = 1.0 {
        didSet {
            updateVisualizationVolume()
        }
    }
    
    private let visualizer: AudioVisualizerProtocol
    private var visualizationTask: Task<Void, Never>?
    private let nowPlayingViewModel: NowPlayingViewModel?
    private weak var audioEngine: AudioEngine?
    
    init(nowPlayingViewModel: NowPlayingViewModel? = nil, audioEngine: AudioEngine? = nil) {
        self.nowPlayingViewModel = nowPlayingViewModel
        self.audioEngine = audioEngine
        // Use the audio engine's visualizer if available, otherwise create a new one
        self.visualizer = nowPlayingViewModel?.visualizer ?? AudioVisualizer()
        // Initialize volume from audio engine's visualizer tap if available
        if let engine = audioEngine {
            visualizationVolume = engine.getVisualizationVolume()
        }
    }
    
    private func updateVisualizationVolume() {
        // Update the visualization engine's volume in real-time
        // This will be implemented through AudioEngine's visualizerTap
        audioEngine?.setVisualizationVolume(visualizationVolume)
    }
    
    func startVisualization() async {
        // Run visualization in its own task to avoid blocking the main thread
        // This runs independently and is memory efficient (only stores current frame)
        let visualizer = self.visualizer
        let nowPlayingViewModel = self.nowPlayingViewModel
        
        visualizationTask = Task {
            var lastFrameTimestamp: Date?
            var consecutiveFallbacks = 0
            var wasPlaying = false // Track previous playback state to detect resume
            let maxFallbacks = 10 // Only use fallback if no real frames for 10 iterations (about 83ms)
            
            while !Task.isCancelled {
                let isCurrentlyPlaying = await MainActor.run {
                    nowPlayingViewModel?.isPlaying ?? false
                }
                
                // Detect transition from paused/stopped to playing (resume or restart)
                // This handles both pause→play and stop→play transitions
                let justResumed = !wasPlaying && isCurrentlyPlaying
                wasPlaying = isCurrentlyPlaying
                
                // Poll for latest frame from visualizer (non-blocking)
                // Prioritize real audio data over fallback
                if let frame = await visualizer.latestFrame() {
                    // Check if this is a new frame (different timestamp)
                    let isNewFrame = lastFrameTimestamp != frame.timestamp
                    
                    if isNewFrame {
                        await MainActor.run {
                            self.currentFrame = frame
                            self.fftSize = frame.fftSize
                        }
                        lastFrameTimestamp = frame.timestamp
                        consecutiveFallbacks = 0 // Reset fallback counter when we get real data
                    }
                } else {
                    consecutiveFallbacks += 1
                    
                    // If we just resumed, immediately show fallback frames to avoid blank screen
                    // Otherwise, wait for maxFallbacks to ensure we prioritize real audio data
                    let shouldShowFallback = justResumed || consecutiveFallbacks >= maxFallbacks
                    
                    // Only use fallback if we haven't received real frames for a while
                    // This ensures we prioritize real audio data from AudioVisualizerTap
                    if shouldShowFallback,
                       let nowPlayingViewModel = nowPlayingViewModel,
                       nowPlayingViewModel.isPlaying {
                        // Fallback only if playing and no real frames available after waiting
                        await MainActor.run {
                            self.createFallbackFrame()
                        }
                        // Reset counter after showing fallback to avoid rapid updates
                        if justResumed {
                            consecutiveFallbacks = maxFallbacks - 1
                        }
                    } else if let nowPlayingViewModel = nowPlayingViewModel,
                              !nowPlayingViewModel.isPlaying,
                              nowPlayingViewModel.currentTrack != nil {
                        // Paused/stopped - keep last frame or show static
                        await MainActor.run {
                            // Always show static frame when paused to maintain visual continuity
                            // This prevents blank screen when pausing
                            if self.currentFrame == nil {
                                self.createStaticFrame()
                            }
                        }
                    }
                }
                
                // Update at ~120 FPS (8.33ms intervals) for ultra-responsive visualization
                // This provides the smoothest, most real-time visual feedback
                // The task is cancelled when view disappears, preventing memory leaks
                try? await Task.sleep(nanoseconds: 8_333_333)
            }
        }
    }
    
    func stopVisualization() {
        visualizationTask?.cancel()
        visualizationTask = nil
    }
    
    // This would be called by the audio engine when processing audio
    func updateFrame(_ frame: AudioVisualizerFrame) {
        currentFrame = frame
    }
    
    // Fallback visualization when audio tap is not available
    // This creates a reactive pattern based on playback state
    // NOTE: For real audio-reactive visualization, the audio engine needs to use AVAudioEngine
    // with installTap to provide actual audio samples to the visualizer
    private func createFallbackFrame() {
        guard let nowPlayingViewModel = nowPlayingViewModel,
              nowPlayingViewModel.isPlaying else {
            currentFrame = nil
            return
        }
        
        let magnitudeCount = fftSize / 2
        var magnitudes = [Float](repeating: 0.0, count: magnitudeCount)
        
        // Create a more reactive pattern based on playback position and volume
        let time = Date().timeIntervalSince1970
        let position = nowPlayingViewModel.currentPosition
        let volume = Float(nowPlayingViewModel.volume)
        
        // Create frequency bands that respond to different aspects
        // More dynamic and responsive to match audioMotion-analyzer style
        for i in 0..<magnitudeCount {
            let frequency = Float(i) / Float(magnitudeCount)
            
            // Low frequencies (bass) - respond to position changes with more energy
            let bassWave = sin(Float(position) * 2.0 + Float(i) * 0.1) * (1.0 - frequency * 0.7)
            
            // Mid frequencies - respond to time and position with faster updates
            let midWave = sin(Float(time) * 8.0 * .pi * frequency * 3.0 + Float(position) * 1.0)
            
            // High frequencies - very fast animation for responsiveness
            let highWave = sin(Float(time) * 12.0 * .pi * frequency * 4.0 + Float(i) * 0.3)
            
            // Combine bands with volume scaling and more dynamic range
            let combined = (bassWave * 0.5 + midWave * 0.3 + highWave * 0.2) * volume
            // Scale to more visible range with better dynamics
            magnitudes[i] = max(0.0, combined * 80.0 + 30.0)
        }
        
        let sampleRate = 44100 // Default sample rate
        currentFrame = AudioVisualizerFrame(
            magnitudes: magnitudes,
            timestamp: Date(),
            sampleRate: sampleRate,
            fftSize: fftSize
        )
    }
    
    // Static visualization when paused/stopped but track is loaded
    // Maintains visual continuity instead of going blank
    private func createStaticFrame() {
        guard let nowPlayingViewModel = nowPlayingViewModel,
              nowPlayingViewModel.currentTrack != nil else {
            return
        }
        
        let magnitudeCount = fftSize / 2
        var magnitudes = [Float](repeating: 0.0, count: magnitudeCount)
        
        // Create a static but visible pattern when paused
        // Lower amplitude than playing state to indicate paused
        for i in 0..<magnitudeCount {
            let frequency = Float(i) / Float(magnitudeCount)
            // Create a gentle static pattern
            let staticWave = sin(Float(i) * 0.1) * (1.0 - frequency * 0.5)
            magnitudes[i] = max(0.0, staticWave * 15.0 + 5.0) // Lower amplitude for paused state
        }
        
        let sampleRate = 44100 // Default sample rate
        currentFrame = AudioVisualizerFrame(
            magnitudes: magnitudes,
            timestamp: Date(),
            sampleRate: sampleRate,
            fftSize: fftSize
        )
    }
}
