//
//  NormalizationSettingsView.swift
//  Audientia
//
//  Audio normalization settings (peak/RMS/loudness)
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AudioCore
import SwiftUI

/// Normalization settings view
/// BDD: As a user, I want to normalize audio levels across my library
@MainActor
public struct NormalizationSettingsView: View {
    @StateObject private var viewModel = NormalizationSettingsViewModel()
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            Text("Audio Normalization")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Normalization Mode
            VStack(alignment: .leading, spacing: 8) {
                Text("Normalization Mode")
                    .font(.headline)
                
                Picker("Mode", selection: $viewModel.mode) {
                    Text("Peak").tag(NormalizationMode.peak)
                    Text("RMS").tag(NormalizationMode.rms)
                    Text("Loudness").tag(NormalizationMode.loudness)
                }
                .pickerStyle(.segmented)
                .onChange(of: viewModel.mode) { _, newValue in
                    viewModel.setMode(newValue)
                }
            }
            
            // Target Level
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Target Level")
                        .font(.headline)
                    Spacer()
                    Text(String(format: "%.1f dB", viewModel.targetLevel))
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Slider(
                    value: $viewModel.targetLevel,
                    in: -30.0...0.0,
                    step: 0.5
                ) {
                    Text("Target Level")
                } minimumValueLabel: {
                    Text("-30")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } maximumValueLabel: {
                    Text("0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Information
            VStack(alignment: .leading, spacing: 8) {
                Text("About Normalization")
                    .font(.headline)
                
                Text("Normalization adjusts audio levels to a consistent target:")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Text("• Peak: Normalizes to maximum peak amplitude")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("• RMS: Normalizes to average RMS level")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("• Loudness: Normalizes to perceived loudness (EBU R128)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// ViewModel for Normalization Settings
@MainActor
private final class NormalizationSettingsViewModel: ObservableObject {
    @Published var mode: NormalizationMode = .peak
    @Published var targetLevel: Float = -3.0
    
    private let normalizer = AudioNormalizer()
    
    func setMode(_ mode: NormalizationMode) {
        self.mode = mode
        // Apply normalization mode
        // This would integrate with the audio engine
    }
}
