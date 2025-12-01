//
//  TagEditHistory.swift
//  MetadataEngine
//
//  Undo/redo system for tag edits
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Represents a single tag edit operation
public struct TagEdit: Sendable {
    /// The original track before editing
    public let originalTrack: Track
    
    /// The edited track after editing
    public let editedTrack: Track
    
    /// The file URL of the track
    public let fileURL: URL
    
    public init(originalTrack: Track, editedTrack: Track, fileURL: URL) {
        self.originalTrack = originalTrack
        self.editedTrack = editedTrack
        self.fileURL = fileURL
    }
}

/// Manages undo/redo history for tag edits
public final class TagEditHistory: @unchecked Sendable {
    private var undoStack: [TagEdit] = []
    private var redoStack: [TagEdit] = []
    private let maxHistorySize: Int
    
    /// Initialise with a maximum history size
    /// - Parameter maxHistorySize: Maximum number of edits to keep in history (default: 100)
    public init(maxHistorySize: Int = 100) {
        self.maxHistorySize = maxHistorySize
    }
    
    /// Check if undo is available
    public var canUndo: Bool {
        !undoStack.isEmpty
    }
    
    /// Check if redo is available
    public var canRedo: Bool {
        !redoStack.isEmpty
    }
    
    /// Add an edit to the history
    /// - Parameters:
    ///   - originalTrack: The original track before editing
    ///   - editedTrack: The edited track after editing
    ///   - fileURL: The file URL of the track
    public func addEdit(originalTrack: Track, editedTrack: Track, fileURL: URL) {
        let edit = TagEdit(originalTrack: originalTrack, editedTrack: editedTrack, fileURL: fileURL)
        
        // Add to undo stack
        undoStack.append(edit)
        
        // Clear redo stack when new edit is added (branching history)
        redoStack.removeAll()
        
        // Enforce history size limit
        if undoStack.count > maxHistorySize {
            undoStack.removeFirst()
        }
    }
    
    /// Undo the last edit
    /// - Returns: The edit to undo (original track), or nil if nothing to undo
    public func undo() -> TagEdit? {
        guard let edit = undoStack.popLast() else {
            return nil
        }
        
        // Move to redo stack
        redoStack.append(edit)
        
        // Return the edit (contains original track to restore)
        return edit
    }
    
    /// Redo the last undone edit
    /// - Returns: The edit to redo (edited track), or nil if nothing to redo
    public func redo() -> TagEdit? {
        guard let edit = redoStack.popLast() else {
            return nil
        }
        
        // Move back to undo stack
        undoStack.append(edit)
        
        // Return the edit (contains edited track to apply)
        return edit
    }
    
    /// Clear all history
    public func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
    }
}
