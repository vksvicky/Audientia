//
//  MetadataNormaliserTests.swift
//  DataLayerTests
//

@testable import DataLayer
import Foundation
@testable import Shared
import XCTest

final class MetadataNormaliserTests: XCTestCase {
    var normaliser: MetadataNormaliser!

    override func setUp() {
        super.setUp()
        normaliser = MetadataNormaliser()
    }

    override func tearDown() {
        normaliser = nil
        super.tearDown()
    }

    func testTrimsAndCollapsesWhitespaceInTitleAndAlbum() {
        let original = Track(
            title: "  15  Step ",
            artist: "Radiohead",
            album: "  In   Rainbows  ",
            duration: 240,
            filePath: "/tmp/a.mp3",
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100
        )

        let normalized = normaliser.normalize(track: original)

        XCTAssertEqual(normalized.title, "15 Step")
        XCTAssertEqual(normalized.album, "In Rainbows")
    }

    func testNormalizesLowercasedArtistName() {
        let original = Track(
            title: "Everything In Its Right Place",
            artist: "radiohead",
            album: "Kid A",
            duration: 250,
            filePath: "/tmp/b.mp3",
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100
        )

        let normalized = normaliser.normalize(track: original)

        XCTAssertEqual(normalized.artist, "Radiohead")
    }

    func testLeavesAlreadyCasedArtistNameUntouched() {
        let original = Track(
            title: "Numb",
            artist: "Linkin Park",
            album: "Meteora",
            duration: 185,
            filePath: "/tmp/c.mp3",
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100
        )

        let normalized = normaliser.normalize(track: original)

        XCTAssertEqual(normalized.artist, "Linkin Park")
    }

    func testEmptyOrWhitespaceGenreBecomesNil() {
        let original = Track(
            title: "Track",
            artist: "Artist",
            album: "Album",
            duration: 100,
            filePath: "/tmp/d.mp3",
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100,
            genre: "   "
        )

        let normalized = normaliser.normalize(track: original)

        XCTAssertNil(normalized.genre)
    }

    func testNormalizesGenreCasing() {
        let original = Track(
            title: "Track",
            artist: "Artist",
            album: "Album",
            duration: 100,
            filePath: "/tmp/e.mp3",
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100,
            genre: "  progressive   rock "
        )

        let normalized = normaliser.normalize(track: original)

        XCTAssertEqual(normalized.genre, "Progressive Rock")
    }
}
