//
//  BatchTagOperationsView.swift
//  Audientia - Batch Tag Operations View
//
//  View for batch updating multiple tracks' metadata
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import MetadataEngine
import Shared
import SwiftUI

/// Batch tag operations view
/// BDD: As a user, I want to update multiple tracks at once
@MainActor
public struct BatchTagOperationsView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel: BatchTagOperationsViewModel
    @State private var selectedTracks: [Shared.Track] = []
    @State private var showingResults = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // MARK: - Initialisation
    
    /// Initialise with batch operations
    /// - Parameter batchOperations: The batch operations instance to use
    public init(batchOperations: any BatchTagOperationsProtocol) {
        _viewModel = StateObject(
            wrappedValue: BatchTagOperationsViewModel(batchOperations: batchOperations)
        )
    }
    
    // MARK: - Body
    
    public var body: some View {
        Form {
            // Selection Section
            Section("Select Tracks") {
                Text("\(selectedTracks.count) track(s) selected")
                    .foregroundColor(.secondary)
                
                // Track list would go here
                // For now, this is a placeholder for the actual track selection UI
            }
            
            // Batch Edit Section
            Section("Batch Edit") {
                // Common fields that can be applied to all tracks
                TextField("Artist (applies to all)", text: .constant(""))
                TextField("Album (applies to all)", text: .constant(""))
                TextField("Genre (applies to all)", text: .constant(""))
            }
            
            // Progress Section
            if viewModel.isProcessing {
                Section("Progress") {
                    ProgressView(value: viewModel.progress) {
                        Text("Processing...")
                    }
                }
            }
            
            // Results Section
            if let result = viewModel.result {
                Section("Results") {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(result.successCount) tracks updated successfully")
                    }
                    
                    if result.failureCount > 0 {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text("\(result.failureCount) tracks failed")
                        }
                        
                        // Show failure details
                        ForEach(Array(result.failures.enumerated()), id: \.offset) { _, failure in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(failure.fileURL.lastPathComponent)
                                    .font(.caption)
                                Text(failure.error.localizedDescription)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            // Action Buttons Section
            Section {
                Button {
                    Task {
                        await performBatchUpdate()
                    }
                } label: {
                    if viewModel.isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Apply to All Selected Tracks")
                    }
                }
                .disabled(viewModel.isProcessing || selectedTracks.isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(LocalisationManager.shared[LocalisationManager.batchTagOperations])
        .alert(
            LocalisationManager.shared[LocalisationManager.error],
            isPresented: $showingError,
            actions: {
                Button(LocalisationManager.shared[LocalisationManager.apply], role: .cancel) { }
            },
            message: {
                Text(errorMessage)
            }
        )
        .task(id: viewModel.lastError?.localizedDescription) {
            if let error = viewModel.lastError {
                showError(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func performBatchUpdate() async {
        // This would create edited tracks based on the batch edit fields
        // For now, this is a placeholder
        let fileURLs = selectedTracks.map { URL(fileURLWithPath: $0.filePath) }
        
        do {
            // In a real implementation, this would apply the batch edits to all tracks
            // For now, we'll use the tracks as-is
            try await viewModel.updateTracks(tracks: selectedTracks, fileURLs: fileURLs)
            showingResults = true
        } catch {
            showError(error.localizedDescription)
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}
