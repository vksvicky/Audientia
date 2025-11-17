//
//  TagEditorViewModelTests.swift
//  UITests
//
//  TDD tests for TagEditorViewModel following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import MetadataEngine
@testable import Shared
import XCTest

// TagEditorViewModel is compiled into UITests target, no import needed

/// TDD tests for TagEditorViewModel
/// Following Right-BICEP: Right, Boundary, Inverse, Cross-check, Error, Performance
@MainActor
final class TagEditorViewModelTests: XCTestCase {
    
    fileprivate var viewModel: TagEditorViewModel!
    fileprivate var mockTagWriter: MockTagWriterCoordinator!
    fileprivate var mockValidator: MockTagValidator!
    fileprivate var mockHistory: MockTagEditHistory!
    
    override func setUp() async throws {
        try await super.setUp()
        mockTagWriter = MockTagWriterCoordinator()
        mockValidator = MockTagValidator()
        mockHistory = MockTagEditHistory()
        viewModel = TagEditorViewModel(
            tagWriter: mockTagWriter,
            validator: mockValidator,
            history: mockHistory
        )
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockTagWriter = nil
        mockValidator = nil
        mockHistory = nil
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createTrack(
        id: UUID = UUID(),
        title: String = "Test Title",
        artist: String = "Test Artist",
        album: String = "Test Album",
        filePath: String = "/path/to/track.mp3"
    ) -> Track {
        Track(
            id: id,
            title: title,
            artist: artist,
            album: album,
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
    
    /// Test loading a track for editing
    func testLoadTrackForEditing() async {
        // Given - A track
        let track = createTrack()
        let fileURL = URL(fileURLWithPath: track.filePath)
        
        // When - Load track for editing
        await viewModel.loadTrack(track: track, fileURL: fileURL)
        
        // Then - Track should be loaded
        XCTAssertEqual(viewModel.currentTrack?.id, track.id, "Current track should match loaded track")
        XCTAssertEqual(viewModel.editedTitle, track.title, "Edited title should match track title")
        XCTAssertEqual(viewModel.editedArtist, track.artist, "Edited artist should match track artist")
        XCTAssertEqual(viewModel.editedAlbum, track.album, "Edited album should match track album")
        XCTAssertEqual(viewModel.editedYear, track.year, "Edited year should match track year")
        XCTAssertEqual(viewModel.editedTrackNumber, track.trackNumber, "Edited track number should match")
        XCTAssertEqual(viewModel.editedDiscNumber, track.discNumber, "Edited disc number should match")
        XCTAssertEqual(viewModel.editedGenre, track.genre, "Edited genre should match track genre")
    }
    
    /// Test saving edited tags
    func testSaveEditedTags() async throws {
        // Given - A loaded track with edits
        let track = createTrack()
        let fileURL = URL(fileURLWithPath: track.filePath)
        await viewModel.loadTrack(track: track, fileURL: fileURL)
        
        viewModel.editedTitle = "New Title"
        viewModel.editedArtist = "New Artist"
        mockValidator.validationResult = TagValidationResult(isValid: true, errors: [])
        mockTagWriter.writeShouldSucceed = true
        
        // When - Save edits
        try await viewModel.save()
        
        // Then - Tags should be written
        XCTAssertTrue(mockTagWriter.writeCalled, "Tag writer should be called")
        XCTAssertEqual(mockTagWriter.lastWrittenTrack?.title, "New Title", "Written title should match edited title")
        XCTAssertEqual(mockTagWriter.lastWrittenTrack?.artist, "New Artist", "Written artist should match edited artist")
        XCTAssertTrue(mockHistory.recordEditCalled, "History should record the edit")
        XCTAssertNotNil(mockHistory.lastRecordedEdit, "History should have recorded edit")
    }
    
    // MARK: - Boundary Conditions
    
    /// Test editing with empty fields
    func testEditWithEmptyFields() async {
        // Given - A track with empty fields
        let track = createTrack(title: "", artist: "", album: "")
        let fileURL = URL(fileURLWithPath: track.filePath)
        
        // When - Load track
        await viewModel.loadTrack(track: track, fileURL: fileURL)
        
        // Then - Empty fields should be loaded
        XCTAssertEqual(viewModel.editedTitle, "", "Empty title should be loaded")
        XCTAssertEqual(viewModel.editedArtist, "", "Empty artist should be loaded")
        XCTAssertEqual(viewModel.editedAlbum, "", "Empty album should be loaded")
    }
    
    /// Test editing with very long fields
    func testEditWithVeryLongFields() async {
        // Given - A track with very long fields
        let longTitle = String(repeating: "A", count: 1000)
        let track = createTrack(title: longTitle)
        let fileURL = URL(fileURLWithPath: track.filePath)
        
        // When - Load track
        await viewModel.loadTrack(track: track, fileURL: fileURL)
        
        // Then - Long fields should be loaded
        XCTAssertEqual(viewModel.editedTitle, longTitle, "Long title should be loaded")
    }
    
    /// Test editing with nil optional fields
    func testEditWithNilOptionalFields() async {
        // Given - A track with nil optional fields
        let track = createTrack()
        let trackWithNils = Track(
            id: track.id,
            title: track.title,
            artist: track.artist,
            album: track.album,
            duration: track.duration,
            filePath: track.filePath,
            fileSize: track.fileSize,
            bitrate: track.bitrate,
            sampleRate: track.sampleRate,
            year: nil,
            trackNumber: nil,
            discNumber: nil,
            genre: nil
        )
        let fileURL = URL(fileURLWithPath: track.filePath)
        
        // When - Load track
        await viewModel.loadTrack(track: trackWithNils, fileURL: fileURL)
        
        // Then - Nil fields should be handled
        XCTAssertNil(viewModel.editedYear, "Nil year should be handled")
        XCTAssertNil(viewModel.editedTrackNumber, "Nil track number should be handled")
        XCTAssertNil(viewModel.editedDiscNumber, "Nil disc number should be handled")
        XCTAssertNil(viewModel.editedGenre, "Nil genre should be handled")
    }
    
    // MARK: - Inverse Relationships
    
    /// Test undo restores original values
    func testUndoRestoresOriginalValues() async throws {
        // Given - A track with edits and history
        let track = createTrack()
        let fileURL = URL(fileURLWithPath: track.filePath)
        await viewModel.loadTrack(track: track, fileURL: fileURL)
        
        viewModel.editedTitle = "Edited Title"
        mockValidator.validationResult = TagValidationResult(isValid: true, errors: [])
        mockTagWriter.writeShouldSucceed = true
        try await viewModel.save()
        
        // Setup history to return undo
        let originalEdit = TagEdit(
            originalTrack: track,
            editedTrack: createTrack(id: track.id, title: "Edited Title"),
            fileURL: fileURL
        )
        mockHistory.undoResult = originalEdit
        mockHistory.canUndoValue = true
        mockTagWriter.writeShouldSucceed = true
        
        // When - Undo
        try await viewModel.undo()
        
        // Then - Original values should be restored
        XCTAssertEqual(viewModel.editedTitle, track.title, "Undo should restore original title")
        XCTAssertTrue(mockTagWriter.writeCalled, "Tag writer should be called to restore original")
    }
    
    /// Test redo restores edited values
    func testRedoRestoresEditedValues() async throws {
        // Given - A track with undo performed
        let track = createTrack()
        let fileURL = URL(fileURLWithPath: track.filePath)
        await viewModel.loadTrack(track: track, fileURL: fileURL)
        
        viewModel.editedTitle = "Edited Title"
        mockValidator.validationResult = TagValidationResult(isValid: true, errors: [])
        mockTagWriter.writeShouldSucceed = true
        try await viewModel.save()
        
        // Undo first
        let originalEdit = TagEdit(
            originalTrack: track,
            editedTrack: createTrack(id: track.id, title: "Edited Title"),
            fileURL: fileURL
        )
        mockHistory.undoResult = originalEdit
        mockHistory.canUndoValue = true
        mockTagWriter.writeShouldSucceed = true
        try await viewModel.undo()
        
        // Setup redo
        mockHistory.redoResult = originalEdit
        mockHistory.canRedoValue = true
        mockTagWriter.writeShouldSucceed = true
        
        // When - Redo
        try await viewModel.redo()
        
        // Then - Edited values should be restored
        XCTAssertEqual(viewModel.editedTitle, "Edited Title", "Redo should restore edited title")
        XCTAssertTrue(mockTagWriter.writeCalled, "Tag writer should be called to restore edited values")
    }
    
    // MARK: - Error Conditions
    
    /// Test saving with validation errors
    func testSaveWithValidationErrors() async {
        // Given - A track with invalid data
        let track = createTrack()
        let fileURL = URL(fileURLWithPath: track.filePath)
        await viewModel.loadTrack(track: track, fileURL: fileURL)
        
        viewModel.editedYear = 1800 // Invalid year
        mockValidator.validationResult = TagValidationResult(
            isValid: false,
            errors: [.invalidYear(1800)]
        )
        
        // When/Then - Save should throw validation error
        do {
            try await viewModel.save()
            XCTFail("Should have thrown validation error")
        } catch {
            XCTAssertNotNil(viewModel.validationErrors, "Validation errors should be set")
            XCTAssertFalse(viewModel.validationErrors.isEmpty, "Should have validation errors")
        }
    }
    
    /// Test saving with write error
    func testSaveWithWriteError() async {
        // Given - A track with valid data but write fails
        let track = createTrack()
        let fileURL = URL(fileURLWithPath: track.filePath)
        await viewModel.loadTrack(track: track, fileURL: fileURL)
        
        mockValidator.validationResult = TagValidationResult(isValid: true, errors: [])
        mockTagWriter.writeShouldSucceed = false
        mockTagWriter.writeError = TagWriterError.fileNotFound(fileURL)
        
        // When/Then - Save should throw write error
        do {
            try await viewModel.save()
            XCTFail("Should have thrown write error")
        } catch {
            XCTAssertNotNil(viewModel.lastError, "Last error should be set")
        }
    }
    
    /// Test undo when no history available
    func testUndoWhenNoHistoryAvailable() async {
        // Given - No undo history
        mockHistory.canUndoValue = false
        
        // When/Then - Undo should not throw but do nothing
        do {
            try await viewModel.undo()
            // Should not throw, just do nothing
        } catch {
            XCTFail("Undo should not throw when no history available")
        }
    }
    
    // MARK: - Performance Characteristics
    
    /// Test save performance
    func testSavePerformance() async throws {
        // Given - A track
        let track = createTrack()
        let fileURL = URL(fileURLWithPath: track.filePath)
        await viewModel.loadTrack(track: track, fileURL: fileURL)
        
        mockValidator.validationResult = TagValidationResult(isValid: true, errors: [])
        mockTagWriter.writeShouldSucceed = true
        
        // When - Measure save performance
        let iterations = 10
        var times: [TimeInterval] = []
        
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            try await viewModel.save()
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            times.append(elapsed)
        }
        
        let average = times.reduce(0, +) / Double(times.count)
        print("Average save time: \(String(format: "%.2f", average * 1000))ms")
        
        // Then - Should complete quickly
        XCTAssertLessThan(average, 0.1, "Save should complete in reasonable time")
    }
}

// MARK: - Mock Classes

/// Mock TagWriterCoordinator for testing
private final class MockTagWriterCoordinator: TagWriterCoordinating, @unchecked Sendable {
    var canWriteValue = true
    var writeShouldSucceed = true
    var writeError: Error?
    var writeCalled = false
    var lastWrittenTrack: Track?
    var lastWrittenURL: URL?
    
    func canWrite(fileURL: URL) -> Bool {
        canWriteValue
    }
    
    func write(track: Track, to fileURL: URL) async throws {
        writeCalled = true
        lastWrittenTrack = track
        lastWrittenURL = fileURL
        if !writeShouldSucceed {
            throw writeError ?? TagWriterError.fileNotFound(fileURL)
        }
    }
    
    func update(track: Track, in fileURL: URL) async throws {
        writeCalled = true
        lastWrittenTrack = track
        lastWrittenURL = fileURL
        if !writeShouldSucceed {
            throw writeError ?? TagWriterError.fileNotFound(fileURL)
        }
    }
}

/// Mock TagValidator for testing
private final class MockTagValidator: TagValidatorProtocol, @unchecked Sendable {
    var validationResult = TagValidationResult(isValid: true, errors: [])
    
    func validate(track: Track) -> TagValidationResult {
        validationResult
    }
}

/// Mock TagEditHistory for testing
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
    
    func addEdit(originalTrack: Track, editedTrack: Track, fileURL: URL) {
        recordEditCalled = true
        lastRecordedEdit = TagEdit(originalTrack: originalTrack, editedTrack: editedTrack, fileURL: fileURL)
    }
}

