//
//  TagEditHistoryTests.swift
//  MetadataEngineTests
//
//  TDD tests for TagEditHistory following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// TDD tests for TagEditHistory
/// Following Right-BICEP: Right, Boundary, Inverse, Cross-check, Error, Performance
@MainActor
final class TagEditHistoryTests: XCTestCase {
    
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
    
    // MARK: - Right: Are the Results Right?
    
    /// Test adding an edit to history
    func testAddEditToHistory() {
        // Given - Track edit
        let originalTrack = createTrack()
        let editedTrack = createTrack(id: originalTrack.id, title: "Edited Title")
        let fileURL = URL(fileURLWithPath: originalTrack.filePath)
        
        // When - Add edit to history
        history.addEdit(originalTrack: originalTrack, editedTrack: editedTrack, fileURL: fileURL)
        
        // Then - History should contain the edit
        XCTAssertTrue(history.canUndo, "Should be able to undo")
        XCTAssertFalse(history.canRedo, "Should not be able to redo")
    }
    
    /// Test undoing an edit
    func testUndoEdit() {
        // Given - Track edit in history
        let originalTrack = createTrack()
        let editedTrack = createTrack(id: originalTrack.id, title: "Edited Title")
        let fileURL = URL(fileURLWithPath: originalTrack.filePath)
        history.addEdit(originalTrack: originalTrack, editedTrack: editedTrack, fileURL: fileURL)
        
        // When - Undo edit
        let undoEdit = history.undo()
        
        // Then - Should return the original track
        XCTAssertNotNil(undoEdit, "Should return undo edit")
        XCTAssertEqual(undoEdit?.originalTrack.id, originalTrack.id, "Should return original track")
        XCTAssertEqual(undoEdit?.originalTrack.title, originalTrack.title, "Should have original title")
        XCTAssertFalse(history.canUndo, "Should not be able to undo again")
        XCTAssertTrue(history.canRedo, "Should be able to redo")
    }
    
    /// Test redoing an undone edit
    func testRedoEdit() {
        // Given - Track edit that was undone
        let originalTrack = createTrack()
        let editedTrack = createTrack(id: originalTrack.id, title: "Edited Title")
        let fileURL = URL(fileURLWithPath: originalTrack.filePath)
        history.addEdit(originalTrack: originalTrack, editedTrack: editedTrack, fileURL: fileURL)
        _ = history.undo()
        
        // When - Redo edit
        let redoEdit = history.redo()
        
        // Then - Should return the edited track
        XCTAssertNotNil(redoEdit, "Should return redo edit")
        XCTAssertEqual(redoEdit?.editedTrack.id, editedTrack.id, "Should return edited track")
        XCTAssertEqual(redoEdit?.editedTrack.title, editedTrack.title, "Should have edited title")
        XCTAssertTrue(history.canUndo, "Should be able to undo again")
        XCTAssertFalse(history.canRedo, "Should not be able to redo again")
    }
    
    // MARK: - Boundary Conditions
    
    /// Test undoing when history is empty
    func testUndoWhenHistoryIsEmpty() {
        // Given - Empty history
        
        // When - Try to undo
        let undoEdit = history.undo()
        
        // Then - Should return nil
        XCTAssertNil(undoEdit, "Should return nil when history is empty")
        XCTAssertFalse(history.canUndo, "Should not be able to undo")
    }
    
    /// Test redoing when nothing to redo
    func testRedoWhenNothingToRedo() {
        // Given - History with no undone edits
        let originalTrack = createTrack()
        let editedTrack = createTrack(id: originalTrack.id, title: "Edited Title")
        let fileURL = URL(fileURLWithPath: originalTrack.filePath)
        history.addEdit(originalTrack: originalTrack, editedTrack: editedTrack, fileURL: fileURL)
        
        // When - Try to redo
        let redoEdit = history.redo()
        
        // Then - Should return nil
        XCTAssertNil(redoEdit, "Should return nil when nothing to redo")
        XCTAssertFalse(history.canRedo, "Should not be able to redo")
    }
    
    /// Test history size limit
    func testHistorySizeLimit() {
        // Given - History with max size 3
        let limitedHistory = TagEditHistory(maxHistorySize: 3)
        
        // When - Add more edits than limit
        for i in 0..<5 {
            let originalTrack = createTrack(title: "Original \(i)")
            let editedTrack = createTrack(id: originalTrack.id, title: "Edited \(i)")
            let fileURL = URL(fileURLWithPath: "/path/to/track\(i).mp3")
            limitedHistory.addEdit(originalTrack: originalTrack, editedTrack: editedTrack, fileURL: fileURL)
        }
        
        // Then - History should only contain last 3 edits
        // Undo 3 times should work, but 4th should fail
        var undoCount = 0
        while limitedHistory.canUndo {
            _ = limitedHistory.undo()
            undoCount += 1
        }
        XCTAssertEqual(undoCount, 3, "Should only be able to undo 3 times (history limit)")
    }
    
