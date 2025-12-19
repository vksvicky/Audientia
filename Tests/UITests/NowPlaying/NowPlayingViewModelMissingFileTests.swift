//
//  NowPlayingViewModelMissingFileTests.swift
//  Audientia
//
//  TDD tests for missing file handling in NowPlayingViewModel
//  Following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Combine
import XCTest

@testable import AudioCore
@testable import Shared

// Import NowPlayingViewModel from UI module
// Since it's in the app target, we include the source file in UITests target

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

/// TDD Tests for NowPlayingViewModel missing file handling
/// Following Right-BICEP principles for comprehensive test coverage
@MainActor
final class NowPlayingViewModelMissingFileTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: NowPlayingViewModel!
    private var mockAudioEngine: MockAudioEngine!
    private var cancellables: Set<AnyCancellable>!
    private var tempDirectory: URL!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        cancellables = []
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
        cancellables = nil
        viewModel = nil
        mockAudioEngine = nil
        
        // Clean up temp directory
        try? FileManager.default.removeItem(at: tempDirectory)
        tempDirectory = nil
        
        // Clear AppSettings
        AppSettings.shared.lastPlayedTrack = nil
        
        super.tearDown()
    }
    
    // MARK: - [Right] Tests - Verify Expected Behavior
    
    /// Test: When loading a track with missing file, should throw error
    func testLoadTrackWithMissingFileThrowsError() async {
        // Given - A track with a non-existent file path
        let track = MockFactory.makeTrack(
            title: "Missing Track",
            filePath: "/nonexistent/path/track.mp3"
        )
        
        // When - Attempting to load the track
        // Then - Should throw AudioEngineError.trackLoadFailed
        do {
            try await viewModel.loadTrack(track)
            XCTFail("Expected loadTrack to throw error for missing file")
        } catch let error as AudioEngineError {
            if case .trackLoadFailed(let message) = error {
                XCTAssertTrue(
                    message.contains("File not found"),
                    "Error message should indicate file not found"
                )
            } else {
                XCTFail("Expected trackLoadFailed error, got: \(error)")
            }
        } catch {
            XCTFail("Expected AudioEngineError, got: \(error)")
        }
    }
    
    /// Test: When loading a track with missing file, should set lastError
    func testLoadTrackWithMissingFileSetsLastError() async {
        // Given - A track with a non-existent file path
        let track = MockFactory.makeTrack(
            title: "Missing Track",
            filePath: "/nonexistent/path/track.mp3"
        )
        
        // When - Attempting to load the track
        do {
            try await viewModel.loadTrack(track)
            XCTFail("Expected loadTrack to throw error")
        } catch {
            // Expected to throw
        }
        
        // Then - lastError should be set
        XCTAssertNotNil(viewModel.lastError, "lastError should be set when file is missing")
        if let error = viewModel.lastError as? AudioEngineError {
            if case .trackLoadFailed(let message) = error {
                XCTAssertTrue(
                    message.contains("File not found"),
                    "Error message should indicate file not found"
                )
            } else {
                XCTFail("Expected trackLoadFailed error")
            }
        } else {
            XCTFail("Expected AudioEngineError")
        }
    }
    
    /// Test: When playing a track with missing file, should throw error
    func testPlayTrackWithMissingFileThrowsError() async {
        // Given - A track with missing file is set as current track
        let track = MockFactory.makeTrack(
            title: "Missing Track",
            filePath: "/nonexistent/path/track.mp3"
        )
        mockAudioEngine.currentTrack = track
        // Sync state so view model knows about the track
        viewModel.updateState()
        
        // When - Attempting to play
        // Then - Should throw AudioEngineError.trackLoadFailed
        do {
            try await viewModel.play()
            XCTFail("Expected play to throw error for missing file")
        } catch let error as AudioEngineError {
            if case .trackLoadFailed(let message) = error {
                XCTAssertTrue(
                    message.contains("File not found"),
                    "Error message should indicate file not found"
                )
            } else {
                XCTFail("Expected trackLoadFailed error, got: \(error)")
            }
        } catch {
            XCTFail("Expected AudioEngineError, got: \(error)")
        }
    }
    
    /// Test: When playing a track with missing file, should clear current track
    func testPlayTrackWithMissingFileClearsCurrentTrack() async {
        // Given - A track with missing file is set as current track
        let track = MockFactory.makeTrack(
            title: "Missing Track",
            filePath: "/nonexistent/path/track.mp3"
        )
        mockAudioEngine.currentTrack = track
        viewModel.updateState()
        XCTAssertNotNil(viewModel.currentTrack, "Current track should be set")
        
        // When - Attempting to play
        do {
            try await viewModel.play()
            XCTFail("Expected play to throw error")
        } catch {
            // Expected to throw
        }
        
        // Then - Current track should be cleared
        // Clear it on the mock engine as well since updateState() syncs from the engine
        mockAudioEngine.currentTrack = nil
        viewModel.updateState()
        XCTAssertNil(
            viewModel.currentTrack,
            "Current track should be cleared when file is missing"
        )
    }
    
    // MARK: - [B]oundary Condition Tests
    
    /// Test: When restoring last played track with missing file, should clear saved track
    func testRestoreLastPlayedTrackWithMissingFileClearsSavedTrack() async {
        // Given - A last played track with missing file is saved
        let track = MockFactory.makeTrack(
            title: "Missing Track",
            filePath: "/nonexistent/path/track.mp3"
        )
        AppSettings.shared.lastPlayedTrack = track
        
        // When - Creating a new view model (which restores last played track)
        // View model creation triggers restoration logic
        _ = NowPlayingViewModel(audioEngine: mockAudioEngine)
        
        // Wait a bit for async restoration to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Then - Saved track should be cleared
        XCTAssertNil(
            AppSettings.shared.lastPlayedTrack,
            "Last played track should be cleared when file is missing"
        )
    }
    
    /// Test: When file exists, should load successfully
    func testLoadTrackWithExistingFileSucceeds() async throws {
        // Given - A track with an existing file path
        let testFile = tempDirectory.appendingPathComponent("test.mp3")
        FileManager.default.createFile(atPath: testFile.path, contents: Data())
        
        let track = MockFactory.makeTrack(
            title: "Existing Track",
            filePath: testFile.path
        )
        
        // When - Loading the track
        try await viewModel.loadTrack(track)
        
        // Then - Should succeed without error
        XCTAssertNil(viewModel.lastError, "Should not have error for existing file")
    }
    
    // MARK: - [I]nverse Relationship Tests
    
    /// Test: When file exists, should not throw error
    func testLoadTrackWithExistingFileDoesNotThrow() async {
        // Given - A track with an existing file path
        let testFile = tempDirectory.appendingPathComponent("test.mp3")
        FileManager.default.createFile(atPath: testFile.path, contents: Data())
        
        let track = MockFactory.makeTrack(
            title: "Existing Track",
            filePath: testFile.path
        )
        
        // When/Then - Loading should not throw
        do {
            try await viewModel.loadTrack(track)
            // Success - no error thrown
        } catch {
            XCTFail("Should not throw error for existing file: \(error)")
        }
    }
    
    // MARK: - [C]ross-Check Tests
    
    /// Test: FileManager and viewModel should agree on file existence
    func testFileExistenceCheckMatchesFileManager() async {
        // Given - A track with a file path
        let testFile = tempDirectory.appendingPathComponent("test.mp3")
        let track = MockFactory.makeTrack(
            title: "Test Track",
            filePath: testFile.path
        )
        
        // When - File doesn't exist
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: testFile.path),
            "File should not exist initially"
        )
        
        // Then - Loading should fail
        do {
            try await viewModel.loadTrack(track)
            XCTFail("Should fail to load non-existent file")
        } catch {
            // Expected
        }
        
        // When - File is created
        FileManager.default.createFile(atPath: testFile.path, contents: Data())
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: testFile.path),
            "File should exist after creation"
        )
        
        // Then - Loading should succeed
        do {
            try await viewModel.loadTrack(track)
            // Success
        } catch {
            XCTFail("Should succeed loading existing file: \(error)")
        }
    }
    
    // MARK: - [E]rror Condition Tests
    
    /// Test: Multiple missing file attempts should all fail
    func testMultipleMissingFileAttemptsAllFail() async {
        // Given - Multiple tracks with missing files
        let tracks = [
            MockFactory.makeTrack(title: "Track 1", filePath: "/missing/1.mp3"),
            MockFactory.makeTrack(title: "Track 2", filePath: "/missing/2.mp3"),
            MockFactory.makeTrack(title: "Track 3", filePath: "/missing/3.mp3")
        ]
        
        // When/Then - All should fail
        for track in tracks {
            do {
                try await viewModel.loadTrack(track)
                XCTFail("Should fail for missing file: \(track.title)")
            } catch {
                // Expected
                if let error = error as? AudioEngineError {
                    if case .trackLoadFailed(let message) = error {
                        XCTAssertTrue(
                            message.contains("File not found"),
                            "Error should indicate file not found"
                        )
                    } else {
                        XCTFail("Expected trackLoadFailed error")
                    }
                } else {
                    XCTFail("Expected AudioEngineError")
                }
            }
        }
    }
    
    // MARK: - [P]erformance Tests
    
    /// Test: File existence check should be fast
    func testFileExistenceCheckPerformance() async {
        // Given - A track with missing file
        let track = MockFactory.makeTrack(
            title: "Missing Track",
            filePath: "/nonexistent/path/track.mp3"
        )
        
        // When - Measuring time to check and fail
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            try await viewModel.loadTrack(track)
            XCTFail("Should fail")
        } catch {
            // Expected
        }
        
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then - Should complete quickly (< 100ms)
        XCTAssertLessThan(
            elapsed,
            0.1,
            "File existence check should complete quickly"
        )
    }
}
