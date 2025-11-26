//
//  TrackImportCoordinatorBDDTests.swift
//  AudientiaUITests
//
//  BDD scenarios for track import workflow
//

import AudioCore
import DataLayer
import Foundation
import Shared
import XCTest

@testable import Audientia

@MainActor
final class TrackImportCoordinatorBDDTests: XCTestCase {
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

    func testAsAUserIWantToImportAudioFilesAndPlayThem() async throws {
        // Given: I have audio files on my computer
        let urls = [
            URL(fileURLWithPath: "/tmp/song1.mp3"),
            URL(fileURLWithPath: "/tmp/song2.flac")
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

        // When: I import the files
        try await coordinator.importFiles(urls: urls)

        // Then: The files should be queued for playback
        XCTAssertEqual(mockAudioEngine.queue.count, 2)
        XCTAssertTrue(mockAudioEngine.queue.contains { $0.filePath.contains("song1") })
        XCTAssertTrue(mockAudioEngine.queue.contains { $0.filePath.contains("song2") })
    }

    func testAsAUserIWantToSeeAnErrorWhenImportingUnsupportedFiles() async {
        // Given: I try to import a PDF file
        let url = URL(fileURLWithPath: "/tmp/document.pdf")
        FileManager.default.createFile(atPath: url.path, contents: Data("pdf content".utf8), attributes: nil)
        defer { try? FileManager.default.removeItem(at: url) }

        // When: I attempt to import it
        // Then: I should see a clear error message
        do {
            try await coordinator.importFile(url: url)
            XCTFail("Should have thrown error for unsupported format")
        } catch let error as TrackImportError {
            XCTAssertEqual(error, .unsupportedFormat)
            XCTAssertFalse(error.localizedDescription.isEmpty)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testAsAUserIWantToDragAndDropFilesToPlayThem() async throws {
        // Given: I drag audio files onto the app
        let urls = [
            URL(fileURLWithPath: "/tmp/drag1.mp3"),
            URL(fileURLWithPath: "/tmp/drag2.m4a")
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

        // When: I drop them
        try await coordinator.importFiles(urls: urls)

        // Then: They should be queued and ready to play
        XCTAssertEqual(mockAudioEngine.queue.count, 2)
    }
}
