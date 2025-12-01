//
//  AudioVisualiserView.swift
//  Audientia
//
//  Audio visualiser view displaying FFT spectrum data
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AudioCore
import SwiftUI

/// Audio visualiser view that displays real-time FFT spectrum
/// BDD: As a listener, I want to see an audio visualiser that reacts to the music
@MainActor
public struct AudioVisualiserView: View {
    @StateObject private var viewModel: AudioVisualiserViewModel
    
    public init(nowPlayingViewModel: NowPlayingViewModel? = nil, audioEngine: AudioEngine? = nil) {
        _viewModel = StateObject(wrappedValue: AudioVisualiserViewModel(nowPlayingViewModel: nowPlayingViewModel, audioEngine: audioEngine))
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Header with compact mode selector
            HStack(spacing: 8) {
                Text("Audio Visualizer")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Compact icon-based mode selector with 3D button style
                HStack(spacing: 3) {
                    ForEach(VisualisationMode.allCases) { mode in
                        VisualisationModeButton(
                            mode: mode,
                            isSelected: viewModel.visualisationMode == mode,
                            action: { viewModel.visualisationMode = mode }
                        )
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
    
    private func spectrumView(frame: AudioVisualiserFrame) -> some View {
        GeometryReader { geometry in
            switch viewModel.visualisationMode {
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

// MARK: - Visualization Mode Button

private struct VisualisationModeButton: View {
    let mode: VisualisationMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            modeIcon
                .foregroundColor(isSelected ? .white : .secondary)
                .frame(width: 24, height: 24)
                .background(buttonBackground)
                .cornerRadius(4)
                .overlay(buttonBorder)
                .shadow(
                    color: isSelected ? Color.black.opacity(0.4) : Color.black.opacity(0.3),
                    radius: isSelected ? 1 : 2,
                    x: 0,
                    y: isSelected ? 1 : -1
                )
        }
        .buttonStyle(.plain)
        .help(mode.displayName)
    }
    
    private var modeIcon: some View {
        Group {
            if NSImage(named: mode.iconImageName) != nil {
                Image(mode.iconImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: mode.iconSystemName)
                    .font(.system(size: 11))
            }
        }
    }
    
    @ViewBuilder
    private var buttonBackground: some View {
        if isSelected {
            selectedButtonBackground
        } else {
            unselectedButtonBackground
        }
    }
    
    private var selectedButtonBackground: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.accentColor.opacity(0.9),
                    Color.accentColor.opacity(0.7)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            VStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.3),
                                Color.clear
                            ]),
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(height: 2)
                Spacer()
            }
        }
    }
    
    private var unselectedButtonBackground: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(white: 0.25),
                    Color(white: 0.15)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            VStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.2),
                                Color.clear
                            ]),
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(height: 2)
                Spacer()
            }
        }
    }
    
    private var buttonBorder: some View {
        RoundedRectangle(cornerRadius: 4)
            .stroke(
                isSelected ? Color.white.opacity(0.3) : Color.black.opacity(0.4),
                lineWidth: 0.5
            )
    }
}

// MARK: - Controls View Extension
private extension AudioVisualiserView {
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
                            value: $viewModel.visualisationVolume,
                            in: 0.0...1.0
                        )
                        .frame(width: 150)
                        
                        Text("\(Int(viewModel.visualisationVolume * 100))%")
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
