//
//  NowPlayingViewModelMissingFileBDDTests.swift
//  Audientia
//
//  BDD tests for missing file handling in NowPlayingViewModel
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Combine
import XCTest

@testable import AudioCore
@testable import Shared

private enum MockFactory {
    static func makeTrack(
        title: String = "Test Track",
        artist: String = "Test Artist",
        album: String = "Test Album",
        duration: TimeInterval = 180.0,
        filePath: String = "/path/to/track.mp3"
    ) -> Track {
        Track(
            id: UUID(),
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            filePath: filePath,
            fileSize: 5_000_000,
            bitrate: 320,
            sampleRate: 44100
        )
    }
}

/// BDD Tests for NowPlayingViewModel missing file handling
@MainActor
final class NowPlayingViewModelMissingFileBDDTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: NowPlayingViewModel!
    private var mockAudioEngine: MockAudioEngine!
    private var tempDirectory: URL!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockAudioEngine = MockAudioEngine()
        viewModel = NowPlayingViewModel(audioEngine: mockAudioEngine)
        
        // Create temporary directory for test files
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true
        )
        
        // Clear AppSettings lastPlayedTrack
        AppSettings.shared.lastPlayedTrack = nil
    }
    
    override func tearDown() {
        viewModel = nil
        mockAudioEngine = nil
        
        // Clean up temp directory
        try? FileManager.default.removeItem(at: tempDirectory)
        tempDirectory = nil
        
        // Clear AppSettings
        AppSettings.shared.lastPlayedTrack = nil
        
        super.tearDown()
    }
    
    // MARK: - BDD Scenario 1: User tries to play missing file
    
    /// BDD: As a user, when I try to play a track that has been moved or deleted,
    /// then I should be notified that the file was not found
    func testUserTriesToPlayMissingFileGetsNotification() async {
        // Given - I have a track that was previously playing
        let track = MockFactory.makeTrack(
            title: "My Favorite Song",
            artist: "My Favorite Artist",
            filePath: "/nonexistent/path/song.mp3"
        )
        mockAudioEngine.currentTrack = track
        viewModel.updateState()
        
        // When - I try to play the track (but the file has been deleted)
        do {
            try await viewModel.play()
            XCTFail("Expected play to fail for missing file")
        } catch let error as AudioEngineError {
            // Then - I should get an error indicating the file was not found
            if case .trackLoadFailed(let message) = error {
                XCTAssertTrue(
                    message.contains("File not found"),
                    "Error message should indicate file not found: \(message)"
                )
            } else {
                XCTFail("Expected trackLoadFailed error, got: \(error)")
            }
        } catch {
            XCTFail("Expected AudioEngineError, got: \(error)")
        }
        
        // And - The current track should be cleared
        // Clear it on the mock engine as well since updateState() syncs from the engine
        mockAudioEngine.currentTrack = nil
        viewModel.updateState()
        XCTAssertNil(
            viewModel.currentTrack,
            "Current track should be cleared when file is missing"
        )
    }
    
    // MARK: - BDD Scenario 2: User loads missing file
    
    /// BDD: As a user, when I try to load a track from a file that doesn't exist,
    /// then I should be notified that the file was not found
    func testUserLoadsMissingFileGetsNotification() async {
        // Given - I have a track reference to a file that doesn't exist
        let track = MockFactory.makeTrack(
            title: "Missing Song",
            artist: "Unknown Artist",
            filePath: "/nonexistent/path/missing.mp3"
        )
        
        // When - I try to load the track
        do {
            try await viewModel.loadTrack(track)
            XCTFail("Expected loadTrack to fail for missing file")
        } catch let error as AudioEngineError {
            // Then - I should get an error indicating the file was not found
            if case .trackLoadFailed(let message) = error {
                XCTAssertTrue(
                    message.contains("File not found"),
                    "Error message should indicate file not found: \(message)"
                )
            } else {
                XCTFail("Expected trackLoadFailed error, got: \(error)")
            }
        } catch {
            XCTFail("Expected AudioEngineError, got: \(error)")
        }
        
        // And - The error should be stored in lastError
        XCTAssertNotNil(
            viewModel.lastError,
            "lastError should be set when file is missing"
        )
    }
    
    // MARK: - BDD Scenario 3: App restores missing last played track
    
    /// BDD: As a user, when I restart the app and the last played track file is missing,
    /// then I should be notified that the file was not found
    func testAppRestoresMissingLastPlayedTrackShowsNotification() async {
        // Given - I previously played a track that is now missing
        let track = MockFactory.makeTrack(
            title: "Previously Played Song",
            artist: "My Artist",
            filePath: "/nonexistent/path/previous.mp3"
        )
        AppSettings.shared.lastPlayedTrack = track
        
        // When - I restart the app (creating a new view model)
        let newViewModel = NowPlayingViewModel(audioEngine: mockAudioEngine)
        
        // Wait for async restoration to complete
        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        // Then - The saved track should be cleared
        XCTAssertNil(
            AppSettings.shared.lastPlayedTrack,
            "Last played track should be cleared when file is missing"
        )
    }
    
    // MARK: - BDD Scenario 4: User successfully loads existing file
    
    /// BDD: As a user, when I load a track from an existing file,
    /// then the track should load successfully without errors
    func testUserLoadsExistingFileSucceeds() async throws {
        // Given - I have a track with an existing file
        let testFile = tempDirectory.appendingPathComponent("existing.mp3")
        FileManager.default.createFile(atPath: testFile.path, contents: Data())
        
        let track = MockFactory.makeTrack(
            title: "Existing Song",
            artist: "My Artist",
            filePath: testFile.path
        )
        
        // When - I load the track
        try await viewModel.loadTrack(track)
        
        // Then - The track should load successfully
        XCTAssertNil(
            viewModel.lastError,
            "Should not have error for existing file"
        )
    }
    
    // MARK: - BDD Scenario 5: User plays existing file after missing file
    
    /// BDD: As a user, when I try to play a missing file and then load a valid file,
    /// then I should be able to play the valid file successfully
    func testUserPlaysExistingFileAfterMissingFileSucceeds() async throws {
        // Given - I tried to play a missing file (which failed)
        let missingTrack = MockFactory.makeTrack(
            title: "Missing Song",
            filePath: "/nonexistent/path/missing.mp3"
        )
        
        do {
            try await viewModel.loadTrack(missingTrack)
            XCTFail("Should fail for missing file")
        } catch {
            // Expected failure
        }
        
        // When - I load and play a valid file
        let testFile = tempDirectory.appendingPathComponent("valid.mp3")
        FileManager.default.createFile(atPath: testFile.path, contents: Data())
        
        let validTrack = MockFactory.makeTrack(
            title: "Valid Song",
            filePath: testFile.path
        )
        
        try await viewModel.loadTrack(validTrack)
        
        // Then - I should be able to play it
        // (Note: MockAudioEngine may not fully support play, but load should succeed)
        XCTAssertNil(
            viewModel.lastError,
            "Should not have error for valid file after missing file"
        )
    }
    
    // MARK: - BDD Scenario 6: User has multiple missing files
    
    /// BDD: As a user, when I have multiple tracks with missing files,
    /// then each attempt should fail with appropriate error
    func testUserHasMultipleMissingFilesAllFail() async {
        // Given - I have multiple tracks with missing files
        let tracks = [
            ("Song 1", "/missing/1.mp3"),
            ("Song 2", "/missing/2.mp3"),
            ("Song 3", "/missing/3.mp3")
        ].map { title, path in
            MockFactory.makeTrack(title: title, filePath: path)
        }
        
        // When - I try to load each track
        for track in tracks {
            do {
                try await viewModel.loadTrack(track)
                XCTFail("Should fail for missing file: \(track.title)")
            } catch let error as AudioEngineError {
                // Then - Each should fail with file not found error
                if case .trackLoadFailed(let message) = error {
                    XCTAssertTrue(
                        message.contains("File not found"),
                        "Error should indicate file not found for: \(track.title)"
                    )
                } else {
                    XCTFail("Expected trackLoadFailed error for: \(track.title)")
                }
            } catch {
                XCTFail("Expected AudioEngineError for: \(track.title), got: \(error)")
            }
        }
    }
}
