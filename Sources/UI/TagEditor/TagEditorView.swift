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
    @State private var showingMetadataLookup = false
    
    // Metadata lookup dependencies (optional, can be injected)
    private let acoustIDService: (any AcoustIDServicing)?
    private let musicBrainzClient: (any MusicBrainzClientProtocol)?
    private let discogsClient: (any DiscogsClientProtocol)?
    
    // MARK: - Initialization
    
    /// Initialize with dependencies
    /// - Parameters:
    ///   - tagWriter: Tag writer coordinator
    ///   - validator: Tag validator
    ///   - history: Tag edit history
    ///   - acoustIDService: AcoustID service (optional, for metadata lookup)
    ///   - musicBrainzClient: MusicBrainz client (optional, for metadata lookup)
    ///   - discogsClient: Discogs client (optional, for metadata lookup)
    public init(
        tagWriter: any TagWriterCoordinating,
        validator: any TagValidatorProtocol,
        history: any TagEditHistoryProtocol,
        acoustIDService: (any AcoustIDServicing)? = nil,
        musicBrainzClient: (any MusicBrainzClientProtocol)? = nil,
        discogsClient: (any DiscogsClientProtocol)? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: TagEditorViewModel(
                tagWriter: tagWriter,
                validator: validator,
                history: history
            )
        )
        self.acoustIDService = acoustIDService
        self.musicBrainzClient = musicBrainzClient
        self.discogsClient = discogsClient
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
                                .foregroundColor(Color("AccentColor"))
                            Text(error.localizedDescription)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Metadata Lookup Section
            if acoustIDService != nil && musicBrainzClient != nil && discogsClient != nil {
                Section("Metadata Enhancement") {
                    Button {
                        showingMetadataLookup = true
                    } label: {
                        Label("Lookup Metadata", systemImage: "magnifyingglass")
                    }
                    .disabled(viewModel.currentTrack == nil)
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
        .sheet(isPresented: $showingMetadataLookup) {
            if let track = viewModel.currentTrack,
               let acoustID = acoustIDService,
               let musicBrainz = musicBrainzClient,
               let discogs = discogsClient {
                MetadataLookupSheetView(
                    track: track,
                    acoustIDService: acoustID,
                    musicBrainzClient: musicBrainz,
                    discogsClient: discogs,
                    onApply: { mergedTrack in
                        viewModel.applyMetadata(from: mergedTrack)
                        showingMetadataLookup = false
                    },
                    onCancel: {
                        showingMetadataLookup = false
                    }
                )
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
