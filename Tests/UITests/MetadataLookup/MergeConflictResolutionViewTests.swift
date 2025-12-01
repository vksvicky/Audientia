//
//  MergeConflictResolutionViewTests.swift
//  UITests
//
//  TDD tests for MergeConflictResolutionView
//

@testable import Shared
import SwiftUI
import XCTest

@MainActor
final class MergeConflictResolutionViewTests: XCTestCase {
    
    func testViewInitialisesWithTracks() {
        let original = Track(
            title: "Original",
            artist: "Original Artist",
            album: "Original Album",
            duration: 180,
            filePath: "/tmp/original.mp3",
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100
        )
        let preview = Track(
            id: original.id,
            title: "Preview",
            artist: "Preview Artist",
            album: "Preview Album",
            duration: 180,
            filePath: "/tmp/original.mp3",
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100
        )
        let view = MergeConflictResolutionView(originalTrack: original, previewTrack: preview)
        XCTAssertNotNil(view)
    }
}
