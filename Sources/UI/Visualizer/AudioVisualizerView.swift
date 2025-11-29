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
            // Header with compact mode selector
            HStack(spacing: 8) {
                Text("Audio Visualizer")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Compact icon-based mode selector
                HStack(spacing: 2) {
                    ForEach(VisualizationMode.allCases) { mode in
                        Button {
                            viewModel.visualizationMode = mode
                        } label: {
                            Image(systemName: mode.icon)
                                .font(.system(size: 11))
                                .foregroundColor(viewModel.visualizationMode == mode ? .white : .secondary)
                                .frame(width: 22, height: 22)
                                .background(
                                    viewModel.visualizationMode == mode ?
                                    Color.accentColor.opacity(0.8) :
                                    Color.clear
                                )
                                .cornerRadius(3)
                        }
                        .buttonStyle(.plain)
                        .help(mode.displayName)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.15))
                .cornerRadius(4)
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
            switch viewModel.visualizationMode {
            case .bars:
                spectrumBarsView(frame: frame, geometry: geometry)
            case .line:
                spectrumLineView(frame: frame, geometry: geometry)
            case .mirror:
                spectrumMirrorView(frame: frame, geometry: geometry)
            case .radial:
                spectrumRadialView(frame: frame, geometry: geometry)
            case .luminance:
                spectrumLuminanceView(frame: frame, geometry: geometry)
            case .led:
                spectrumLEDView(frame: frame, geometry: geometry)
            case .waveform:
                spectrumWaveformView(frame: frame, geometry: geometry)
            case .circle:
                spectrumCircleView(frame: frame, geometry: geometry)
            }
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
    
    func spectrumBar(barWidth: CGFloat, barHeight: CGFloat, color: Color) -> some View {
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
    
}

// MARK: - Controls View Extension
private extension AudioVisualizerView {
    var controlsView: some View {
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
