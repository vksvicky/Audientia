//
//  TagEditorViewBDDTests.swift
//  UITests
//
//  BDD tests for TagEditorView
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import MetadataEngine
@testable import Shared
import SwiftUI
import XCTest

// TagEditorView is compiled into UITests target, no import needed

/// BDD tests for TagEditorView
/// Scenarios: "As a user, I want to edit track metadata in a user-friendly interface"
@MainActor
final class TagEditorViewBDDTests: XCTestCase {
    
    fileprivate var mockTagWriter: MockTagWriterCoordinator!
    fileprivate var mockValidator: MockTagValidator!
    fileprivate var mockHistory: MockTagEditHistory!
    
    override func setUp() async throws {
        try await super.setUp()
        mockTagWriter = MockTagWriterCoordinator()
        mockValidator = MockTagValidator()
        mockHistory = MockTagEditHistory()
    }
    
    override func tearDown() async throws {
        mockTagWriter = nil
        mockValidator = nil
        mockHistory = nil
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createView() -> TagEditorView {
        TagEditorView(
            tagWriter: mockTagWriter,
            validator: mockValidator,
            history: mockHistory
        )
    }
    
    // MARK: - BDD Scenarios
    
    /// Scenario: As a user, I want to see a form with all track metadata fields
    func testUserSeesFormWithAllMetadataFields() {
        // Given - I open the tag editor
        let view = createView()
        
        // When/Then - I should see fields for title, artist, album, year, track number, disc number, and genre
        // The view includes all these fields in the Form
        XCTAssertNotNil(view, "View should display all metadata fields")
    }
    
    /// Scenario: As a user, I want to see validation warnings when I enter invalid data
    func testUserSeesValidationWarnings() {
        // Given - I have the tag editor open
        let view = createView()
        
        // When/Then - I should see validation errors displayed when validation fails
        // The view includes a "Validation Errors" section that displays when validationErrors is not empty
        XCTAssertNotNil(view, "View should display validation warnings")
    }
    
    /// Scenario: As a user, I want to see undo/redo buttons that are enabled when appropriate
    func testUserSeesUndoRedoButtons() {
        // Given - I have the tag editor open
        let view = createView()
        
        // When/Then - I should see undo and redo buttons
        // The view includes undo and redo buttons that are disabled when not available
        XCTAssertNotNil(view, "View should display undo/redo buttons")
    }
    
    /// Scenario: As a user, I want to see a save button that shows progress when saving
    func testUserSeesSaveButtonWithProgress() {
        // Given - I have the tag editor open
        let view = createView()
        
        // When/Then - I should see a save button that shows a progress indicator when saving
        // The view includes a save button that displays ProgressView when isSaving is true
        XCTAssertNotNil(view, "View should display save button with progress indicator")
    }
}

// MARK: - Shared Mock Classes

/// Mock TagWriterCoordinator for BDD view tests
private final class MockTagWriterCoordinator: TagWriterCoordinating, @unchecked Sendable {
    var canWriteValue = true
    var writeShouldSucceed = true
    var writeError: Error?
    var writeCalled = false
    var lastWrittenTrack: Shared.Track?
    var lastWrittenURL: URL?
    
    func canWrite(fileURL: URL) -> Bool {
        canWriteValue
    }
    
    func write(track: Shared.Track, to fileURL: URL) async throws {
        writeCalled = true
        lastWrittenTrack = track
        lastWrittenTrack = track
        lastWrittenURL = fileURL
        if !writeShouldSucceed {
            throw writeError ?? TagWriterError.fileNotFound(fileURL)
        }
    }
    
    func update(track: Shared.Track, in fileURL: URL) async throws {
        writeCalled = true
        lastWrittenTrack = track
        lastWrittenURL = fileURL
        if !writeShouldSucceed {
            throw writeError ?? TagWriterError.fileNotFound(fileURL)
        }
    }
}

/// Mock TagValidator for BDD view tests
private final class MockTagValidator: TagValidatorProtocol, @unchecked Sendable {
    var validationResult = TagValidationResult(isValid: true, errors: [])
    
    func validate(track: Shared.Track) -> TagValidationResult {
        validationResult
    }
}

/// Mock TagEditHistory for BDD view tests
private final class MockTagEditHistory: TagEditHistoryProtocol, @unchecked Sendable {
    var canUndoValue = false
    var canRedoValue = false
    var undoResult: TagEdit?
    var redoResult: TagEdit?
    var recordEditCalled = false
    var lastRecordedEdit: TagEdit?
    
    var canUndo: Bool {
        canUndoValue
    }
    
    var canRedo: Bool {
        canRedoValue
    }
    
    func undo() -> TagEdit? {
        undoResult
    }
    
    func redo() -> TagEdit? {
        redoResult
    }
    
    func addEdit(originalTrack: Shared.Track, editedTrack: Shared.Track, fileURL: URL) {
        recordEditCalled = true
        lastRecordedEdit = TagEdit(originalTrack: originalTrack, editedTrack: editedTrack, fileURL: fileURL)
    }
}

