//
//  AudioVisualizerView.swift
//  Audientia
//
//  Audio visualizer view displaying FFT spectrum data
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AudioCore
import SwiftUI

/// Audio visualizer view that displays real-time FFT spectrum
/// BDD: As a listener, I want to see an audio visualizer that reacts to the music
@MainActor
public struct AudioVisualizerView: View {
    @StateObject private var viewModel: AudioVisualizerViewModel
    
    public init(nowPlayingViewModel: NowPlayingViewModel? = nil, audioEngine: AudioEngine? = nil) {
        _viewModel = StateObject(wrappedValue: AudioVisualizerViewModel(nowPlayingViewModel: nowPlayingViewModel, audioEngine: audioEngine))
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Audio Visualizer")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Visualizer Display
            if let currentFrame = viewModel.currentFrame {
                spectrumView(frame: currentFrame)
            } else {
                Text("No audio data available")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Controls
            controlsView
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await viewModel.startVisualization()
        }
        .onDisappear {
            viewModel.stopVisualization()
        }
    }
    
    // MARK: - Spectrum View
    
    private func spectrumView(frame: AudioVisualizerFrame) -> some View {
        GeometryReader { geometry in
            spectrumBarsView(frame: frame, geometry: geometry)
        }
        .frame(height: 300)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color("AccentColor").opacity(0.3),
                            Color("AccentColor").opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
    
    private func spectrumBarsView(frame: AudioVisualizerFrame, geometry: GeometryProxy) -> some View {
        let barWidth = geometry.size.width / CGFloat(frame.magnitudes.count)
        
        // Use logarithmic normalization similar to audioMotion-analyzer
        let normalizer = SpectrumNormalizer(
            logScale: 2.0,
            minFreq: 20.0,
            maxFreq: 20000.0,
            sampleRate: frame.sampleRate,
            fftSize: frame.fftSize
        )
        let normalizedMagnitudes = normalizer.normalize(frame.magnitudes)
        let compressedMagnitudes = normalizer.compress(normalizedMagnitudes, sensitivity: 1.2)
        
        // Apply amplification factor for better visibility (2.5x as requested)
        let amplificationFactor: Float = 2.5
        let amplifiedMagnitudes = compressedMagnitudes.map { $0 * amplificationFactor }
        
        // Dynamic range scaling for better visualization
        let maxMagnitude = amplifiedMagnitudes.max() ?? 1.0
        let minMagnitude = amplifiedMagnitudes.min() ?? 0.0
        let range = max(maxMagnitude - minMagnitude, 1.0)
        
        return ZStack {
            // Background gradient for depth
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.4),
                    Color.black.opacity(0.1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Main spectrum bars with logarithmic scaling
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(Array(amplifiedMagnitudes.enumerated()), id: \.offset) { index, magnitude in
                    // Normalize to 0-1 range
                    let normalizedMagnitude = CGFloat((magnitude - minMagnitude) / range)
                    let barHeight = normalizedMagnitude * geometry.size.height
                    let frequencyRatio = CGFloat(index) / CGFloat(amplifiedMagnitudes.count)
                    let energy = min(normalizedMagnitude, 1.0)
                    let color = colorForFrequency(ratio: frequencyRatio, energy: energy)
                    
                    spectrumBar(
                        barWidth: barWidth,
                        barHeight: max(1, barHeight), // Minimum 1pt for visibility
                        color: color
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }
    
    private func spectrumBar(barWidth: CGFloat, barHeight: CGFloat, color: Color) -> some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Main bar with gradient
            RoundedRectangle(cornerRadius: max(1, barWidth * 0.3))
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            color.opacity(0.9),
                            color.opacity(0.6),
                            color.opacity(0.3)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(
                    width: max(1, barWidth - 1),
                    height: max(2, barHeight)
                )
                .shadow(color: color.opacity(0.5), radius: 2, x: 0, y: -1)
        }
    }
    
    // Dynamic color based on frequency band and energy
    // Enhanced color mapping similar to audioMotion-analyzer with better visual response
    private func colorForFrequency(ratio: CGFloat, energy: CGFloat) -> Color {
        // Use gamma correction for better visual energy response
        let enhancedEnergy = pow(energy, 0.7)
        
        // Low frequencies (bass) - deep blue to cyan
        if ratio < 0.25 {
            return Color(
                red: 0.1 + enhancedEnergy * 0.4,
                green: 0.3 + enhancedEnergy * 0.5,
                blue: 0.9 + enhancedEnergy * 0.1
            )
        }
        // Lower mid frequencies - cyan to green
        else if ratio < 0.4 {
            return Color(
                red: 0.2 + enhancedEnergy * 0.3,
                green: 0.7 + enhancedEnergy * 0.3,
                blue: 0.8 + enhancedEnergy * 0.2
            )
        }
        // Mid frequencies - green to yellow
        else if ratio < 0.55 {
            return Color(
                red: 0.5 + enhancedEnergy * 0.4,
                green: 0.8 + enhancedEnergy * 0.2,
                blue: 0.3 + enhancedEnergy * 0.2
            )
        }
        // Upper mid frequencies - yellow to orange
        else if ratio < 0.7 {
            return Color(
                red: 0.9 + enhancedEnergy * 0.1,
                green: 0.6 + enhancedEnergy * 0.3,
                blue: 0.2 + enhancedEnergy * 0.2
            )
        }
        // High frequencies - orange to red/pink
        else {
            return Color(
                red: 1.0,
                green: 0.3 + enhancedEnergy * 0.4,
                blue: 0.4 + enhancedEnergy * 0.3
            )
        }
    }
    
    // MARK: - Controls View
    
    private var controlsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    // FFT Size - Always visible
                    Text("FFT Size: \(viewModel.fftSize.formatted())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Dominant Frequency and Bin - Only shown when frame is available
                    if let frame = viewModel.currentFrame,
                       let dominantBin = frame.dominantBin {
                        Text("Dominant Frequency: \(String(format: "%.1f", frame.dominantFrequency)) Hz")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Bin: \(dominantBin)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Visualization Volume Control
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Visualization Volume")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 8) {
                        Slider(
                            value: $viewModel.visualizationVolume,
                            in: 0.0...1.0
                        )
                        .frame(width: 150)
                        
                        Text("\(Int(viewModel.visualizationVolume * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 35, alignment: .trailing)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// ViewModel for Audio Visualizer
@MainActor
private final class AudioVisualizerViewModel: ObservableObject {
    @Published var currentFrame: AudioVisualizerFrame?
    @Published var fftSize: Int = 1024
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
            let maxFallbacks = 10 // Only use fallback if no real frames for 10 iterations (about 83ms)
            
            while !Task.isCancelled {
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
                    
                    // Only use fallback if we haven't received real frames for a while
                    // This ensures we prioritize real audio data from AudioVisualizerTap
                    if consecutiveFallbacks >= maxFallbacks,
                       let nowPlayingViewModel = nowPlayingViewModel,
                       nowPlayingViewModel.isPlaying {
                        // Fallback only if playing and no real frames available after waiting
                        await MainActor.run {
                            self.createFallbackFrame()
                        }
                    } else if let nowPlayingViewModel = nowPlayingViewModel,
                              !nowPlayingViewModel.isPlaying,
                              nowPlayingViewModel.currentTrack != nil {
                        // Paused/stopped - keep last frame or show static
                        await MainActor.run {
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
