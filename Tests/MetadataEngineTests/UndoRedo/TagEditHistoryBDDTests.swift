//
//  TagEditHistoryBDDTests.swift
//  MetadataEngineTests
//
//  BDD tests for TagEditHistory
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// BDD tests for TagEditHistory
/// Scenarios: "As a user, I want to undo and redo tag edits"
@MainActor
final class TagEditHistoryBDDTests: XCTestCase {
    
    var history: TagEditHistory!
    
    override func setUp() async throws {
        try await super.setUp()
        history = TagEditHistory(maxHistorySize: 100)
    }
    
    override func tearDown() async throws {
        history = nil
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createTrack(
        id: UUID = UUID(),
        title: String = "Test Title",
        artist: String = "Test Artist",
        filePath: String = "/path/to/track.mp3"
    ) -> Track {
        Track(
            id: id,
            title: title,
            artist: artist,
            album: "Test Album",
            duration: 180.0,
            filePath: filePath,
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100,
            year: 2023,
            trackNumber: 1,
            discNumber: 1,
            genre: "Rock"
        )
    }
    
    // MARK: - Scenario: Undo Edit
    
    /// Scenario: As a user, I want to undo a tag edit I just made
    /// Given: I edited a track's title from "Original" to "Edited"
    /// When: I undo the edit
    /// Then: The track's title should be restored to "Original"
    func testUserUndoesTagEdit() {
        // Given - Track edit
        let originalTrack = createTrack(title: "Original Title")
        let editedTrack = createTrack(id: originalTrack.id, title: "Edited Title")
        let fileURL = URL(fileURLWithPath: originalTrack.filePath)
        history.addEdit(originalTrack: originalTrack, editedTrack: editedTrack, fileURL: fileURL)
        
        // When - Undo the edit
        let undoEdit = history.undo()
        
        // Then - Should return original track
        XCTAssertNotNil(undoEdit, "Should return undo edit")
        XCTAssertEqual(undoEdit?.originalTrack.title, "Original Title", "Should restore original title")
        XCTAssertEqual(undoEdit?.originalTrack.id, originalTrack.id, "Should be the same track")
    }
    
    // MARK: - Scenario: Redo Edit
    
    /// Scenario: As a user, I want to redo a tag edit I just undid
    /// Given: I edited a track's title, then undid it
    /// When: I redo the edit
    /// Then: The track's title should be restored to the edited value
    func testUserRedoesTagEdit() {
        // Given - Track edit that was undone
        let originalTrack = createTrack(title: "Original Title")
        let editedTrack = createTrack(id: originalTrack.id, title: "Edited Title")
        let fileURL = URL(fileURLWithPath: originalTrack.filePath)
        history.addEdit(originalTrack: originalTrack, editedTrack: editedTrack, fileURL: fileURL)
        _ = history.undo()
        
        // When - Redo the edit
        let redoEdit = history.redo()
        
        // Then - Should return edited track
        XCTAssertNotNil(redoEdit, "Should return redo edit")
        XCTAssertEqual(redoEdit?.editedTrack.title, "Edited Title", "Should restore edited title")
        XCTAssertEqual(redoEdit?.editedTrack.id, editedTrack.id, "Should be the same track")
    }
    
    // MARK: - Scenario: Multiple Edits
    
    /// Scenario: As a user, I want to undo multiple edits in sequence
    /// Given: I made 3 edits to different tracks
    /// When: I undo 3 times
    /// Then: All 3 edits should be undone in reverse order
    func testUserUndoesMultipleEdits() {
        // Given - 3 edits
        let track1 = createTrack(title: "Original 1", filePath: "/path/to/track1.mp3")
        let edited1 = createTrack(id: track1.id, title: "Edited 1", filePath: track1.filePath)
        history.addEdit(originalTrack: track1, editedTrack: edited1, fileURL: URL(fileURLWithPath: track1.filePath))
        
        let track2 = createTrack(title: "Original 2", filePath: "/path/to/track2.mp3")
        let edited2 = createTrack(id: track2.id, title: "Edited 2", filePath: track2.filePath)
        history.addEdit(originalTrack: track2, editedTrack: edited2, fileURL: URL(fileURLWithPath: track2.filePath))
        
        let track3 = createTrack(title: "Original 3", filePath: "/path/to/track3.mp3")
        let edited3 = createTrack(id: track3.id, title: "Edited 3", filePath: track3.filePath)
        history.addEdit(originalTrack: track3, editedTrack: edited3, fileURL: URL(fileURLWithPath: track3.filePath))
        
        // When - Undo 3 times
        let undo1 = history.undo()
        let undo2 = history.undo()
        let undo3 = history.undo()
        
        // Then - Should undo in reverse order (3, 2, 1)
        XCTAssertNotNil(undo1, "Should undo first edit")
        XCTAssertNotNil(undo2, "Should undo second edit")
        XCTAssertNotNil(undo3, "Should undo third edit")
        XCTAssertEqual(undo1?.originalTrack.title, "Original 3", "Should undo most recent first")
        XCTAssertEqual(undo2?.originalTrack.title, "Original 2", "Should undo second most recent")
        XCTAssertEqual(undo3?.originalTrack.title, "Original 1", "Should undo oldest")
    }
    
    // MARK: - Scenario: New Edit Clears Redo
    
    /// Scenario: As a user, I want to know that making a new edit after undoing clears the redo stack
    /// Given: I edited a track, then undid it
    /// When: I make a new edit
    /// Then: I should not be able to redo the previous edit
    func testUserMakesNewEditAfterUndo() {
        // Given - Track edit that was undone
        let originalTrack1 = createTrack(title: "Original 1")
        let editedTrack1 = createTrack(id: originalTrack1.id, title: "Edited 1")
        let fileURL1 = URL(fileURLWithPath: originalTrack1.filePath)
        history.addEdit(originalTrack: originalTrack1, editedTrack: editedTrack1, fileURL: fileURL1)
        _ = history.undo()
        XCTAssertTrue(history.canRedo, "Should be able to redo")
        
        // When - Make new edit
        let originalTrack2 = createTrack(title: "Original 2", filePath: "/path/to/track2.mp3")
        let editedTrack2 = createTrack(id: originalTrack2.id, title: "Edited 2", filePath: originalTrack2.filePath)
        let fileURL2 = URL(fileURLWithPath: originalTrack2.filePath)
        history.addEdit(originalTrack: originalTrack2, editedTrack: editedTrack2, fileURL: fileURL2)
        
        // Then - Should not be able to redo previous edit
        XCTAssertFalse(history.canRedo, "Should not be able to redo after new edit")
        XCTAssertTrue(history.canUndo, "Should be able to undo new edit")
    }
    
    // MARK: - Scenario: Clear History
    
    /// Scenario: As a user, I want to clear the undo/redo history
    /// Given: I have made several edits and undone some
    /// When: I clear the history
    /// Then: I should not be able to undo or redo anything
    func testUserClearsHistory() {
        // Given - History with edits
        let track1 = createTrack(title: "Original 1")
        let edited1 = createTrack(id: track1.id, title: "Edited 1")
        history.addEdit(originalTrack: track1, editedTrack: edited1, fileURL: URL(fileURLWithPath: track1.filePath))
        
        let track2 = createTrack(title: "Original 2", filePath: "/path/to/track2.mp3")
        let edited2 = createTrack(id: track2.id, title: "Edited 2", filePath: track2.filePath)
        history.addEdit(originalTrack: track2, editedTrack: edited2, fileURL: URL(fileURLWithPath: track2.filePath))
        
        _ = history.undo()
        XCTAssertTrue(history.canUndo, "Should be able to undo")
        XCTAssertTrue(history.canRedo, "Should be able to redo")
        
        // When - Clear history
        history.clear()
        
        // Then - Should not be able to undo or redo
        XCTAssertFalse(history.canUndo, "Should not be able to undo after clear")
        XCTAssertFalse(history.canRedo, "Should not be able to redo after clear")
    }
}
