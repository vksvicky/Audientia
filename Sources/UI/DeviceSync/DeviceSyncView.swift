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
        .toolbar {
            Button("Refresh") {
                Task {
                    await viewModel.refreshDevices()
                    await viewModel.reloadJobs()
                }
            }
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
                                    Task {
                                        let resolutions = conflicts.map {
                                            SyncConflictResolution(conflictId: $0.id, action: .keepLibraryVersion)
                                        }
                                        await viewModel.resolve(job: job, with: resolutions)
                                    }
                                }
                            }
                        }
                    }
                    Divider()
                }
            }
        }
    }
    
    private var actionButtons: some View {
        HStack {
            Button("Start Sync") {
                Task {
                    await viewModel.startSync(tracks: tracks)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.selectedDevice == nil || tracks.isEmpty)
            
            Button("Reload Jobs") {
                Task { await viewModel.reloadJobs() }
            }
            
            Button("Reload Tracks") {
                Task { await reloadTracks() }
            }
        }
    }
    
    private var statusBanner: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let message = viewModel.infoMessage {
                Label(message, systemImage: "checkmark.seal")
                    .foregroundColor(.green)
            }
            if let error = viewModel.lastError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundColor(.red)
            }
            if isLoadingTracks {
                Label("Loading tracks…", systemImage: "arrow.triangle.2.circlepath")
                    .foregroundColor(.secondary)
            } else if tracks.isEmpty {
                Label("No tracks available for sync.", systemImage: "music.note.list")
                    .foregroundColor(.secondary)
            } else {
                Label("\(tracks.count) tracks ready for sync", systemImage: "music.note.list")
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
        let defaultViewModel = DeviceSyncViewModel(manager: environment.manager)
        self.init(viewModel: defaultViewModel, trackProvider: trackProvider)
    }
    
    init() {
        let environment = DeviceSyncComposer.makeDefaultEnvironment()
        self.init(
            viewModel: DeviceSyncViewModel(manager: environment.manager),
            trackProvider: { await environment.trackProvider.loadTracks() }
        )
    }
}
