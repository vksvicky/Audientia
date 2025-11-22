//
//  MTPDeviceConnectorBDDTests.swift
//  DataLayerTests
//
//  BDD tests for MTPDeviceConnector scenarios
//

@testable import DataLayer
@testable import Shared
import XCTest

final class MTPDeviceConnectorBDDTests: XCTestCase {
    
    private var connector: MTPDeviceConnector!
    private var mockMTP: MockMTPProtocol!
    private var device: Device!
    private var tracks: [Track]!
    private var testDirectory: URL!
    
    override func setUp() async throws {
        testDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        
        mockMTP = MockMTPProtocol()
        connector = MTPDeviceConnector(mtpProtocol: mockMTP)
        
        device = Device(
            name: "Android Phone",
            type: .mtp,
            capacity: 128 * 1024 * 1024 * 1024,
            availableSpace: 64 * 1024 * 1024 * 1024,
            mountPath: nil,
            status: .ready
        )
        
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
            let data = Data(repeating: 0, count: Int(track.fileSize))
            try data.write(to: URL(fileURLWithPath: track.filePath))
        }
    }
    
    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: testDirectory)
        connector = nil
        mockMTP = nil
        device = nil
        tracks = nil
    }
    
    func testGivenMTPDeviceWhenSyncingTracksThenTracksAreTransferredToDevice() async throws {
        // Scenario: As a user, I want to sync music tracks to my Android device via MTP
        // Given: An MTP device and tracks to sync
        // Note: transfer() connects internally, so we don't need to connect beforehand
        let options = SyncOptions(createFolderStructure: true, folderStructure: .artistAlbum)
        
        // When: I sync tracks to the device
        var progressReports: [SyncProgress] = []
        try await connector.transfer(
            tracks: tracks,
            to: device,
            jobId: UUID(),
            options: options
        ) { progress in
            progressReports.append(progress)
        }
        
        // Then: The tracks should be on the device
        // Note: transfer() disconnects after completion, so we need to reconnect to check files
        _ = try await mockMTP.connect(deviceId: device.id.uuidString)
        let deviceFiles = try await mockMTP.listFiles()
        XCTAssertGreaterThan(deviceFiles.count, 0, "Device should have files after sync")
        XCTAssertTrue(deviceFiles.contains { $0.contains("bohemian") }, "Should contain bohemian track")
        XCTAssertTrue(deviceFiles.contains { $0.contains("stairway") }, "Should contain stairway track")
        XCTAssertTrue(!progressReports.isEmpty, "Should report progress during transfer")
    }
    
    func testGivenMTPDeviceWithFolderStructureWhenSyncingThenTracksAreOrganized() async throws {
        // Scenario: As a user, I want my music organized by artist and album on my Android device
        // Given: An MTP device and tracks with folder structure enabled
        // Note: transfer() connects internally, so we don't need to connect beforehand
        let options = SyncOptions(
            createFolderStructure: true,
            folderStructure: .artistAlbum
        )
        
        // When: I sync tracks to the device
        try await connector.transfer(
            tracks: tracks,
            to: device,
            jobId: UUID(),
            options: options
        ) { _ in }
        
        // Then: Tracks should be organized in Artist/Album folders
        // Note: transfer() disconnects after completion, so we need to reconnect to check files
        _ = try await mockMTP.connect(deviceId: device.id.uuidString)
        let deviceFiles = try await mockMTP.listFiles()
        let queenPath = deviceFiles.first { $0.contains("Queen") && $0.contains("A Night at the Opera") }
        let zeppelinPath = deviceFiles.first { $0.contains("Led Zeppelin") && $0.contains("Led Zeppelin IV") }
        
        XCTAssertNotNil(queenPath, "Queen track should be in Queen/A Night at the Opera folder")
        XCTAssertNotNil(zeppelinPath, "Zeppelin track should be in Led Zeppelin/Led Zeppelin IV folder")
    }
    
    func testGivenMTPDeviceWithInsufficientSpaceWhenSyncingThenSyncFailsGracefully() async throws {
        // Scenario: As a user, I want to be informed if my device doesn't have enough space
        // Given: An MTP device with very little available space
        _ = try await mockMTP.connect(deviceId: device.id.uuidString)
        await mockMTP.setAvailableSpace(1024) // 1 KB
        
        let largeTrack = Track(
            title: "Large Song",
            artist: "Artist",
            album: "Album",
            duration: 180,
            filePath: testDirectory.appendingPathComponent("large.mp3").path,
            fileSize: 10 * 1024 * 1024,
            bitrate: 320,
            sampleRate: 44_100
        )
        let largeData = Data(repeating: 0, count: 2 * 1024) // 2 KB
        try largeData.write(to: URL(fileURLWithPath: largeTrack.filePath))
        
        // When: I try to sync a large file
        // Then: The sync should fail with an insufficient space error
        do {
            try await connector.transfer(
                tracks: [largeTrack],
                to: device,
                jobId: UUID(),
                options: .default
            ) { _ in }
            XCTFail("Should throw insufficient space error")
        } catch let error as DeviceSyncError {
            XCTAssertEqual(error, .insufficientSpace, "Should throw insufficientSpace error")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testGivenMTPDeviceWhenCancellingTransferThenTransferStops() async throws {
        // Scenario: As a user, I want to cancel a sync operation in progress
        // Given: A slow transfer in progress
        _ = try await mockMTP.connect(deviceId: device.id.uuidString)
        await mockMTP.setUploadDelay(0.5) // 0.5 second delay per file
        
        let jobId = UUID()
        let transferTask = Task {
            try await connector.transfer(
                tracks: tracks,
                to: device,
                jobId: jobId,
                options: .default
            ) { _ in }
        }
        
        // When: I cancel the transfer
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        await connector.cancel(jobId: jobId)
        
        // Then: The transfer should be cancelled
        do {
            try await transferTask.value
            XCTFail("Transfer should be cancelled")
        } catch is CancellationError {
            // Expected - transfer was cancelled
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testGivenMTPDeviceWhenConnectionFailsThenErrorIsReported() async throws {
        // Scenario: As a user, I want to know if my device connection fails
        // Given: An MTP device that fails to connect
        await mockMTP.setShouldFailConnection(true)
        
        // When: I try to fetch device tracks
        // Then: Should throw device not found error
        do {
            _ = try await connector.fetchDeviceTracks(device: device)
            XCTFail("Should throw error when connection fails")
        } catch let error as DeviceSyncError {
            XCTAssertEqual(error, .deviceNotFound, "Should throw deviceNotFound error")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testGivenMTPDeviceWhenTransferFailsThenErrorIsReported() async throws {
        // Scenario: As a user, I want to know if a file transfer fails
        // Given: An MTP device that fails during transfer
        _ = try await mockMTP.connect(deviceId: device.id.uuidString)
        await mockMTP.setShouldFailUpload(true)
        
        // When: I try to transfer tracks
        // Then: Should throw transfer failed error
        do {
            try await connector.transfer(
                tracks: tracks,
                to: device,
                jobId: UUID(),
                options: .default
            ) { _ in }
            XCTFail("Should throw transfer failed error")
        } catch let error as DeviceSyncError {
            if case .transferFailed = error {
                // Expected
            } else {
                XCTFail("Should throw transferFailed error, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
