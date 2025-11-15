//
//  AudioGainControlView.swift
//  Audientia
//
//  Audio gain control interface (per-track and global)
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AudioCore
import Shared
import SwiftUI

/// Audio gain control view for per-track and global gain adjustment
/// BDD: As a user, I want to adjust gain for a specific track
@MainActor
public struct AudioGainControlView: View {
    @StateObject private var viewModel = AudioGainControlViewModel()
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            Text("Audio Gain Control")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Global Gain
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Global Gain")
                        .font(.headline)
                    Spacer()
                    Text(String(format: "%.1f dB", viewModel.globalGain))
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Slider(
                    value: $viewModel.globalGain,
                    in: -20.0...20.0,
                    step: 0.5
                ) {
                    Text("Global Gain")
                } minimumValueLabel: {
                    Text("-20")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } maximumValueLabel: {
                    Text("+20")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .onChange(of: viewModel.globalGain) { _, newValue in
                    Task {
                        await viewModel.setGlobalGain(newValue)
                    }
                }
            }
            
            Divider()
            
            // Current Track Gain
            if viewModel.currentTrack != nil {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Current Track Gain")
                            .font(.headline)
                        Spacer()
                        Text(String(format: "%.1f dB", viewModel.trackGain ?? 0.0))
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { viewModel.trackGain ?? 0.0 },
                            set: { newValue in
                                viewModel.trackGain = newValue
                                Task {
                                    if let track = viewModel.currentTrack {
                                        await viewModel.setTrackGain(newValue, for: track)
                                    }
                                }
                            }
                        ),
                        in: -20.0...20.0,
                        step: 0.5
                    ) {
                        Text("Track Gain")
                    } minimumValueLabel: {
                        Text("-20")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } maximumValueLabel: {
                        Text("+20")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Effective Gain Display
                    HStack {
                        Text("Effective Gain:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f dB", viewModel.effectiveGain))
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    // Remove Track Gain Button
                    if viewModel.trackGain != nil {
                        Button("Remove Track Gain") {
                            Task {
                                if let track = viewModel.currentTrack {
                                    await viewModel.removeTrackGain(for: track)
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            } else {
                Text("No track loaded")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Information
            VStack(alignment: .leading, spacing: 8) {
                Text("About Gain Control")
                    .font(.headline)
                
                Text("Global gain applies to all tracks. Track gain applies only to the current track. " +
                     "Effective gain is the sum of both.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task {
            await viewModel.loadGainSettings()
        }
    }
}

/// ViewModel for Audio Gain Control
@MainActor
private final class AudioGainControlViewModel: ObservableObject {
    @Published var globalGain: Float = 0.0
    @Published var trackGain: Float?
    @Published var currentTrack: Shared.Track?
    
    private let gainControl = AudioGainControl()
    
    var effectiveGain: Float {
        globalGain + (trackGain ?? 0.0)
    }
    
    func loadGainSettings() async {
        globalGain = await gainControl.getGlobalGain()
        // Track gain would be loaded when a track is playing
        // This would need integration with the audio engine
    }
    
    func setGlobalGain(_ gain: Float) async {
        await gainControl.setGlobalGain(gain)
        globalGain = await gainControl.getGlobalGain()
    }
    
    func setTrackGain(_ gain: Float, for track: Shared.Track) async {
        await gainControl.setTrackGain(gain, for: track)
        trackGain = await gainControl.getTrackGain(for: track)
    }
    
    func removeTrackGain(for track: Shared.Track) async {
        await gainControl.removeTrackGain(for: track)
        trackGain = await gainControl.getTrackGain(for: track)
    }
}
