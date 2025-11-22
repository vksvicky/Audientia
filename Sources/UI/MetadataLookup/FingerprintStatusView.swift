//
//  FingerprintStatusView.swift
//  Audientia - Fingerprint Status View
//
//  SwiftUI view for displaying fingerprint status and manual trigger
//

import MetadataEngine
import Shared
import SwiftUI

public struct FingerprintStatusView: View {
    @StateObject private var viewModel: FingerprintStatusViewModel
    private let track: Track?
    
    public init(
        viewModel: FingerprintStatusViewModel,
        track: Track?
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.track = track
    }
    
    public init(
        acoustIDService: any AcoustIDServicing,
        fingerprintCache: (any FingerprintCacheProtocol)? = nil,
        track: Track?
    ) {
        _viewModel = StateObject(
            wrappedValue: FingerprintStatusViewModel(
                acoustIDService: acoustIDService,
                fingerprintCache: fingerprintCache
            )
        )
        self.track = track
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            statusSection
            actionSection
            if let error = viewModel.lastError {
                errorSection(error: error)
            }
        }
        .padding()
        .task {
            if let track = track {
                await viewModel.checkStatus(for: track)
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            Text("Fingerprint Status")
                .font(.headline)
            Spacer()
            if viewModel.isGenerating {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.8)
            }
        }
    }
    
    private var statusSection: some View {
        HStack(spacing: 8) {
            Label(
                viewModel.fingerprintStatus.displayText,
                systemImage: viewModel.fingerprintStatus.systemImage
            )
            .foregroundColor(viewModel.fingerprintStatus.color)
            
            if viewModel.fingerprintStatus == .cached, let fingerprint = viewModel.fingerprint {
                Spacer()
                Text("Fingerprint: \(String(fingerprint.prefix(20)))...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var actionSection: some View {
        HStack(spacing: 12) {
            Button("Generate Fingerprint") {
                if let track = track {
                    Task {
                        await viewModel.generateFingerprint(for: track)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(track == nil || viewModel.isGenerating)
            
            Button("Refresh Status") {
                if let track = track {
                    Task {
                        await viewModel.checkStatus(for: track)
                    }
                }
            }
            .buttonStyle(.bordered)
            .disabled(track == nil || viewModel.isGenerating)
        }
    }
    
    private func errorSection(error: Error) -> some View {
        Label(error.localizedDescription, systemImage: "exclamationmark.triangle.fill")
            .foregroundColor(.red)
            .font(.caption)
    }
}

// MARK: - Preview

#if DEBUG
// Preview disabled - requires mock services
// Use FingerprintStatusViewTests for testing
#endif
