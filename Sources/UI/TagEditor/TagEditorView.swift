//
//  TagEditorView.swift
//  Audientia - Tag Editor View
//
//  Main view for editing track metadata tags
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import MetadataEngine
import os.log
import Shared
import SwiftUI

/// Main tag editor view
/// BDD: As a user, I want to edit a track's metadata and see it saved
@MainActor
public struct TagEditorView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel: TagEditorViewModel
    @State private var showingSaveConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // MARK: - Initialization
    
    /// Initialize with dependencies
    /// - Parameters:
    ///   - tagWriter: Tag writer coordinator
    ///   - validator: Tag validator
    ///   - history: Tag edit history
    public init(
        tagWriter: any TagWriterCoordinating,
        validator: any TagValidatorProtocol,
        history: any TagEditHistoryProtocol
    ) {
        _viewModel = StateObject(
            wrappedValue: TagEditorViewModel(
                tagWriter: tagWriter,
                validator: validator,
                history: history
            )
        )
    }
    
    // MARK: - Body
    
    public var body: some View {
        Form {
            // Basic Information Section
            Section("Basic Information") {
                TextField("Title", text: $viewModel.editedTitle)
                TextField("Artist", text: $viewModel.editedArtist)
                TextField("Album", text: $viewModel.editedAlbum)
            }
            
            // Additional Information Section
            Section("Additional Information") {
                HStack {
                    Text("Year")
                    Spacer()
                    TextField("Year", value: $viewModel.editedYear, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }
                
                HStack {
                    Text("Track Number")
                    Spacer()
                    TextField("Track", value: $viewModel.editedTrackNumber, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }
                
                HStack {
                    Text("Disc Number")
                    Spacer()
                    TextField("Disc", value: $viewModel.editedDiscNumber, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }
                
                TextField("Genre", text: Binding(
                    get: { viewModel.editedGenre ?? "" },
                    set: { viewModel.editedGenre = $0.isEmpty ? nil : $0 }
                ))
            }
            
            // Validation Errors Section
            if !viewModel.validationErrors.isEmpty {
                Section("Validation Errors") {
                    ForEach(viewModel.validationErrors, id: \.localizedDescription) { error in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(error.localizedDescription)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Action Buttons Section
            Section {
                HStack {
                    // Undo/Redo buttons
                    Button {
                        Task {
                            do {
                                try await viewModel.undo()
                            } catch {
                                showError(error.localizedDescription)
                            }
                        }
                    } label: {
                        Label("Undo", systemImage: "arrow.uturn.backward")
                    }
                    .disabled(!viewModel.canUndo || viewModel.isSaving)
                    
                    Button {
                        Task {
                            do {
                                try await viewModel.redo()
                            } catch {
                                showError(error.localizedDescription)
                            }
                        }
                    } label: {
                        Label("Redo", systemImage: "arrow.uturn.forward")
                    }
                    .disabled(!viewModel.canRedo || viewModel.isSaving)
                    
                    Spacer()
                    
                    // Save button
                    Button {
                        Task {
                            await saveTags()
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(viewModel.isSaving || viewModel.currentTrack == nil)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Edit Tags")
        .alert(
            "Error",
            isPresented: $showingError,
            actions: {
                Button("OK", role: .cancel) { }
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
    
    private func saveTags() async {
        do {
            try await viewModel.save()
            Logger.userInterface.info("Tags saved successfully")
        } catch {
            showError(error.localizedDescription)
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}
