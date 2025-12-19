//
//  AudioVisualiserViewModel.swift
//  Audientia
//
//  ViewModel for Audio Visualizer
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AudioCore
import Foundation
import Shared
import SwiftUI

/// ViewModel for Audio Visualizer
@MainActor
final class AudioVisualiserViewModel: ObservableObject {
    @Published var currentFrame: AudioVisualiserFrame?
    @Published var fftSize: Int = 1024
    @Published var visualisationMode: VisualisationMode = .discreteFrequencies {
        didSet {
            // Save visualization mode for restoration on app restart
            // Save synchronously to ensure immediate persistence and avoid race conditions in tests
            AppSettings.shared.lastVisualisationMode = visualisationMode.rawValue
        }
    }
    @Published var visualisationVolume: Float = 1.0 {
        didSet {
            updateVisualisationVolume()
        }
    }
    
    /// Current playback speed multiplier (affects visualization update rate)
    @Published var playbackSpeedMultiplier: Double = 1.0
    
    /// Sensitivity control (0.0 to 1.0, default 0.5)
    /// Higher values make the visualisation more reactive to audio changes
    @Published var sensitivity: Float = 0.5 {
        didSet {
            updateVisualisationSettings()
        }
    }
    
    /// Smoothing control (0.0 to 1.0, default 0.3)
    /// Higher values make transitions smoother and less jittery
    @Published var smoothing: Float = 0.3 {
        didSet {
            updateVisualisationSettings()
        }
    }
    
    private let visualiser: AudioVisualiserProtocol
    private var visualisationTask: Task<Void, Never>?
    private var nowPlayingViewModel: NowPlayingViewModel?
    private weak var audioEngine: AudioEngine?
    
    init(nowPlayingViewModel: NowPlayingViewModel? = nil, audioEngine: AudioEngine? = nil) {
        self.nowPlayingViewModel = nowPlayingViewModel
        self.audioEngine = audioEngine
        // Use the audio engine's visualiser if available, otherwise create a new one
        self.visualiser = nowPlayingViewModel?.visualiser ?? AudioVisualiser()
        // Initialise volume from audio engine's visualiser tap if available
        if let engine = audioEngine {
            visualisationVolume = engine.getVisualizationVolume()
        }
        
        // Restore last visualization mode from AppSettings
        if let savedMode = AppSettings.shared.lastVisualisationMode,
           let mode = VisualisationMode(rawValue: savedMode) {
            self.visualisationMode = mode
        }
    }
    
    /// Update the nowPlayingViewModel reference
    /// (used when ViewModel is created before nowPlayingViewModel is available)
    func updateNowPlayingViewModel(_ viewModel: NowPlayingViewModel?) {
        self.nowPlayingViewModel = viewModel
        // Update playback speed multiplier when view model changes
        updatePlaybackSpeedMultiplier()
    }
    
    /// Update playback speed multiplier from audio engine or view model
    private func updatePlaybackSpeedMultiplier() {
        if let engine = audioEngine {
            playbackSpeedMultiplier = engine.playbackSpeed.rawValue
        } else if let viewModel = nowPlayingViewModel {
            playbackSpeedMultiplier = viewModel.playbackSpeed.rawValue
        }
    }
    
    private func updateVisualisationVolume() {
        // Update the visualisation engine's volume in real-time
        // This will be implemented through AudioEngine's visualiserTap
        audioEngine?.setVisualizationVolume(visualisationVolume)
    }
    
    private func updateVisualisationSettings() {
        // Update visualisation settings (sensitivity and smoothing)
        // These affect how the visualiser processes and displays audio data
        // NOTE: Implementation will depend on AudioVisualiserProtocol capabilities
        // For now, these values are stored and can be used by the visualisation algorithms
    }
    
    func startVisualization() async {
        let visualiser = self.visualiser
        let nowPlayingViewModel = self.nowPlayingViewModel
        
        // Create an initial frame immediately so the visualiser shows something
        await MainActor.run {
            if currentFrame == nil {
                currentFrame = createInitialFrame()
            }
        }
        
        visualisationTask = Task {
            var lastFrameTimestamp: Date?
            var consecutiveFallbacks = 0
            var wasPlaying = false
            let maxFallbacks = 10
            
            while !Task.isCancelled {
                let (isCurrentlyPlaying, currentSpeed) = await getPlaybackState(from: nowPlayingViewModel)
                await updatePlaybackSpeedMultiplier(currentSpeed)
                
                let justResumed = !wasPlaying && isCurrentlyPlaying
                wasPlaying = isCurrentlyPlaying
                
                if let frame = await visualiser.latestFrame() {
                    await handleNewFrame(frame, &lastFrameTimestamp, &consecutiveFallbacks)
                } else {
                    await handleNoFrame(
                        justResumed: justResumed,
                        consecutiveFallbacks: &consecutiveFallbacks,
                        maxFallbacks: maxFallbacks,
                        nowPlayingViewModel: nowPlayingViewModel
                    )
                }
                
                let interval = calculateUpdateInterval()
                try? await Task.sleep(nanoseconds: interval)
            }
        }
    }
    
