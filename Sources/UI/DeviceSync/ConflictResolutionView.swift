//
//  ConflictResolutionView.swift
//  UI
//
//  Dedicated conflict resolution UI with detailed view
//

import DataLayer
import Shared
import SwiftUI

public struct ConflictResolutionView: View {
    
    @Binding var isPresented: Bool
    @StateObject private var viewModel: ConflictResolutionViewModel
    let job: SyncJob
    
    public init(
        isPresented: Binding<Bool>,
        job: SyncJob,
        viewModel: ConflictResolutionViewModel
    ) {
        _isPresented = isPresented
        self.job = job
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection
                conflictsList
                actionButtons
            }
            .navigationTitle("Resolve Conflicts")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        Task {
                            await viewModel.applyResolutions()
                            isPresented = false
                        }
                    }
                    .disabled(!viewModel.hasResolutions)
                }
            }
        }
        .frame(width: 800, height: 600)
        .task {
            await viewModel.loadConflicts(job: job)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sync Job: \(job.request.device.name)")
                .font(.headline)
            Text("\(viewModel.conflicts.count) conflict\(viewModel.conflicts.count == 1 ? "" : "s") detected")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if viewModel.hasResolutions {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("\(viewModel.resolvedCount) of \(viewModel.conflicts.count) resolved")
                        .font(.caption)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var conflictsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.conflicts) { conflict in
                    ConflictRowView(
                        conflict: conflict,
                        resolution: viewModel.resolutions[conflict.id],
                        onResolutionChange: { resolution in
                            viewModel.setResolution(for: conflict.id, resolution: resolution)
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    private var actionButtons: some View {
        HStack {
            Button("Resolve All: Keep Library") {
                viewModel.resolveAll(strategy: .keepLibrary)
            }
            Button("Resolve All: Keep Device") {
                viewModel.resolveAll(strategy: .keepDevice)
            }
            Spacer()
            Button("Clear All") {
                viewModel.clearAll()
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Conflict Row View

private struct ConflictRowView: View {
    let conflict: SyncConflict
    let resolution: ConflictResolutionAction?
    let onResolutionChange: (ConflictResolutionAction) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(conflict.track.title)
                        .font(.headline)
                    Text(conflict.track.artist)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(conflict.reason.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(4)
            }
            
            HStack(spacing: 16) {
                conflictInfo(
                    title: "Library",
                    checksum: conflict.libraryChecksum,
                    date: nil
                )
                
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundStyle(.secondary)
                
                conflictInfo(
                    title: "Device",
                    checksum: conflict.deviceChecksum,
                    date: nil
                )
            }
            
            Divider()
            
            Picker("Resolution", selection: Binding(
                get: { resolution ?? .keepLibrary },
                set: { onResolutionChange($0) }
            )) {
                Text("Keep Library Version").tag(ConflictResolutionAction.keepLibrary)
                Text("Keep Device Version").tag(ConflictResolutionAction.keepDevice)
                Text("Skip This File").tag(ConflictResolutionAction.skip)
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func conflictInfo(title: String, checksum: String?, date: Date?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let checksum = checksum {
                Text(String(checksum.prefix(16)) + "...")
                    .font(.system(.caption, design: .monospaced))
            } else {
                Text("Unknown")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - ViewModel

@MainActor
public class ConflictResolutionViewModel: ObservableObject {
    
    @Published var conflicts: [SyncConflict] = []
    @Published var resolutions: [UUID: ConflictResolutionAction] = [:]
    
    private let manager: DeviceSyncManagerProtocol
    private var currentJob: SyncJob?
    
    public init(manager: DeviceSyncManagerProtocol) {
        self.manager = manager
    }
    
    var hasResolutions: Bool {
        !resolutions.isEmpty
    }
    
    var resolvedCount: Int {
        resolutions.count
    }
    
    func loadConflicts(job: SyncJob) async {
        currentJob = job
        conflicts = job.conflicts ?? []
        resolutions = [:]
    }
    
    func setResolution(for conflictId: UUID, resolution: ConflictResolutionAction) {
        resolutions[conflictId] = resolution
    }
    
    func resolveAll(strategy: ConflictResolutionAction) {
        for conflict in conflicts {
            resolutions[conflict.id] = strategy
        }
    }
    
    func clearAll() {
        resolutions.removeAll()
    }
    
    func applyResolutions() async {
        guard let job = currentJob else { return }
        
        let syncResolutions = resolutions.map { conflictId, action in
            SyncConflictResolution(conflictId: conflictId, action: action.toSyncConflictResolutionAction())
        }
        
        do {
            _ = try await manager.resolveConflicts(jobId: job.id, resolutions: syncResolutions)
        } catch {
            // Handle error
            print("Failed to apply resolutions: \(error)")
        }
    }
}

// MARK: - Supporting Types

public enum ConflictResolutionAction {
    case keepLibrary
    case keepDevice
    case skip
}

extension ConflictResolutionAction {
    func toSyncConflictResolutionAction() -> SyncConflictResolution.Action {
        switch self {
        case .keepLibrary:
            return .keepLibraryVersion
        case .keepDevice:
            return .keepDeviceVersion
        case .skip:
            return .skipTrack
        }
    }
}
