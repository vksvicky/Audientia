//
//  TrackImportCoordinatorTests.swift
//  AudientiaUITests
//
//  TDD tests for TrackImportCoordinator following Right-BICEP
//

import AudioCore
import DataLayer
import Foundation
import Shared
import XCTest

@testable import Audientia

@MainActor
final class TrackImportCoordinatorTests: XCTestCase {
    var coordinator: TrackImportCoordinator!
    var mockAudioEngine: MockAudioEngine!
    var mockIndexer: MockLibraryIndexer!

    override func setUp() {
        super.setUp()
        mockAudioEngine = MockAudioEngine()
        mockIndexer = MockLibraryIndexer()
        coordinator = TrackImportCoordinator(
            audioEngine: mockAudioEngine,
            indexer: mockIndexer
        )
    }

    override func tearDown() {
        coordinator = nil
        mockAudioEngine = nil
        mockIndexer = nil
        super.tearDown()
    }

    // MARK: - Right Results

    func testImportValidAudioFile() async throws {
        // Given: A valid audio file URL
        let url = URL(fileURLWithPath: "/tmp/test.mp3")
        // Create a temporary file for testing
        FileManager.default.createFile(atPath: url.path, contents: Data("fake mp3 data".utf8), attributes: nil)
        defer { try? FileManager.default.removeItem(at: url) }

        // When: Importing the file
        try await coordinator.importFile(url: url)

        // Then: Track should be queued in audio engine
        let queuedTrack = mockAudioEngine.queue.first { $0.filePath == url.path }
        XCTAssertNotNil(queuedTrack)
    }

    func testImportMultipleValidFiles() async throws {
        // Given: Multiple valid audio files
        let urls = [
            URL(fileURLWithPath: "/tmp/track1.mp3"),
            URL(fileURLWithPath: "/tmp/track2.flac"),
            URL(fileURLWithPath: "/tmp/track3.m4a")
        ]
        // Create temporary files
        for url in urls {
            FileManager.default.createFile(atPath: url.path, contents: Data("fake audio".utf8), attributes: nil)
        }
        defer {
            for url in urls {
                try? FileManager.default.removeItem(at: url)
            }
        }

        // When: Importing all files
        try await coordinator.importFiles(urls: urls)

        // Then: All tracks should be queued
        XCTAssertEqual(mockAudioEngine.queue.count, 3)
    }

    // MARK: - Boundary Conditions

    func testImportUnsupportedFileFormat() async {
        // Given: An unsupported file format
        let url = URL(fileURLWithPath: "/tmp/document.pdf")
        FileManager.default.createFile(atPath: url.path, contents: Data("pdf content".utf8), attributes: nil)
        defer { try? FileManager.default.removeItem(at: url) }

        // When: Importing the file
        // Then: Should throw unsupported format error
        do {
            try await coordinator.importFile(url: url)
            XCTFail("Should have thrown unsupported format error")
        } catch let error as TrackImportError {
            XCTAssertEqual(error, .unsupportedFormat)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testImportEmptyFileList() async throws {
        // Given: Empty file list
        let urls: [URL] = []

        // When: Importing files
        try await coordinator.importFiles(urls: urls)

        // Then: Queue should remain empty
        XCTAssertTrue(mockAudioEngine.queue.isEmpty)
    }

    func testImportMixedValidAndInvalidFiles() async {
        // Given: Mix of valid and invalid files
        let urls = [
            URL(fileURLWithPath: "/tmp/track1.mp3"),
            URL(fileURLWithPath: "/tmp/document.pdf"),
            URL(fileURLWithPath: "/tmp/track2.flac")
        ]
        // Create temporary files
        for url in urls {
            FileManager.default.createFile(atPath: url.path, contents: Data("content".utf8), attributes: nil)
        }
        defer {
            for url in urls {
                try? FileManager.default.removeItem(at: url)
            }
        }

        // When: Importing files
        // Then: Should throw error for invalid file
        do {
            try await coordinator.importFiles(urls: urls)
            XCTFail("Should have thrown error for invalid file")
        } catch let error as TrackImportError {
            XCTAssertEqual(error, .unsupportedFormat)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Inverse Relationships

    func testImportThenRemoveFromQueue() async throws {
        // Given: An imported track
        let url = URL(fileURLWithPath: "/tmp/test.mp3")
        FileManager.default.createFile(atPath: url.path, contents: Data("fake mp3".utf8), attributes: nil)
        defer { try? FileManager.default.removeItem(at: url) }

        try await coordinator.importFile(url: url)
        let track = mockAudioEngine.queue.first!

        // When: Removing from queue
        mockAudioEngine.removeFromQueue(track)

        // Then: Track should be removed
        XCTAssertFalse(mockAudioEngine.queue.contains { $0.id == track.id })
    }

    // MARK: - Cross-Checking

    func testImportValidatesFormatBeforeQueueing() async throws {
        // Given: A file with valid extension but invalid content
        let url = URL(fileURLWithPath: "/tmp/fake.mp3")
        FileManager.default.createFile(atPath: url.path, contents: Data("fake content".utf8), attributes: nil)
        defer { try? FileManager.default.removeItem(at: url) }

        // When: Importing
        try await coordinator.importFile(url: url)

        // Then: Should validate extension and queue (format validation passes on extension)
        XCTAssertTrue(mockAudioEngine.queue.contains { $0.filePath == url.path })
    }

    // MARK: - Error Conditions

    func testImportNonExistentFile() async {
        // Given: A non-existent file URL
        let url = URL(fileURLWithPath: "/nonexistent/track.mp3")

        // When: Importing
        // Then: Should throw file not found error
        do {
            try await coordinator.importFile(url: url)
            XCTFail("Should have thrown file not found error")
        } catch let error as TrackImportError {
            XCTAssertEqual(error, .fileNotFound)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Performance

    func testImportManyFilesPerformance() throws {
        // Given: Many valid files
        let urls = (0..<100).map { URL(fileURLWithPath: "/tmp/track\($0).mp3") }
        // Create temporary files
        for url in urls {
            FileManager.default.createFile(atPath: url.path, contents: Data("fake audio".utf8), attributes: nil)
        }
        defer {
            for url in urls {
                try? FileManager.default.removeItem(at: url)
            }
        }

        // When: Importing all files
        measure(metrics: [XCTClockMetric()]) {
            let exp = expectation(description: "import")
            Task {
                try? await coordinator.importFiles(urls: urls)
                exp.fulfill()
            }
            wait(for: [exp], timeout: 5.0)
        }
    }

}

