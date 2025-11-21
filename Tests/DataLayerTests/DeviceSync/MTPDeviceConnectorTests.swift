//
//  MTPDeviceConnectorTests.swift
//  DataLayerTests
//
//  TDD tests for MTPDeviceConnector (Right-BICEP)
//

@testable import DataLayer
@testable import Shared
import XCTest

final class MTPDeviceConnectorTests: XCTestCase {
    
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
            name: "Android Device",
            type: .mtp,
            capacity: 64 * 1024 * 1024 * 1024,
            availableSpace: 32 * 1024 * 1024 * 1024,
            mountPath: nil, // MTP devices don't have mount paths
            status: .ready
        )
        
        tracks = [
            Track(
                title: "Test Song",
                artist: "Test Artist",
                album: "Test Album",
                duration: 180,
                filePath: testDirectory.appendingPathComponent("test1.mp3").path,
                fileSize: 5 * 1024 * 1024,
                bitrate: 320,
                sampleRate: 44_100
            )
        ]
        
        // Create source file
        try "test data".write(to: URL(fileURLWithPath: tracks[0].filePath), atomically: true, encoding: .utf8)
    }
    
    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: testDirectory)
        connector = nil
        mockMTP = nil
        device = nil
        tracks = nil
    }
    
    // MARK: - [Right] Results Right
    
    func testFetchDeviceTracksReturnsEmptyArrayWhenNoFiles() async throws {
        // Given: An MTP device with no files
        _ = try await mockMTP.connect(deviceId: device.id.uuidString)
        
        // When: Fetching device tracks
        let snapshots = try await connector.fetchDeviceTracks(device: device)
        
        // Then: Should return empty array
        XCTAssertEqual(snapshots.count, 0, "Should return empty array when no files on device")
    }
    
    func testTransferFileToMTPDevice() async throws {
        // Given: A connected MTP device and a track to transfer
        _ = try await mockMTP.connect(deviceId: device.id.uuidString)
        let options = SyncOptions(createFolderStructure: true, folderStructure: .artistAlbum)
        
        // When: Transferring a track
        var progressValues: [Double] = []
        try await connector.transfer(
            tracks: tracks,
            to: device,
            jobId: UUID(),
            options: options
        ) { progress in
            progressValues.append(progress.percentage)
        }
        
        // Then: File should be uploaded to device
        let files = try await mockMTP.listFiles()
        XCTAssertGreaterThan(files.count, 0, "Should have files on device after transfer")
        XCTAssertTrue(!progressValues.isEmpty, "Should report progress")
    }
    
    // MARK: - [B] Boundary Conditions
    
    func testFetchDeviceTracksWhenNotConnected() async {
        // Given: MTP device that fails to connect
        await mockMTP.setShouldFailConnection(true)
        
        // When: Fetching device tracks
        // Then: Should throw device not found error
        do {
            _ = try await connector.fetchDeviceTracks(device: device)
            XCTFail("Should throw error when device connection fails")
        } catch let error as DeviceSyncError {
            XCTAssertEqual(error, .deviceNotFound, "Should throw deviceNotFound error")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testTransferWithInsufficientSpace() async throws {
        // Given: MTP device with very little space
        _ = try await mockMTP.connect(deviceId: device.id.uuidString)
        await mockMTP.setAvailableSpace(1024) // 1 KB
        
        let largeTrack = Track(
            title: "Large Song",
            artist: "Artist",
            album: "Album",
            duration: 180,
            filePath: testDirectory.appendingPathComponent("large.mp3").path,
            fileSize: 10 * 1024 * 1024, // 10 MB
            bitrate: 320,
            sampleRate: 44_100
        )
        // Create a file that's actually large enough to trigger insufficient space
        let largeData = Data(repeating: 0, count: 2 * 1024) // 2 KB (larger than 1 KB available)
        try largeData.write(to: URL(fileURLWithPath: largeTrack.filePath))
        
        // When: Transferring large file
        // Then: Should throw insufficient space error
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
    
    // MARK: - [I] Inverse Relationships
    
    func testCancelStopsTransfer() async throws {
        // Given: A slow transfer in progress
        _ = try await mockMTP.connect(deviceId: device.id.uuidString)
        await mockMTP.setUploadDelay(1.0) // 1 second delay
        
        let jobId = UUID()
        let transferTask = Task {
            try await connector.transfer(
                tracks: tracks,
                to: device,
                jobId: jobId,
                options: .default
            ) { _ in }
        }
        
        // When: Cancelling the transfer
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        await connector.cancel(jobId: jobId)
        await mockMTP.cancel()
        
        // Then: Transfer should be cancelled
        do {
            try await transferTask.value
            XCTFail("Transfer should be cancelled")
        } catch is CancellationError {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - [C] Cross-Checking
    
    func testTransferCreatesCorrectFolderStructure() async throws {
        // Given: MTP device and track with folder structure enabled
        _ = try await mockMTP.connect(deviceId: device.id.uuidString)
        let options = SyncOptions(
            createFolderStructure: true,
            folderStructure: .artistAlbum
        )
        
        // When: Transferring track
        try await connector.transfer(
            tracks: tracks,
            to: device,
            jobId: UUID(),
            options: options
        ) { _ in }
        
        // Then: Files should be in correct folder structure
        let files = try await mockMTP.listFiles()
        let hasArtistAlbumPath = files.contains { $0.contains("Test Artist") && $0.contains("Test Album") }
        XCTAssertTrue(hasArtistAlbumPath, "Should create Artist/Album folder structure")
    }
    
    // MARK: - [E] Error Conditions
    
    func testTransferFailsWhenConnectionLost() async throws {
        // Given: Connected device
        _ = try await mockMTP.connect(deviceId: device.id.uuidString)
        await mockMTP.setShouldFailUpload(true)
        
        // When: Transferring with connection failure
        // Then: Should throw transfer failed error
        do {
            try await connector.transfer(
                tracks: tracks,
                to: device,
                jobId: UUID(),
                options: .default
            ) { _ in }
            XCTFail("Should throw error on connection failure")
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
    
    // MARK: - [P] Performance
    
    func testTransferPerformance() async throws {
        // Given: Connected device and multiple tracks
        _ = try await mockMTP.connect(deviceId: device.id.uuidString)
        await mockMTP.setUploadDelay(0.001) // Fast upload
        
        let multipleTracks = (0..<10).map { index in
            Track(
                title: "Track \(index)",
                artist: "Artist",
                album: "Album",
                duration: 180,
                filePath: testDirectory.appendingPathComponent("track\(index).mp3").path,
                fileSize: 1024 * 1024,
                bitrate: 320,
                sampleRate: 44_100
            )
        }
        
        // Create source files
        for track in multipleTracks {
            try "data".write(to: URL(fileURLWithPath: track.filePath), atomically: true, encoding: .utf8)
        }
        
        // When: Measuring transfer performance
        measure {
            Task {
                try? await connector.transfer(
                    tracks: multipleTracks,
                    to: device,
                    jobId: UUID(),
                    options: .default
                ) { _ in }
            }
        }
    }
}
