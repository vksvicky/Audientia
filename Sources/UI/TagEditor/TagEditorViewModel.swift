//
//  TagEditorViewModel.swift
//  Audientia - Tag Editor ViewModel
//
//  ViewModel for tag editing UI
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Combine
import Foundation
import MetadataEngine
import os.log
import Shared
import SwiftUI

/// Protocol for tag edit history (for dependency injection)
public protocol TagEditHistoryProtocol: Sendable {
    var canUndo: Bool { get }
    var canRedo: Bool { get }
    func undo() -> TagEdit?
    func redo() -> TagEdit?
    func addEdit(originalTrack: Shared.Track, editedTrack: Shared.Track, fileURL: URL)
}

/// Extension to make TagEditHistory conform to protocol
extension TagEditHistory: TagEditHistoryProtocol {}

/// ViewModel for tag editing
/// Manages track metadata editing, validation, and undo/redo
@MainActor
public final class TagEditorViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current track being edited
    @Published public private(set) var currentTrack: Shared.Track?
    
    /// Current file URL
    @Published public private(set) var currentFileURL: URL?
    
    /// Edited title
    @Published public var editedTitle: String = ""
    
    /// Edited artist
    @Published public var editedArtist: String = ""
    
    /// Edited album
    @Published public var editedAlbum: String = ""
    
    /// Edited year
    @Published public var editedYear: Int?
    
    /// Edited track number
    @Published public var editedTrackNumber: Int?
    
    /// Edited disc number
    @Published public var editedDiscNumber: Int?
    
    /// Edited genre
    @Published public var editedGenre: String?
    
    /// Validation errors
    @Published public private(set) var validationErrors: [TagValidationError] = []
    
    /// Whether save is in progress
    @Published public private(set) var isSaving = false
    
    /// Last error that occurred
    @Published public private(set) var lastError: Error?
    
    /// Whether undo is available
    @Published public private(set) var canUndo = false
    
    /// Whether redo is available
    @Published public private(set) var canRedo = false
    
    // MARK: - Private Properties
    
    private let tagWriter: any TagWriterCoordinating
    private let validator: any TagValidatorProtocol
    private let history: any TagEditHistoryProtocol
    
    // MARK: - Initialisation
    
    /// Initialise with dependencies
    /// - Parameters:
    ///   - tagWriter: Tag writer coordinator
    ///   - validator: Tag validator
    ///   - history: Tag edit history
    public init(
        tagWriter: any TagWriterCoordinating,
        validator: any TagValidatorProtocol,
        history: any TagEditHistoryProtocol
    ) {
        self.tagWriter = tagWriter
        self.validator = validator
        self.history = history
        Logger.userInterface.info("TagEditorViewModel initialised")
    }
    
    // MARK: - Public Methods
    
    /// Load a track for editing
    /// - Parameters:
    ///   - track: The track to edit
    ///   - fileURL: The file URL of the track
    public func loadTrack(track: Shared.Track, fileURL: URL) async {
        currentTrack = track
        currentFileURL = fileURL
        
        // Populate edited fields
        editedTitle = track.title
        editedArtist = track.artist
        editedAlbum = track.album
        editedYear = track.year
        editedTrackNumber = track.trackNumber
        editedDiscNumber = track.discNumber
        editedGenre = track.genre
        
        // Clear validation errors
        validationErrors = []
        lastError = nil
        
        // Update undo/redo state
        updateUndoRedoState()
        
        Logger.userInterface.debug("Loaded track for editing: \(track.title)")
    }
    
    /// Save edited tags
    public func save() async throws {
        guard let currentTrack = currentTrack,
              let fileURL = currentFileURL else {
            throw TagEditorError.noTrackLoaded
        }
        
        isSaving = true
        validationErrors = []
        lastError = nil
        
        // Create edited track
        let editedTrack = Shared.Track(
            id: currentTrack.id,
            title: editedTitle,
            artist: editedArtist,
            album: editedAlbum,
            duration: currentTrack.duration,
            filePath: currentTrack.filePath,
            fileSize: currentTrack.fileSize,
            bitrate: currentTrack.bitrate,
            sampleRate: currentTrack.sampleRate,
            year: editedYear,
            trackNumber: editedTrackNumber,
            discNumber: editedDiscNumber,
            genre: editedGenre
        )
        
        // Validate
        let validationResult = validator.validate(track: editedTrack)
        if !validationResult.isValid {
            validationErrors = validationResult.errors
            isSaving = false
            throw TagEditorError.validationFailed(validationResult.errors)
        }
        
        // Save original track for history
        let originalTrack = currentTrack
        
        // Write tags
        do {
            try await tagWriter.update(track: editedTrack, in: fileURL)
            
            // Record in history
            history.addEdit(originalTrack: originalTrack, editedTrack: editedTrack, fileURL: fileURL)
            
            // Update current track
            self.currentTrack = editedTrack
            
            // Update undo/redo state
            updateUndoRedoState()
            
            Logger.userInterface.info("Saved tags for track: \(editedTrack.title)")
        } catch {
            lastError = error
            isSaving = false
            throw TagEditorError.writeFailed(error)
        }
        
        isSaving = false
    }
    
    /// Apply metadata from a lookup result
    /// - Parameter mergedTrack: The merged track from metadata lookup
    public func applyMetadata(from mergedTrack: Shared.Track) {
        editedTitle = mergedTrack.title
        editedArtist = mergedTrack.artist
        editedAlbum = mergedTrack.album
        editedYear = mergedTrack.year
        editedTrackNumber = mergedTrack.trackNumber
        editedDiscNumber = mergedTrack.discNumber
        editedGenre = mergedTrack.genre
        
        // Clear validation errors (will be re-validated on save)
        validationErrors = []
        lastError = nil
        
        Logger.userInterface.info("Applied metadata from lookup: \(mergedTrack.title)")
    }
    
    /// Undo last edit
    public func undo() async throws {
        guard let edit = history.undo() else {
            return // No undo available
        }
        
        guard let fileURL = currentFileURL else {
            throw TagEditorError.noTrackLoaded
        }
        
        // Restore original track
        try await tagWriter.update(track: edit.originalTrack, in: fileURL)
        
        // Reload original values
        await loadTrack(track: edit.originalTrack, fileURL: fileURL)
        
        // Update undo/redo state
        updateUndoRedoState()
        
        Logger.userInterface.info("Undid tag edit")
    }
    
    /// Redo last undone edit
    public func redo() async throws {
        guard let edit = history.redo() else {
            return // No redo available
        }
        
        guard let fileURL = currentFileURL else {
            throw TagEditorError.noTrackLoaded
        }
        
        // Restore edited track
        try await tagWriter.update(track: edit.editedTrack, in: fileURL)
        
        // Reload edited values
        await loadTrack(track: edit.editedTrack, fileURL: fileURL)
        
        // Update undo/redo state
        updateUndoRedoState()
        
        Logger.userInterface.info("Redid tag edit")
    }
    
    // MARK: - Private Methods
    
    private func updateUndoRedoState() {
        canUndo = history.canUndo
        canRedo = history.canRedo
    }
}

/// Errors that can occur during tag editing
public enum TagEditorError: LocalizedError {
    case noTrackLoaded
    case validationFailed([TagValidationError])
    case writeFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .noTrackLoaded:
            return "No track is currently loaded for editing"
        case let .validationFailed(errors):
            return "Validation failed: \(errors.map { $0.localizedDescription }.joined(separator: ", "))"
        case let .writeFailed(error):
            return "Failed to write tags: \(error.localizedDescription)"
        }
    }
}
