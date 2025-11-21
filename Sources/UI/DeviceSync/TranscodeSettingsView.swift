//
//  TranscodeSettingsView.swift
//  UI
//
//  Transcoding settings view for device sync
//

import DataLayer
import Foundation
import Shared
import SwiftUI

public struct TranscodeSettingsView: View {
    
    @StateObject private var viewModel: TranscodeSettingsViewModel
    @Binding var isPresented: Bool
    
    public init(
        isPresented: Binding<Bool>,
        viewModel: TranscodeSettingsViewModel
    ) {
        _isPresented = isPresented
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                transcodingToggleSection
                if viewModel.transcodeEnabled {
                    profileSelectionSection
                    qualityPresetsSection
                    customProfileSection
                }
            }
            .navigationTitle("Transcoding Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveSettings()
                        isPresented = false
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
        .task {
            await viewModel.loadProfiles()
        }
    }
    
    private var transcodingToggleSection: some View {
        Section {
            Toggle("Enable Transcoding", isOn: $viewModel.transcodeEnabled)
            
            if viewModel.transcodeEnabled {
                Text(
                    "Files will be transcoded to the selected format " +
                    "and quality during sync"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        } header: {
            Text("Transcoding")
        }
    }
    
    private var profileSelectionSection: some View {
        Section {
            Picker("Output Format", selection: $viewModel.selectedFormat) {
                Text("MP3").tag(AudioFormat.mp3)
                Text("AAC").tag(AudioFormat.aac)
                Text("FLAC").tag(AudioFormat.flac)
            }
            
            Picker("Quality Preset", selection: $viewModel.selectedQuality) {
                Text("Low (128 kbps)").tag(TranscodeQuality.low)
                Text("Standard (192 kbps)").tag(TranscodeQuality.standard)
                Text("High (256 kbps)").tag(TranscodeQuality.high)
                Text("Very High (320 kbps)").tag(TranscodeQuality.veryHigh)
                if viewModel.selectedFormat == .flac {
                    Text("Lossless").tag(TranscodeQuality.lossless)
                }
            }
            
            if viewModel.selectedQuality != .lossless {
                HStack {
                    Text("Bitrate")
                    Spacer()
                    Text("\(viewModel.currentBitrate) kbps")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Output Settings")
        }
    }
    
    private var qualityPresetsSection: some View {
        Section {
            ForEach(viewModel.availablePresets, id: \.id) { profile in
                Button {
                    viewModel.selectProfile(profile)
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(profile.name)
                                .foregroundStyle(.primary)
                            Text(
                                "\(profile.format.rawValue.uppercased()) • " +
                                "\(profile.bitrate > 0 ? "\(profile.bitrate) kbps" : "Lossless")"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if viewModel.isProfileSelected(profile) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Quality Presets")
        }
    }
    
    private var customProfileSection: some View {
        Section {
            Button("Create Custom Profile") {
                viewModel.showCustomProfileEditor = true
            }
            
            if !viewModel.customProfiles.isEmpty {
                ForEach(viewModel.customProfiles, id: \.id) { profile in
                    Button {
                        viewModel.selectProfile(profile)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(profile.name)
                                    .foregroundStyle(.primary)
                                Text("\(profile.format.rawValue.uppercased()) • \(profile.bitrate) kbps")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if viewModel.isProfileSelected(profile) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                            Button {
                                viewModel.deleteCustomProfile(profile.id)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        } header: {
            Text("Custom Profiles")
        }
    }
}

// MARK: - ViewModel

@MainActor
public class TranscodeSettingsViewModel: ObservableObject {
    
    @Published var transcodeEnabled: Bool = false
    @Published var selectedFormat: AudioFormat = .mp3
    @Published var selectedQuality: TranscodeQuality = .standard
    @Published var availablePresets: [TranscodeProfile] = []
    @Published var customProfiles: [TranscodeProfile] = []
    @Published var selectedProfile: TranscodeProfile?
    @Published var showCustomProfileEditor: Bool = false
    @Published var errorMessage: String?
    
    private let profileManager: TranscodeProfileManager
    
    public init(profileManager: TranscodeProfileManager = TranscodeProfileManager()) {
        self.profileManager = profileManager
    }
    
    var currentBitrate: Int {
        selectedQuality.defaultBitrate
    }
    
    func loadProfiles() async {
        let presets = await profileManager.getPresetProfiles()
        let custom = await profileManager.getCustomProfiles()
        
        await MainActor.run {
            availablePresets = presets
            customProfiles = custom
            
            // Set default profile
            if selectedProfile == nil {
                selectedProfile = presets.first { $0.format == selectedFormat && $0.quality == selectedQuality }
            }
        }
    }
    
    func selectProfile(_ profile: TranscodeProfile) {
        selectedProfile = profile
        selectedFormat = profile.format
        selectedQuality = profile.quality
    }
    
    func isProfileSelected(_ profile: TranscodeProfile) -> Bool {
        selectedProfile?.id == profile.id
    }
    
    func deleteCustomProfile(_ id: UUID) {
        Task {
            await profileManager.deleteCustomProfile(id: id)
            await loadProfiles()
        }
    }
    
    func saveSettings() {
        // Save to device configuration or app settings
        // This will be integrated with DeviceConfigurationStorage
    }
}
