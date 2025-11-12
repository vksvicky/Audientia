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
    @StateObject private var viewModel = AudioVisualizerViewModel()
    
    public init() {}
    
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
            let barWidth = geometry.size.width / CGFloat(frame.magnitudes.count)
            
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(Array(frame.magnitudes.enumerated()), id: \.offset) { _, magnitude in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.8),
                                    Color.purple.opacity(0.6),
                                    Color.pink.opacity(0.4)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(
                            width: max(1, barWidth - 1),
                            height: CGFloat(magnitude) * geometry.size.height / 100.0
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: 200)
        .background(Color.black.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Controls View
    
    private var controlsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // FFT Size
            VStack(alignment: .leading, spacing: 4) {
                Text("FFT Size: \(viewModel.fftSize)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Dominant Frequency
            if let frame = viewModel.currentFrame,
               let dominantBin = frame.dominantBin {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dominant Frequency: \(String(format: "%.1f", frame.dominantFrequency)) Hz")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Bin: \(dominantBin)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
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
    
    private let visualizer = AudioVisualizer()
    private var visualizationTask: Task<Void, Never>?
    
    func startVisualization() async {
        visualizationTask = Task {
            // In a real implementation, this would receive audio data from the audio engine
            // For now, this is a placeholder that would need integration
            while !Task.isCancelled {
                // Wait for audio frames from the engine
                // This would be connected to the audio engine's visualizer feed
                try? await Task.sleep(nanoseconds: 33_333_333) // ~30 FPS
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
}