    // MARK: - Inverse Relationships
    
    /// Test undo then redo roundtrip
    func testUndoRedoRoundtrip() {
        // Given - Track edit
        let originalTrack = createTrack()
        let editedTrack = createTrack(id: originalTrack.id, title: "Edited Title")
        let fileURL = URL(fileURLWithPath: originalTrack.filePath)
        history.addEdit(originalTrack: originalTrack, editedTrack: editedTrack, fileURL: fileURL)
        
        // When - Undo then redo
        let undoEdit = history.undo()
        let redoEdit = history.redo()
        
        // Then - Should return correct tracks
        XCTAssertNotNil(undoEdit, "Should return undo edit")
        XCTAssertNotNil(redoEdit, "Should return redo edit")
        XCTAssertEqual(undoEdit?.originalTrack.title, originalTrack.title, "Undo should return original")
        XCTAssertEqual(redoEdit?.editedTrack.title, editedTrack.title, "Redo should return edited")
    }
    
    // MARK: - Error Conditions
    
    /// Test adding edit after undo clears redo stack
    func testAddEditAfterUndoClearsRedoStack() {
        // Given - Track edit that was undone
        let originalTrack1 = createTrack()
        let editedTrack1 = createTrack(id: originalTrack1.id, title: "Edited 1")
        let fileURL1 = URL(fileURLWithPath: originalTrack1.filePath)
        history.addEdit(originalTrack: originalTrack1, editedTrack: editedTrack1, fileURL: fileURL1)
        _ = history.undo()
        XCTAssertTrue(history.canRedo, "Should be able to redo")
        
        // When - Add new edit
        let originalTrack2 = createTrack()
        let editedTrack2 = createTrack(id: originalTrack2.id, title: "Edited 2")
        let fileURL2 = URL(fileURLWithPath: originalTrack2.filePath)
        history.addEdit(originalTrack: originalTrack2, editedTrack: editedTrack2, fileURL: fileURL2)
        
        // Then - Redo stack should be cleared
        XCTAssertFalse(history.canRedo, "Should not be able to redo after new edit")
        XCTAssertTrue(history.canUndo, "Should be able to undo new edit")
    }
    
    // MARK: - Performance Characteristics
    
    /// Test history performance with many edits
    func testHistoryPerformanceWithManyEdits() {
        // Given - Many edits
        let edits = (0..<1000).map { index in
            let originalTrack = createTrack(title: "Original \(index)")
            let editedTrack = createTrack(id: originalTrack.id, title: "Edited \(index)")
            let fileURL = URL(fileURLWithPath: "/path/to/track\(index).mp3")
            return (originalTrack, editedTrack, fileURL)
        }
        
        measure {
            // When - Add all edits
            for (original, edited, url) in edits {
                history.addEdit(originalTrack: original, editedTrack: edited, fileURL: url)
            }
        }
    }
    
    // MARK: - Edge Cases
    
    /// Test clearing history
    func testClearHistory() {
        // Given - History with edits
        let originalTrack = createTrack()
        let editedTrack = createTrack(id: originalTrack.id, title: "Edited Title")
        let fileURL = URL(fileURLWithPath: originalTrack.filePath)
        history.addEdit(originalTrack: originalTrack, editedTrack: editedTrack, fileURL: fileURL)
        XCTAssertTrue(history.canUndo, "Should be able to undo")
        
        // When - Clear history
        history.clear()
        
        // Then - History should be empty
        XCTAssertFalse(history.canUndo, "Should not be able to undo after clear")
        XCTAssertFalse(history.canRedo, "Should not be able to redo after clear")
    }
    
    /// Test multiple undo/redo operations
    func testMultipleUndoRedoOperations() {
        // Given - Multiple edits
        _ = (0..<5).map { index in
            let original = createTrack(title: "Original \(index)")
            let edited = createTrack(id: original.id, title: "Edited \(index)")
            let url = URL(fileURLWithPath: "/path/to/track\(index).mp3")
            history.addEdit(originalTrack: original, editedTrack: edited, fileURL: url)
            return (original, edited, url)
        }
        
        // When - Undo all, then redo all
        var undoResults: [TagEdit?] = []
        while history.canUndo {
            undoResults.append(history.undo())
        }
        
        var redoResults: [TagEdit?] = []
        while history.canRedo {
            redoResults.append(history.redo())
        }
        
        // Then - Should have correct number of operations
        XCTAssertEqual(undoResults.count, 5, "Should undo 5 times")
        XCTAssertEqual(redoResults.count, 5, "Should redo 5 times")
    }
}
