//
//  LocalDeviceConnectorTests.swift
//  DataLayerTests
//

@testable import DataLayer
@testable import Shared
import XCTest

final class LocalDeviceConnectorTests: XCTestCase {
    
    private var tempDirectory: URL!
    private var connector: LocalDeviceConnector!
    private var device: Device!
    
    override func setUp() async throws {
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        connector = LocalDeviceConnector()
        device = Device(
            id: UUID(),
            name: "Test USB",
            type: .usb,
            capacity: 128 * 1024 * 1024,
            availableSpace: 64 * 1024 * 1024,
            mountPath: tempDirectory.path,
            status: .ready
        )
    }
    
    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        tempDirectory = nil
        connector = nil
        device = nil
    }
    
    func testTransferCopiesFilesAndUpdatesManifest() async throws {
        let track = try makeSampleTrack(index: 1)
        let jobId = UUID()
        
        try await connector.transfer(tracks: [track], to: device, jobId: jobId) { _ in }
        
        let snapshots = try await connector.fetchDeviceTracks(device: device)
        XCTAssertEqual(snapshots.count, 1)
        let snapshot = try XCTUnwrap(snapshots.first)
        XCTAssertTrue(snapshot.isPresentOnDevice)
        XCTAssertEqual(snapshot.track.id, track.id)
        XCTAssertNotNil(snapshot.libraryChecksum)
    }
    
    func testFetchDeviceTracksReportsMissingFiles() async throws {
        let track = try makeSampleTrack(index: 2)
        let jobId = UUID()
        
        try await connector.transfer(tracks: [track], to: device, jobId: jobId) { _ in }
        
        // Remove file manually
        let snapshots = try await connector.fetchDeviceTracks(device: device)
        let snapshot = try XCTUnwrap(snapshots.first)
        let missingURL = tempDirectory.appendingPathComponent(snapshot.relativePath)
        try FileManager.default.removeItem(at: missingURL)
        
        let refreshed = try await connector.fetchDeviceTracks(device: device)
        XCTAssertEqual(refreshed.first?.isPresentOnDevice, false)
    }
    
    func testCancelStopsTransfer() async throws {
        connector = LocalDeviceConnector(copyDelayNanoseconds: 200_000_000)
        let track = try makeSampleTrack(index: 3)
        let jobId = UUID()
        
        async let transferTask: Void = connector.transfer(tracks: [track], to: device, jobId: jobId) { _ in }
        
        try await Task.sleep(nanoseconds: 50_000_000)
        await connector.cancel(jobId: jobId)
        
        do {
            try await transferTask
            XCTFail("Transfer should have been cancelled")
        } catch is CancellationError {
            // Expected
        }
    }
    
    // MARK: - Helpers
    
    private func makeSampleTrack(index: Int) throws -> Track {
        let sourceDir = tempDirectory.appendingPathComponent("library", isDirectory: true)
        try FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)
        let sourceURL = sourceDir.appendingPathComponent("track\(index).flac")
        let data = Data(repeating: UInt8(index), count: 1_024)
        try data.write(to: sourceURL)
        
        return Track(
            title: "Track \(index)",
            artist: "Artist",
            album: "Album",
            duration: 200,
            filePath: sourceURL.path,
            fileSize: Int64(data.count),
            bitrate: 320,
            sampleRate: 44_100
        )
    }
}
