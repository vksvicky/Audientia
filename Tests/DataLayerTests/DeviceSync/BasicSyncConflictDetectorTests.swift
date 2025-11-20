//
//  BasicSyncConflictDetectorTests.swift
//  DataLayerTests
//

@testable import DataLayer
@testable import Shared
import XCTest

final class BasicSyncConflictDetectorTests: XCTestCase {
    
    func testMissingTrackCreatesConflict() async {
        guard let track = DeviceSyncFixtures.tracks(count: 1).first else {
            XCTFail("Expected at least one track")
            return
        }
        let snapshot = DeviceSyncFixtures.snapshot(
            track: track,
            libraryChecksum: "abc",
            deviceChecksum: nil,
            isPresent: false
        )
        let detector = BasicSyncConflictDetector()
        let job = SyncJob(request: DeviceSyncFixtures.syncRequest(tracks: [track]))
        
        let conflicts = await detector.detectConflicts(job: job, deviceTracks: [snapshot])
        
        XCTAssertEqual(conflicts.count, 1)
        XCTAssertEqual(conflicts.first?.reason, .missingOnDevice)
    }
    
    func testChecksumMismatchCreatesConflict() async {
        guard let track = DeviceSyncFixtures.tracks(count: 1).first else {
            XCTFail("Expected at least one track")
            return
        }
        let snapshot = DeviceSyncFixtures.snapshot(
            track: track,
            libraryChecksum: "abc",
            deviceChecksum: "xyz",
            isPresent: true
        )
        let detector = BasicSyncConflictDetector()
        let job = SyncJob(request: DeviceSyncFixtures.syncRequest(tracks: [track]))
        
        let conflicts = await detector.detectConflicts(job: job, deviceTracks: [snapshot])
        
        XCTAssertEqual(conflicts.count, 1)
        XCTAssertEqual(conflicts.first?.reason, .changedOnDevice)
    }
    
    func testNoConflictWhenChecksumsMatch() async {
        guard let track = DeviceSyncFixtures.tracks(count: 1).first else {
            XCTFail("Expected at least one track")
            return
        }
        let snapshot = DeviceSyncFixtures.snapshot(
            track: track,
            libraryChecksum: "same",
            deviceChecksum: "same",
            isPresent: true
        )
        let detector = BasicSyncConflictDetector()
        let job = SyncJob(request: DeviceSyncFixtures.syncRequest(tracks: [track]))
        
        let conflicts = await detector.detectConflicts(job: job, deviceTracks: [snapshot])
        
        XCTAssertTrue(conflicts.isEmpty)
    }
}
