//
//  ReplayGainSettingsView.swift
//  Audientia
//
//  ReplayGain settings and controls
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AudioCore
import SwiftUI

/// ReplayGain settings view
/// BDD: As a user, I want my music library to play at consistent volume levels
@MainActor
public struct ReplayGainSettingsView: View {
    @StateObject private var viewModel = ReplayGainSettingsViewModel()
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            Text("ReplayGain Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Enable ReplayGain
            Toggle("Enable ReplayGain", isOn: $viewModel.isEnabled)
                .onChange(of: viewModel.isEnabled) { _, newValue in
                    Task {
                        await viewModel.setEnabled(newValue)
                    }
                }
            
            // ReplayGain Mode
            Picker("ReplayGain Mode", selection: $viewModel.mode) {
                Text("Track Gain").tag(ReplayGainMode.track)
                Text("Album Gain").tag(ReplayGainMode.album)
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.mode) { _, newValue in
                Task {
                    await viewModel.setMode(newValue)
                }
            }
            
            Divider()
            
            // Information
            VStack(alignment: .leading, spacing: 8) {
                Text("About ReplayGain")
                    .font(.headline)
                
                Text("ReplayGain analyzes audio files to determine optimal playback volume, " +
                     "ensuring consistent loudness across your library.")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Text("• Track Gain: Uses per-track analysis for maximum consistency")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("• Album Gain: Uses album-level analysis to preserve dynamics")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task {
            await viewModel.loadSettings()
        }
    }
}

/// ViewModel for ReplayGain Settings
@MainActor
private final class ReplayGainSettingsViewModel: ObservableObject {
    @Published var isEnabled: Bool = false
    @Published var mode: ReplayGainMode = .track
    
    private let replayGain = ReplayGain()
    
    func loadSettings() async {
        // Load current settings (would need to be stored in UserDefaults or similar)
        // For now, use defaults
        isEnabled = false
        mode = .track
    }
    
    func setEnabled(_ enabled: Bool) async {
        isEnabled = enabled
        // Apply ReplayGain settings to audio engine
        // This would integrate with the audio engine
    }
    
    func setMode(_ mode: ReplayGainMode) async {
        self.mode = mode
        // Apply mode to ReplayGain processor
    }
}
