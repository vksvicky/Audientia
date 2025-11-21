//
//  DeviceConfigurationWizardView.swift
//  UI
//
//  Device configuration wizard for advanced sync rules
//

import DataLayer
import Foundation
import Shared
import SwiftUI

public struct DeviceConfigurationWizardView: View {
    
    @Binding var isPresented: Bool
    @StateObject private var viewModel: DeviceConfigurationViewModel
    let device: Device
    
    public init(
        isPresented: Binding<Bool>,
        device: Device,
        viewModel: DeviceConfigurationViewModel
    ) {
        _isPresented = isPresented
        self.device = device
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                deviceInfoSection
                syncOptionsSection
                advancedOptionsSection
            }
            .navigationTitle("Configure \(device.name)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveConfiguration()
                        isPresented = false
                    }
                    .disabled(!viewModel.isValid)
                }
            }
        }
        .frame(width: 600, height: 500)
    }
    
    private var deviceInfoSection: some View {
        Section("Device Information") {
            HStack {
                Text("Name")
                Spacer()
                Text(device.name)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Type")
                Spacer()
                Text(device.type.rawValue.uppercased())
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Capacity")
                Spacer()
                Text(formatBytes(device.capacity))
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Available Space")
                Spacer()
                Text(formatBytes(device.availableSpace))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var syncOptionsSection: some View {
        Section("Sync Options") {
            Toggle("Enforce Free Space Check", isOn: $viewModel.enforceFreeSpace)
            Toggle("Auto-Resolve Conflicts", isOn: $viewModel.autoResolveConflicts)
            
            Picker("Conflict Resolution Strategy", selection: $viewModel.conflictStrategy) {
                Text("Keep Library Version").tag(ConflictResolutionStrategy.keepLibrary)
                Text("Keep Device Version").tag(ConflictResolutionStrategy.keepDevice)
                Text("Keep Newer").tag(ConflictResolutionStrategy.keepNewer)
                Text("Keep Larger").tag(ConflictResolutionStrategy.keepLarger)
            }
            .disabled(viewModel.autoResolveConflicts == false)
            
            Picker("Sync Direction", selection: $viewModel.syncDirection) {
                Text("Desktop → Device").tag(SyncDirection.desktopToDevice)
                Text("Device → Desktop").tag(SyncDirection.deviceToDesktop)
                Text("Bidirectional").tag(SyncDirection.bidirectional)
            }
        }
    }
    
    private var advancedOptionsSection: some View {
        Section("Advanced Options") {
            Toggle("Create Folder Structure", isOn: $viewModel.createFolderStructure)
            
            if viewModel.createFolderStructure {
                Picker("Folder Structure", selection: $viewModel.folderStructure) {
                    Text("Artist/Album").tag(FolderStructure.artistAlbum)
                    Text("Album/Artist").tag(FolderStructure.albumArtist)
                    Text("Genre/Artist/Album").tag(FolderStructure.genreArtistAlbum)
                    Text("Flat (All in Root)").tag(FolderStructure.flat)
                }
            }
            
            Toggle("Transcode if Needed", isOn: $viewModel.transcodeIfNeeded)
            
            if viewModel.transcodeIfNeeded {
                Picker("Target Format", selection: $viewModel.targetFormat) {
                    Text("MP3").tag(AudioFormat.mp3)
                    Text("AAC").tag(AudioFormat.aac)
                    Text("FLAC").tag(AudioFormat.flac)
                    Text("Original").tag(AudioFormat.original)
                }
                
                Stepper(
                    "Bitrate: \(viewModel.targetBitrate) kbps",
                    value: $viewModel.targetBitrate,
                    in: 128...320,
                    step: 32
                )
            }
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - ViewModel

@MainActor
public class DeviceConfigurationViewModel: ObservableObject {
    
    @Published var enforceFreeSpace: Bool = true
    @Published var autoResolveConflicts: Bool = false
    @Published var conflictStrategy: ConflictResolutionStrategy = .keepLibrary
    @Published var syncDirection: SyncDirection = .desktopToDevice
    @Published var createFolderStructure: Bool = true
    @Published var folderStructure: FolderStructure = .artistAlbum
    @Published var transcodeIfNeeded: Bool = false
    @Published var targetFormat: AudioFormat = .mp3
    @Published var targetBitrate: Int = 192
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let storage: DeviceConfigurationStorageProtocol
    private let deviceId: UUID
    
    public init(
        deviceId: UUID,
        storage: DeviceConfigurationStorageProtocol = UserDefaultsDeviceConfigurationStorage()
    ) {
        self.deviceId = deviceId
        self.storage = storage
        Task {
            await loadConfiguration()
        }
    }
    
    var isValid: Bool {
        true // Add validation logic if needed
    }
    
    func saveConfiguration() {
        Task {
            await saveConfigurationAsync()
        }
    }
    
    private func saveConfigurationAsync() async {
        let config = DeviceConfiguration(
            enforceFreeSpace: enforceFreeSpace,
            autoResolveConflicts: autoResolveConflicts,
            conflictStrategy: conflictStrategy,
            syncDirection: syncDirection,
            createFolderStructure: createFolderStructure,
            folderStructure: folderStructure,
            transcodeIfNeeded: transcodeIfNeeded,
            targetFormat: targetFormat,
            targetBitrate: targetBitrate
        )
        
        do {
            try await storage.saveConfiguration(config, for: deviceId)
            await MainActor.run {
                successMessage = "Configuration saved successfully"
                errorMessage = nil
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to save configuration: \(error.localizedDescription)"
                successMessage = nil
            }
        }
    }
    
    private func loadConfiguration() async {
        guard let config = await storage.loadConfiguration(for: deviceId) else {
            return // Use defaults if no saved configuration
        }
        
        await MainActor.run {
            enforceFreeSpace = config.enforceFreeSpace
            autoResolveConflicts = config.autoResolveConflicts
            conflictStrategy = config.conflictStrategy
            syncDirection = config.syncDirection
            createFolderStructure = config.createFolderStructure
            folderStructure = config.folderStructure
            transcodeIfNeeded = config.transcodeIfNeeded
            targetFormat = config.targetFormat
            targetBitrate = config.targetBitrate
        }
    }
    
    /// Get the current configuration as a DeviceConfiguration
    public func currentConfiguration() -> DeviceConfiguration {
        DeviceConfiguration(
            enforceFreeSpace: enforceFreeSpace,
            autoResolveConflicts: autoResolveConflicts,
            conflictStrategy: conflictStrategy,
            syncDirection: syncDirection,
            createFolderStructure: createFolderStructure,
            folderStructure: folderStructure,
            transcodeIfNeeded: transcodeIfNeeded,
            targetFormat: targetFormat,
            targetBitrate: targetBitrate
        )
    }
}

// Types are defined in Shared/Models/DeviceSyncModels.swift
