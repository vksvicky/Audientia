//
//  MockLibraryComponents.swift
//  UITests
//
//  Mock implementations for library components (scanner, indexer, search)
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import DataLayer
import Foundation
@testable import Shared

/// Mock implementation of LibraryScannerProtocol for testing
@MainActor
final class MockLibraryScanner: LibraryScannerProtocol {
    
    // MARK: - Mock Properties
    
    var mockTracks: [Track] = []
    var shouldFail = false
    var scanCalled = false
    var lastScannedDirectory: URL?
    
    // MARK: - LibraryScannerProtocol
    
    func scan(directory: URL) async throws -> [Track] {
        scanCalled = true
        lastScannedDirectory = directory
        
        if shouldFail {
            throw NSError(domain: "MockLibraryScanner", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock scan failure"])
        }
        
        return mockTracks
    }
}

/// Mock implementation of LibraryIndexerProtocol for testing
@MainActor
final class MockLibraryIndexer: LibraryIndexerProtocol {
    
    // MARK: - Mock Properties
    
    private var indexedTracks: [UUID: Track] = [:]
    private var tracksByPath: [String: Track] = [:]
    
    var shouldFailIndex = false
    var shouldFailRemove = false
    var shouldFailClear = false
    var indexCalled = false
    var removeCalled = false
    var clearCalled = false
    
    // MARK: - LibraryIndexerProtocol
    
    func index(tracks: [Track]) async throws {
        indexCalled = true
        
        if shouldFailIndex {
            throw LibraryIndexerError.indexingFailed
        }
        
        for track in tracks {
            indexedTracks[track.id] = track
            tracksByPath[track.filePath] = track
        }
    }
    
    func remove(track: Track) async throws {
        removeCalled = true
        
        if shouldFailRemove {
            throw LibraryIndexerError.trackNotFound
        }
        
        indexedTracks.removeValue(forKey: track.id)
        tracksByPath.removeValue(forKey: track.filePath)
    }
    
    func clear() async throws {
        clearCalled = true
        
        if shouldFailClear {
            throw LibraryIndexerError.indexingFailed
        }
        
        indexedTracks.removeAll()
        tracksByPath.removeAll()
    }
    
    func getTrack(by id: UUID) async -> Track? {
        indexedTracks[id]
    }
    
    func getIndexedTrackCount() async -> Int {
        indexedTracks.count
    }
    
    func getAllTracks() async -> [Track] {
        Array(indexedTracks.values)
    }
}

/// Helper factory for creating test tracks
enum MockTrackFactory {
    static func makeTrack(
        id: UUID = UUID(),
        title: String = "Test Track",
        artist: String = "Test Artist",
        album: String = "Test Album",
        duration: TimeInterval = 180.0,
        filePath: String = "/path/to/track.mp3",
        fileSize: Int64 = 5_000_000,
        bitrate: Int = 320,
        sampleRate: Int = 44100,
        year: Int? = nil,
        trackNumber: Int? = nil,
        discNumber: Int? = nil,
        genre: String? = nil,
        rating: Int? = nil
    ) -> Track {
        Track(
            id: id,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            filePath: filePath,
            fileSize: fileSize,
            bitrate: bitrate,
            sampleRate: sampleRate,
            year: year,
            trackNumber: trackNumber,
            discNumber: discNumber,
            genre: genre,
            rating: rating
        )
    }
    
    static func makeTracks(count: Int, prefix: String = "Track") -> [Track] {
        (0..<count).map { index in
            makeTrack(
                title: "\(prefix) \(index + 1)",
                artist: "Artist \(index + 1)",
                album: "Album \(index + 1)",
                filePath: "/path/to/\(prefix.lowercased())_\(index + 1).mp3"
            )
        }
    }
}
