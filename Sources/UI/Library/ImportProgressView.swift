//
//  ImportProgressView.swift
//  Audientia
//
//  Import/scan progress indicator view
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import DataLayer
import Shared
import SwiftUI

/// View displaying import/scan progress
@MainActor
public struct ImportProgressView: View {
    @StateObject private var viewModel: ImportProgressViewModel
    
    public init(scanner: (any LibraryScannerProtocol)? = nil) {
        _viewModel = StateObject(
            wrappedValue: ImportProgressViewModel(scanner: scanner)
        )
    }
    
    public var body: some View {
        Group {
            if viewModel.isActive {
                progressContent
            }
        }
        .task {
            await viewModel.observeProgress()
        }
    }
    
    @ViewBuilder
    private var progressContent: some View {
        VStack(spacing: 8) {
            HStack {
                ProgressView(value: viewModel.progress, total: 1.0)
                    .progressViewStyle(.linear)
                Text("\(Int(viewModel.progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 40)
            }
            
            if let status = viewModel.status {
                Text(status)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

/// ViewModel for import/scan progress
@MainActor
final class ImportProgressViewModel: ObservableObject {
    @Published private(set) var isActive = false
    @Published private(set) var progress: Double = 0.0
    @Published private(set) var status: String?
    
    private let scanner: (any LibraryScannerProtocol)?
    
    init(scanner: (any LibraryScannerProtocol)?) {
        self.scanner = scanner
    }
    
    func observeProgress() async {
        // In a real implementation, this would observe scanner progress
        // For now, this is a placeholder that can be wired to actual scanner events
        guard scanner != nil else { return }
        
        // Simulate progress observation
        // Real implementation would use Combine or async streams
    }
}
