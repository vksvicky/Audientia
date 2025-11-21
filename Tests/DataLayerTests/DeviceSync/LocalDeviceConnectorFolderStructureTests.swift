//
//  LocalDeviceConnectorFolderStructureTests.swift
//  DataLayerTests
//
//  TDD tests for folder structure integration in LocalDeviceConnector
//

@testable import DataLayer
@testable import Shared
import XCTest

final class LocalDeviceConnectorFolderStructureTests: XCTestCase {
    
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
        
        // Create test tracks
        tracks = [
            Track(
                title: "Song 1",
                artist: "Artist A",
                album: "Album 1",
                duration: 180,
                filePath: testDirectory.appendingPathComponent("track1.mp3").path,
                fileSize: 5 * 1024 * 1024,
                bitrate: 320,
                sampleRate: 44_100,
                genre: "Rock"
            ),
            Track(
                title: "Song 2",
                artist: "Artist B",
                album: "Album 2",
                duration: 200,
                filePath: testDirectory.appendingPathComponent("track2.mp3").path,
                fileSize: 6 * 1024 * 1024,
                bitrate: 320,
                sampleRate: 44_100,
                genre: "Jazz"
            )
        ]
        
        // Create source files
        for track in tracks {
            try "test data".write(to: URL(fileURLWithPath: track.filePath), atomically: true, encoding: .utf8)
        }
        
        connector = LocalDeviceConnector()
    }
    
    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: testDirectory)
        connector = nil
        device = nil
        tracks = nil
    }
    
    func testTransferWithArtistAlbumStructure() async throws {
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
        
        // When: Transferring tracks
        var progressCount = 0
        try await connector.transfer(
            tracks: request.tracks,
            to: request.device,
            jobId: request.id,
            options: request.options
        ) { _ in
            progressCount += 1
        }
        
        // Then: Files should be organized in Artist/Album structure
        let libraryRoot = testDirectory.appendingPathComponent("Audientia")
        let track1Path = libraryRoot.appendingPathComponent("Artist A/Album 1/track1.mp3")
        let track2Path = libraryRoot.appendingPathComponent("Artist B/Album 2/track2.mp3")
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: track1Path.path), "Track 1 should be in Artist A/Album 1")
        XCTAssertTrue(FileManager.default.fileExists(atPath: track2Path.path), "Track 2 should be in Artist B/Album 2")
    }
    
    func testTransferWithFlatStructure() async throws {
        // Given: A sync request with flat folder structure
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
        
        // When: Transferring tracks
        try await connector.transfer(
            tracks: request.tracks,
            to: request.device,
            jobId: request.id,
            options: request.options
        ) { _ in }
        
        // Then: Files should be in flat structure (UUID-based directories for now)
        let libraryRoot = testDirectory.appendingPathComponent("Audientia")
        let contents = try FileManager.default.contentsOfDirectory(at: libraryRoot, includingPropertiesForKeys: nil)
        XCTAssertGreaterThan(contents.count, 0, "Should have files in library root")
    }
    
    func testTransferWithGenreArtistAlbumStructure() async throws {
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
        
        // When: Transferring tracks
        try await connector.transfer(
            tracks: request.tracks,
            to: request.device,
            jobId: request.id,
            options: request.options
        ) { _ in }
        
        // Then: Files should be organized in Genre/Artist/Album structure
        let libraryRoot = testDirectory.appendingPathComponent("Audientia")
        let track1Path = libraryRoot.appendingPathComponent("Rock/Artist A/Album 1/track1.mp3")
        let track2Path = libraryRoot.appendingPathComponent("Jazz/Artist B/Album 2/track2.mp3")
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: track1Path.path), "Track 1 should be in Rock/Artist A/Album 1")
        XCTAssertTrue(FileManager.default.fileExists(atPath: track2Path.path), "Track 2 should be in Jazz/Artist B/Album 2")
    }
}
