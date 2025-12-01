//
//  AudioSettingsView.swift
//  Audientia
//
//  Audio/DSP settings view with tabs for EQ, ReplayGain, Gain Control, Normalization, and Visualizer
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AudioCore
import SwiftUI

/// Main audio settings view with tabs for all DSP features
/// BDD: As a user, I want to access all audio processing settings in one place
@MainActor
public struct AudioSettingsView: View {
    @State private var selectedTab: AudioSettingsTab = .equaliser
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            EQInterfaceView()
                .tabItem {
                    Label("Equaliser", systemImage: "slider.horizontal.3")
                }
                .tag(AudioSettingsTab.equaliser)
            
            ReplayGainSettingsView()
                .tabItem {
                    Label("ReplayGain", systemImage: "waveform.path")
                }
                .tag(AudioSettingsTab.replayGain)
            
            AudioGainControlView()
                .tabItem {
                    Label("Gain", systemImage: "speaker.wave.2")
                }
                .tag(AudioSettingsTab.gain)
            
            NormalisationSettingsView()
                .tabItem {
                    Label("Normalization", systemImage: "chart.bar.fill")
                }
                .tag(AudioSettingsTab.normalization)
            
            AudioVisualiserView()
                .tabItem {
                    Label("Visualizer", systemImage: "waveform")
                }
                .tag(AudioSettingsTab.visualiser)
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

private enum AudioSettingsTab: String, CaseIterable {
    case equaliser
    case replayGain
    case gain
    case normalization
    case visualiser
}
