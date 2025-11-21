//
//  TranscodeProgressView.swift
//  UI
//
//  Transcoding progress view for device sync
//

import DataLayer
import Foundation
import Shared
import SwiftUI

public struct TranscodeProgressView: View {
    
    @StateObject private var viewModel: TranscodeProgressViewModel
    @Binding var isPresented: Bool
    
    public init(
        isPresented: Binding<Bool>,
        viewModel: TranscodeProgressViewModel
    ) {
        _isPresented = isPresented
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.activeJobs.isEmpty {
                    emptyState
                } else {
                    jobsList
                }
            }
            .padding()
            .navigationTitle("Transcoding Progress")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        isPresented = false
                    }
                }
            }
            .task {
                await viewModel.startMonitoring()
            }
            .onDisappear {
                viewModel.stopMonitoring()
            }
        }
        .frame(width: 600, height: 400)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text("No Active Transcoding Jobs")
                .font(.headline)
            Text("All transcoding jobs have completed")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var jobsList: some View {
        List {
            ForEach(viewModel.activeJobs) { job in
                TranscodeJobRow(job: job) {
                    Task {
                        await viewModel.cancelJob(job.id)
                    }
                }
            }
        }
    }
}

// MARK: - Job Row

private struct TranscodeJobRow: View {
    let job: TranscodeJob
    let onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(job.track.title)
                    .font(.headline)
                Spacer()
                Button("Cancel", role: .destructive) {
                    onCancel()
                }
                .buttonStyle(.bordered)
            }
            
            Text("\(job.track.artist) • \(job.track.album)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("\(job.profile.name) → \((job.outputPath as NSString).lastPathComponent)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if case .transcoding(let progress) = job.status {
                ProgressView(value: progress)
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if case .queued = job.status {
                HStack {
                    ProgressView()
                        .scaleEffect(0.5)
                    Text("Queued...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ViewModel

@MainActor
public class TranscodeProgressViewModel: ObservableObject {
    
    @Published var activeJobs: [TranscodeJob] = []
    @Published var errorMessage: String?
    
    private let queue: TranscodeQueueProtocol
    private var monitoringTask: Task<Void, Never>?
    
    public init(queue: TranscodeQueueProtocol) {
        self.queue = queue
    }
    
    func startMonitoring() async {
        monitoringTask = Task {
            while !Task.isCancelled {
                await refreshJobs()
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
        }
    }
    
    func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
    }
    
    func refreshJobs() async {
        let jobs = await queue.getActiveJobs()
        await MainActor.run {
            activeJobs = jobs
        }
    }
    
    func cancelJob(_ jobId: UUID) async {
        await queue.cancel(jobId: jobId)
        await refreshJobs()
    }
}
