//
//  LocalDeviceConnectorFolderStructureBDDTests.swift
//  DataLayerTests
//
//  BDD tests for folder structure integration in LocalDeviceConnector
//

@testable import DataLayer
@testable import Shared
import XCTest

final class LocalDeviceConnectorFolderStructureBDDTests: XCTestCase {
    
    private var connector: LocalDeviceConnector!
    private var testDirectory: URL!
    private var device: Device!
    private var tracks: [Track]!
    
    override func setUp() async throws {
        testDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        
        device = Device(
            name: "Test Device",
            type: .usb,
            capacity: 100 * 1024 * 1024,
            availableSpace: 50 * 1024 * 1024,
            mountPath: testDirectory.path,
            status: .ready
        )
        
        // Create test tracks with different artists, albums, and genres
        tracks = [
            Track(
                title: "Bohemian Rhapsody",
                artist: "Queen",
                album: "A Night at the Opera",
                duration: 355,
                filePath: testDirectory.appendingPathComponent("bohemian.mp3").path,
                fileSize: 8 * 1024 * 1024,
                bitrate: 320,
                sampleRate: 44_100,
                genre: "Rock"
            ),
            Track(
                title: "Take Five",
                artist: "Dave Brubeck",
                album: "Time Out",
                duration: 324,
                filePath: testDirectory.appendingPathComponent("takefive.mp3").path,
                fileSize: 7 * 1024 * 1024,
                bitrate: 320,
                sampleRate: 44_100,
                genre: "Jazz"
            ),
            Track(
                title: "Stairway to Heaven",
                artist: "Led Zeppelin",
                album: "Led Zeppelin IV",
                duration: 482,
                filePath: testDirectory.appendingPathComponent("stairway.mp3").path,
                fileSize: 10 * 1024 * 1024,
                bitrate: 320,
                sampleRate: 44_100,
                genre: "Rock"
            )
        ]
        
        // Create source files
        for track in tracks {
            try "test data for \(track.title)".write(to: URL(fileURLWithPath: track.filePath), atomically: true, encoding: .utf8)
        }
        
        connector = LocalDeviceConnector()
    }
    
    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: testDirectory)
        connector = nil
        device = nil
        tracks = nil
    }
    
    func testGivenArtistAlbumStructureWhenSyncingThenTracksAreOrganizedByArtistAndAlbum() async throws {
        // Scenario: As a user, I want my music organized by artist and album on my device
        // Given: A sync request with artist/album folder structure
        let options = SyncOptions(
            createFolderStructure: true,
            folderStructure: .artistAlbum
        )
        let request = SyncRequest(
            device: device,
            tracks: tracks,
            direction: .desktopToDevice,
            options: options
        )
        
        // When: I sync tracks to the device
        try await connector.transfer(
            tracks: request.tracks,
            to: request.device,
            jobId: request.id,
            options: request.options
        ) { _ in }
        
        // Then: Tracks should be organized in Artist/Album folders
        let libraryRoot = testDirectory.appendingPathComponent("Audientia")
        let queenTrack = libraryRoot.appendingPathComponent("Queen/A Night at the Opera/bohemian.mp3")
        let brubeckTrack = libraryRoot.appendingPathComponent("Dave Brubeck/Time Out/takefive.mp3")
        let zeppelinTrack = libraryRoot.appendingPathComponent("Led Zeppelin/Led Zeppelin IV/stairway.mp3")
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: queenTrack.path), "Queen track should be in Queen/A Night at the Opera")
        XCTAssertTrue(FileManager.default.fileExists(atPath: brubeckTrack.path), "Brubeck track should be in Dave Brubeck/Time Out")
        XCTAssertTrue(FileManager.default.fileExists(atPath: zeppelinTrack.path), "Zeppelin track should be in Led Zeppelin/Led Zeppelin IV")
    }
    
    func testGivenGenreArtistAlbumStructureWhenSyncingThenTracksAreOrganizedByGenreArtistAndAlbum() async throws {
        // Scenario: As a user, I want my music organized by genre, then artist, then album
        // Given: A sync request with genre/artist/album folder structure
        let options = SyncOptions(
            createFolderStructure: true,
            folderStructure: .genreArtistAlbum
        )
        let request = SyncRequest(
            device: device,
            tracks: tracks,
            direction: .desktopToDevice,
            options: options
        )
        
        // When: I sync tracks to the device
        try await connector.transfer(
            tracks: request.tracks,
            to: request.device,
            jobId: request.id,
            options: request.options
        ) { _ in }
        
        // Then: Tracks should be organized in Genre/Artist/Album folders
        let libraryRoot = testDirectory.appendingPathComponent("Audientia")
        let rockQueenTrack = libraryRoot.appendingPathComponent("Rock/Queen/A Night at the Opera/bohemian.mp3")
        let jazzBrubeckTrack = libraryRoot.appendingPathComponent("Jazz/Dave Brubeck/Time Out/takefive.mp3")
        let rockZeppelinTrack = libraryRoot.appendingPathComponent("Rock/Led Zeppelin/Led Zeppelin IV/stairway.mp3")
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: rockQueenTrack.path), "Queen track should be in Rock/Queen/A Night at the Opera")
        XCTAssertTrue(FileManager.default.fileExists(atPath: jazzBrubeckTrack.path), "Brubeck track should be in Jazz/Dave Brubeck/Time Out")
        XCTAssertTrue(FileManager.default.fileExists(atPath: rockZeppelinTrack.path), "Zeppelin track should be in Rock/Led Zeppelin/Led Zeppelin IV")
    }
    
    func testGivenFlatStructureWhenSyncingThenTracksAreNotOrganizedIntoFolders() async throws {
        // Scenario: As a user, I want all my tracks in a flat structure without folder organization
        // Given: A sync request with flat folder structure (createFolderStructure = false)
        let options = SyncOptions(
            createFolderStructure: false,
            folderStructure: .flat
        )
        let request = SyncRequest(
            device: device,
            tracks: tracks,
            direction: .desktopToDevice,
            options: options
        )
        
        // When: I sync tracks to the device
        try await connector.transfer(
            tracks: request.tracks,
            to: request.device,
            jobId: request.id,
            options: request.options
        ) { _ in }
        
        // Then: Tracks should be in UUID-based directories (legacy behavior)
        let libraryRoot = testDirectory.appendingPathComponent("Audientia")
        let contents = try FileManager.default.contentsOfDirectory(at: libraryRoot, includingPropertiesForKeys: nil)
        XCTAssertGreaterThan(contents.count, 0, "Should have files in library root")
        
        // Verify files exist but not in organized folders
        let allFiles = contents.flatMap { dir -> [String] in
            (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []
        }
        XCTAssertTrue(allFiles.contains { $0.contains("bohemian") }, "Should contain bohemian track")
        XCTAssertTrue(allFiles.contains { $0.contains("takefive") }, "Should contain takefive track")
        XCTAssertTrue(allFiles.contains { $0.contains("stairway") }, "Should contain stairway track")
    }
    
    func testGivenAlbumArtistStructureWhenSyncingThenTracksAreOrganizedByAlbumThenArtist() async throws {
        // Scenario: As a user, I want my music organized by album first, then artist
        // Given: A sync request with album/artist folder structure
        let options = SyncOptions(
            createFolderStructure: true,
            folderStructure: .albumArtist
        )
        let request = SyncRequest(
            device: device,
            tracks: tracks,
            direction: .desktopToDevice,
            options: options
        )
        
        // When: I sync tracks to the device
        try await connector.transfer(
            tracks: request.tracks,
            to: request.device,
            jobId: request.id,
            options: request.options
        ) { _ in }
        
        // Then: Tracks should be organized in Album/Artist folders
        let libraryRoot = testDirectory.appendingPathComponent("Audientia")
        let queenTrack = libraryRoot.appendingPathComponent("A Night at the Opera/Queen/bohemian.mp3")
        let brubeckTrack = libraryRoot.appendingPathComponent("Time Out/Dave Brubeck/takefive.mp3")
        let zeppelinTrack = libraryRoot.appendingPathComponent("Led Zeppelin IV/Led Zeppelin/stairway.mp3")
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: queenTrack.path), "Queen track should be in A Night at the Opera/Queen")
        XCTAssertTrue(FileManager.default.fileExists(atPath: brubeckTrack.path), "Brubeck track should be in Time Out/Dave Brubeck")
        XCTAssertTrue(FileManager.default.fileExists(atPath: zeppelinTrack.path), "Zeppelin track should be in Led Zeppelin IV/Led Zeppelin")
    }
}