    private func getPlaybackState(from viewModel: NowPlayingViewModel?) async -> (Bool, Double) {
        await MainActor.run {
            (
                viewModel?.isPlaying ?? false,
                viewModel?.playbackSpeed.rawValue ?? 1.0
            )
        }
    }
    
    private func updatePlaybackSpeedMultiplier(_ speed: Double) async {
        await MainActor.run {
            playbackSpeedMultiplier = speed
        }
    }
    
    private func handleNewFrame(
        _ frame: AudioVisualiserFrame,
        _ lastFrameTimestamp: inout Date?,
        _ consecutiveFallbacks: inout Int
    ) async {
        let isNewFrame = lastFrameTimestamp != frame.timestamp
        if isNewFrame {
            await MainActor.run {
                self.currentFrame = frame
                self.fftSize = frame.fftSize
            }
            lastFrameTimestamp = frame.timestamp
            consecutiveFallbacks = 0
        }
    }
    
    private func handleNoFrame(
        justResumed: Bool,
        consecutiveFallbacks: inout Int,
        maxFallbacks: Int,
        nowPlayingViewModel: NowPlayingViewModel?
    ) async {
        consecutiveFallbacks += 1
        let shouldShowFallback = justResumed || consecutiveFallbacks >= maxFallbacks
        
        if shouldShowFallback,
           let viewModel = nowPlayingViewModel,
           viewModel.isPlaying {
            await MainActor.run {
                self.createFallbackFrame()
            }
            if justResumed {
                consecutiveFallbacks = maxFallbacks - 1
            }
        } else if let viewModel = nowPlayingViewModel,
                  !viewModel.isPlaying,
                  viewModel.currentTrack != nil {
            await MainActor.run {
                if self.currentFrame == nil {
                    self.createStaticFrame()
                }
            }
        } else {
            // No track loaded - show initial frame to indicate visualiser is ready
            await MainActor.run {
                if self.currentFrame == nil {
                    self.currentFrame = self.createInitialFrame()
                }
            }
        }
    }
    
    private func calculateUpdateInterval() -> UInt64 {
        // Base interval: ~120Hz (8.33ms) for smooth visualization
        // With CPU optimization: increase interval to reduce CPU usage
        // Default: 16.67ms (60Hz) for better CPU efficiency while maintaining smooth visuals
        let baseInterval: UInt64 = 16_666_666 // 60Hz default (reduced from 120Hz)
        let speedAdjustedInterval = UInt64(Double(baseInterval) / playbackSpeedMultiplier)
        // Clamp between 16.67ms (60Hz) and 33.33ms (30Hz) for CPU efficiency
        return max(16_666_666, min(33_333_333, speedAdjustedInterval))
    }
    
    func stopVisualization() {
        visualisationTask?.cancel()
        visualisationTask = nil
    }
    
    // This would be called by the audio engine when processing audio
    func updateFrame(_ frame: AudioVisualiserFrame) {
        currentFrame = frame
    }
    
    // Fallback visualisation when audio tap is not available
    // This creates a reactive pattern based on playback state
    // NOTE: For real audio-reactive visualisation, the audio engine needs to use AVAudioEngine
    // with installTap to provide actual audio samples to the visualiser
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
        currentFrame = AudioVisualiserFrame(
            magnitudes: magnitudes,
            timestamp: Date(),
            sampleRate: sampleRate,
            fftSize: fftSize
        )
    }
    
    // Static visualisation when paused/stopped but track is loaded
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
        currentFrame = AudioVisualiserFrame(
            magnitudes: magnitudes,
            timestamp: Date(),
            sampleRate: sampleRate,
            fftSize: fftSize
        )
    }
    
    // Create an initial frame for display when no audio data is available
    // This ensures the visualiser always shows something
    func createInitialFrame() -> AudioVisualiserFrame {
        let magnitudeCount = fftSize / 2
        var magnitudes = [Float](repeating: 0.0, count: magnitudeCount)
        
        // Create a subtle static pattern to show the visualiser is ready
        for i in 0..<magnitudeCount {
            let frequency = Float(i) / Float(magnitudeCount)
            // Create a gentle static pattern
            let staticWave = sin(Float(i) * 0.1) * (1.0 - frequency * 0.5)
            magnitudes[i] = max(0.0, staticWave * 10.0 + 3.0) // Very low amplitude for initial state
        }
        
        let sampleRate = 44100 // Default sample rate
        return AudioVisualiserFrame(
            magnitudes: magnitudes,
            timestamp: Date(),
            sampleRate: sampleRate,
            fftSize: fftSize
        )
    }
}
