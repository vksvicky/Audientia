//
//  EQInterfaceView.swift
//  Audientia
//
//  10-band parametric equalizer interface with presets
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AudioCore
import SwiftUI

/// Equalizer interface view with 10-band parametric EQ and presets
/// BDD: As a user, I want to adjust bass and treble using an equalizer
@MainActor
public struct EQInterfaceView: View {
    @StateObject private var viewModel = EQInterfaceViewModel()
    @State private var selectedPreset: EQPreset?
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            // Header
            headerView
            
            // Enable/Disable Toggle
            enableToggleView
            
            // EQ Bands
            eqBandsView
            
            // Presets
            presetsView
            
            // Reset Button
            resetButtonView
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Text("10-Band Parametric Equalizer")
                .font(.title2)
                .fontWeight(.semibold)
            Spacer()
        }
    }
    
    // MARK: - Enable Toggle View
    
    private var enableToggleView: some View {
        Toggle("Enable Equalizer", isOn: $viewModel.isEnabled)
            .onChange(of: viewModel.isEnabled) { _, newValue in
                Task {
                    await viewModel.setEnabled(newValue)
                }
            }
    }
    
    // MARK: - EQ Bands View
    
    private var eqBandsView: some View {
        VStack(spacing: 12) {
            // Frequency labels
            HStack(spacing: 0) {
                ForEach(viewModel.bands, id: \.frequency) { band in
                    Text(formatFrequency(band.frequency))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Gain sliders
            HStack(spacing: 8) {
                ForEach(Array(viewModel.bands.enumerated()), id: \.element.frequency) { index, band in
                    VStack(spacing: 4) {
                        // Gain value display
                        Text(String(format: "%.1f", band.gain))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(height: 20)
                        
                        // Vertical slider
                        GeometryReader { geometry in
                            VStack {
                                Spacer()
                                Slider(
                                    value: Binding(
                                        get: { band.gain },
                                        set: { newValue in
                                            Task {
                                                try? await viewModel.setBandGain(index, gain: newValue)
                                            }
                                        }
                                    ),
                                    in: -20.0...20.0
                                )
                                .rotationEffect(.degrees(-90))
                                .frame(width: geometry.size.height, height: geometry.size.width)
                                .offset(x: (geometry.size.width - geometry.size.height) / 2)
                            }
                        }
                        .frame(height: 200)
                        
                        // Frequency label at bottom
                        Text(formatFrequency(band.frequency))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(height: 20)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    // MARK: - Presets View
    
    private var presetsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Presets")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(EQPreset.allCases, id: \.self) { preset in
                        Button {
                            selectedPreset = preset
                            Task {
                                await viewModel.applyPreset(preset)
                            }
                        } label: {
                            Text(preset.displayName)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    selectedPreset == preset
                                        ? Color.accentColor
                                        : Color.secondary.opacity(0.2)
                                )
                                .foregroundColor(
                                    selectedPreset == preset
                                        ? .white
                                        : .primary
                                )
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Reset Button View
    
    private var resetButtonView: some View {
        Button("Reset to Flat") {
            Task {
                await viewModel.reset()
                selectedPreset = nil
            }
        }
        .buttonStyle(.bordered)
    }
    
    // MARK: - Helpers
    
    private func formatFrequency(_ frequency: Float) -> String {
        if frequency >= 1000 {
            return String(format: "%.1fk", frequency / 1000.0)
        } else {
            return String(format: "%.0f", frequency)
        }
    }
}

/// EQ Presets
private enum EQPreset: String, CaseIterable {
    case flat
    case bassBoost
    case trebleBoost
    case vocal
    case rock
    case jazz
    case classical
    case electronic
    
    var displayName: String {
        rawValue.capitalized.replacingOccurrences(of: "_", with: " ")
    }
}

/// ViewModel for EQ Interface
@MainActor
private final class EQInterfaceViewModel: ObservableObject {
    @Published var bands: [EqualizerBand] = []
    @Published var isEnabled: Bool = true
    
    private let equalizer = AudioEqualizer()
    
    init() {
        Task {
            await loadBands()
            await loadEnabledState()
        }
    }
    
    private func loadBands() async {
        bands = await equalizer.getBands()
    }
    
    private func loadEnabledState() async {
        isEnabled = await equalizer.isEnabled()
    }
    
    func setBandGain(_ bandIndex: Int, gain: Float) async throws {
        try await equalizer.setBandGain(bandIndex, gain: gain)
        await loadBands()
    }
    
    func setEnabled(_ enabled: Bool) async {
        await equalizer.setEnabled(enabled)
        await loadEnabledState()
    }
    
    func reset() async {
        await equalizer.reset()
        await loadBands()
    }
    
    func applyPreset(_ preset: EQPreset) async {
        let presetGains = getPresetGains(preset)
        for (index, gain) in presetGains.enumerated() {
            try? await equalizer.setBandGain(index, gain: gain)
        }
        await loadBands()
    }
    
    private func getPresetGains(_ preset: EQPreset) -> [Float] {
        switch preset {
        case .flat:
            return Array(repeating: 0.0, count: 10)
        case .bassBoost:
            return [6.0, 4.0, 2.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        case .trebleBoost:
            return [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 4.0, 6.0, 4.0]
        case .vocal:
            return [-2.0, -1.0, 0.0, 3.0, 4.0, 4.0, 3.0, 1.0, -1.0, -2.0]
        case .rock:
            return [4.0, 2.0, -1.0, -2.0, -1.0, 1.0, 3.0, 4.0, 3.0, 2.0]
        case .jazz:
            return [2.0, 1.0, 0.0, 1.0, 2.0, 2.0, 1.0, 0.0, 1.0, 2.0]
        case .classical:
            return [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -1.0, -2.0, -2.0, -1.0]
        case .electronic:
            return [4.0, 3.0, 1.0, 0.0, -1.0, 0.0, 1.0, 2.0, 3.0, 4.0]
        }
    }
}
