//
//  DeviceSyncView.swift
//  UI
//
//  SwiftUI surface for Device Sync (Feature 4.1)
//

import DataLayer
import Shared
import SwiftUI

public struct DeviceSyncView: View {
    
    @StateObject private var viewModel: DeviceSyncViewModel
    private let trackProvider: () async -> [Track]
    
    @State private var tracks: [Track] = []
    @State private var isLoadingTracks = false
    @State private var showConfigurationWizard = false
    @State private var showConflictResolution: SyncJob?
    @State private var showTranscodeSettings = false
    @State private var showTranscodeProgress = false
    
    public init(
        viewModel: DeviceSyncViewModel,
        trackProvider: @escaping () async -> [Track]
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.trackProvider = trackProvider
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            devicesSection
            jobsSection
            actionButtons
            statusBanner
        }
        .padding()
        .task {
            await refreshDevicesAndTracks()
        }
        .sheet(isPresented: $showConfigurationWizard) {
            if let device = viewModel.selectedDevice {
                DeviceConfigurationWizardView(
                    isPresented: $showConfigurationWizard,
                    device: device,
                    viewModel: DeviceConfigurationViewModel(deviceId: device.id)
                )
            }
        }
        .sheet(item: $showConflictResolution) { job in
            ConflictResolutionView(
                isPresented: Binding(
                    get: { showConflictResolution != nil },
                    set: { if !$0 { showConflictResolution = nil } }
                ),
                job: job,
                viewModel: ConflictResolutionViewModel(manager: viewModel.manager)
            )
        }
        .sheet(isPresented: $showTranscodeSettings) {
            TranscodeSettingsView(
                isPresented: $showTranscodeSettings,
                viewModel: viewModel.transcodeSettingsViewModel
            )
        }
        .sheet(isPresented: $showTranscodeProgress) {
            TranscodeProgressView(
                isPresented: $showTranscodeProgress,
                viewModel: viewModel.transcodeProgressViewModel
            )
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Device Sync")
                .font(.title)
                .bold()
            Text("Sync your library to USB/MTP/SMB devices.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var devicesSection: some View {
        GroupBox("Available Devices") {
            if viewModel.devices.isEmpty {
                Text(viewModel.isLoading ? "Scanning..." : "No devices detected.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.devices) { device in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(device.name)
                                .font(.headline)
                            Text("\(device.availableSpace / 1024) MB free")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if viewModel.selectedDevice?.id == device.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.selectedDevice = device
                    }
                    Button("Configure") {
                        showConfigurationWizard = true
                    }
                    .buttonStyle(.borderless)
                    Divider()
                }
            }
        }
    }
    
    private var jobsSection: some View {
        GroupBox("Sync Jobs") {
            if viewModel.jobs.isEmpty {
                Text("No sync jobs queued.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.jobs) { job in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(job.request.device.name)
                                .font(.headline)
                            Spacer()
                            Text(job.status.rawValue.capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: job.progress.percentage)
                            .progressViewStyle(.linear)
                        HStack(spacing: 8) {
                            Button("Cancel") {
                                Task {
                                    await viewModel.cancel(job: job)
                                }
                            }
                            .disabled(job.status == .completed || job.status == .failed || job.status == .cancelled)
                            
                            if job.status == .waitingForConflictResolution, let conflicts = job.conflicts {
                                Button("Resolve (\(conflicts.count))") {
                                    showConflictResolution = job
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                    Divider()
                }
            }
        }
    }
    
    private var actionButtons: some View {
        let localisation = LocalisationManager.shared
        return HStack {
            Button(localisation[LocalisationManager.startSync]) {
                Task {
                    await viewModel.startSync(tracks: tracks)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.selectedDevice == nil || tracks.isEmpty)
            
            Button(localisation[LocalisationManager.transcodingSettings]) {
                showTranscodeSettings = true
            }
            
            Button(localisation[LocalisationManager.transcodingProgress]) {
                showTranscodeProgress = true
            }
            
            Button(localisation[LocalisationManager.reloadJobs]) {
                Task { await viewModel.reloadJobs() }
            }
            
            Button(localisation[LocalisationManager.reloadTracks]) {
                Task { await reloadTracks() }
            }
        }
    }
    
    private var statusBanner: some View {
        let localisation = LocalisationManager.shared
        return VStack(alignment: .leading, spacing: 4) {
            if let message = viewModel.infoMessage {
                Label(message, systemImage: "checkmark.seal")
                    .foregroundColor(.green)
            }
            if let error = viewModel.lastError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundColor(.red)
            }
            if isLoadingTracks {
                Label(localisation[LocalisationManager.loadingTracks], systemImage: "arrow.triangle.2.circlepath")
                    .foregroundColor(.secondary)
            } else if tracks.isEmpty {
                Label(localisation[LocalisationManager.noTracksAvailable], systemImage: "music.note.list")
                    .foregroundColor(.secondary)
            } else {
                Label(
                    "\(tracks.count) \(localisation[LocalisationManager.tracksReadyForSync])",
                    systemImage: "music.note.list"
                )
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func refreshDevicesAndTracks() async {
        await viewModel.refreshDevices()
        await viewModel.reloadJobs()
        await reloadTracks()
    }
    
    private func reloadTracks() async {
        isLoadingTracks = true
        let loaded = await trackProvider()
        await MainActor.run {
            self.tracks = loaded
            self.isLoadingTracks = false
        }
    }
}

public extension DeviceSyncView {
    init(viewModel: DeviceSyncViewModel) {
        self.init(viewModel: viewModel, trackProvider: { [] })
    }
    
    init(trackProvider: @escaping () async -> [Track]) {
        let environment = DeviceSyncComposer.makeDefaultEnvironment()
        let defaultViewModel = DeviceSyncViewModel(
            manager: environment.manager,
            transcodeQueue: environment.transcodeQueue
        )
        self.init(viewModel: defaultViewModel, trackProvider: trackProvider)
    }
    
    init() {
        let environment = DeviceSyncComposer.makeDefaultEnvironment()
        self.init(
            viewModel: DeviceSyncViewModel(
                manager: environment.manager,
                transcodeQueue: environment.transcodeQueue
            ),
            trackProvider: { await environment.trackProvider.loadTracks() }
        )
    }
}
