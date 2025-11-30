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
            
            // Visualizer Display - Expand to fill available space
            if let currentFrame = viewModel.currentFrame {
                spectrumView(frame: currentFrame)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("No audio data available")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Controls - Fixed size at bottom
            controlsView
                .frame(maxWidth: .infinity)
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
            case .discreteFrequencies:
                discreteFrequenciesView(frame: frame, geometry: geometry)
            case .radialSpectrum:
                radialSpectrumView(frame: frame, geometry: geometry)
            case .dualChannelGraph:
                dualChannelGraphView(frame: frame, geometry: geometry)
            case .ledBars:
                ledBarsView(frame: frame, geometry: geometry)
            case .lumiBars:
                lumiBarsView(frame: frame, geometry: geometry)
            case .roundBarsReflex:
                roundBarsReflexView(frame: frame, geometry: geometry)
            }
        }
        .frame(minHeight: 200, maxHeight: .infinity) // Responsive: minimum 200pt, expand to fill space
        .drawingGroup() // Render to single layer for crisp rendering
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
