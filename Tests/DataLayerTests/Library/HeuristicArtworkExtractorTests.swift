//
//  HeuristicArtworkExtractorTests.swift
//  DataLayerTests
//

@testable import DataLayer
import Foundation
@testable import Shared
import XCTest

final class HeuristicArtworkExtractorTests: XCTestCase {
    var extractor: HeuristicArtworkExtractor!
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        extractor = HeuristicArtworkExtractor()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        extractor = nil
        tempDirectory = nil
        super.tearDown()
    }

    func testExtractsArtworkFromMatchingBasename() async throws {
        let audioURL = tempDirectory.appendingPathComponent("song.mp3")
        FileManager.default.createFile(atPath: audioURL.path, contents: Data(), attributes: nil)
        let imageData = Data([0x89, 0x50, 0x4E, 0x47])
        let artworkURL = tempDirectory.appendingPathComponent("song.png")
        FileManager.default.createFile(atPath: artworkURL.path, contents: imageData, attributes: nil)

        let track = Track(
            title: "Song",
            artist: "Artist",
            album: "Album",
            duration: 120,
            filePath: audioURL.path,
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44_100
        )

        let artwork = await extractor.extractArtwork(for: track)
        XCTAssertEqual(artwork?.data, imageData)
        XCTAssertEqual(artwork?.mimeType, "image/png")
    }

    func testSkipsFilesLargerThanLimit() async throws {
        let audioURL = tempDirectory.appendingPathComponent("song.mp3")
        FileManager.default.createFile(atPath: audioURL.path, contents: Data(), attributes: nil)
        let hugeData = Data(repeating: 0x00, count: 3 * 1024 * 1024)
        let artworkURL = tempDirectory.appendingPathComponent("cover.jpg")
        FileManager.default.createFile(atPath: artworkURL.path, contents: hugeData, attributes: nil)

        let track = Track(
            title: "Song",
            artist: "Artist",
            album: "Album",
            duration: 120,
            filePath: audioURL.path,
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44_100
        )

        let artwork = await extractor.extractArtwork(for: track)
        XCTAssertNil(artwork)
    }

    func testFallsBackToGenericCoverNames() async throws {
        let audioURL = tempDirectory.appendingPathComponent("song.mp3")
        FileManager.default.createFile(atPath: audioURL.path, contents: Data(), attributes: nil)
        let imageData = Data([0xFF, 0xD8, 0xFF])
        let artworkURL = tempDirectory.appendingPathComponent("cover.jpg")
        FileManager.default.createFile(atPath: artworkURL.path, contents: imageData, attributes: nil)

        let track = Track(
            title: "Song",
            artist: "Artist",
            album: "Album",
            duration: 120,
            filePath: audioURL.path,
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44_100
        )

        let artwork = await extractor.extractArtwork(for: track)
        XCTAssertNotNil(artwork)
        XCTAssertEqual(artwork?.mimeType, "image/jpeg")
    }
}
