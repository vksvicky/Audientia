//
//  HomeViewModelTestHelpers.swift
//  Audientia
//
//  Test helpers and mocks for HomeViewModel tests
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@preconcurrency import DataLayer
@preconcurrency import MetadataEngine
@testable import Shared
import XCTest

// MARK: - Mock Implementations

actor MockListeningHistory: ListeningHistoryProtocol {
    private var events: [ListeningEvent] = []
    private var shouldFailGetRecentEvents = false
    
    func setShouldFailGetRecentEvents(_ value: Bool) {
        shouldFailGetRecentEvents = value
    }
    
    func recordEvent(_ event: ListeningEvent) async {
        events.append(event)
    }
    
    func getRecentEvents(limit: Int) async -> [ListeningEvent] {
        if shouldFailGetRecentEvents {
            return []
        }
        return Array(events.sorted { $0.timestamp > $1.timestamp }.prefix(limit))
    }
    
    func getEvents(for trackId: UUID) async -> [ListeningEvent] {
        events.filter { $0.trackId == trackId }
    }
    
    func getPlayCount(for trackId: UUID) async -> Int {
        events.filter { $0.trackId == trackId && !$0.wasSkipped }.count
    }
    
    func getSkipCount(for trackId: UUID) async -> Int {
        events.filter { $0.trackId == trackId && $0.wasSkipped }.count
    }
    
    func getTracksPlayed(from startDate: Date, to endDate: Date) async -> [UUID] {
        events
            .filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
            .map { $0.trackId }
    }
    
    func clear() async {
        events.removeAll()
    }
    
    func getMostPlayedTrackIds(limit: Int) async -> [UUID] {
        let playCounts = Dictionary(grouping: events.filter { !$0.wasSkipped }) { $0.trackId }
            .mapValues { $0.count }
        
        return playCounts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }
}

actor HomeMockLibraryIndexer: LibraryIndexerProtocol {
    private var tracks: [UUID: Track] = [:]
    private var shouldFailGetTrack = false
    
    func setShouldFailGetTrack(_ value: Bool) {
        shouldFailGetTrack = value
    }
    
    func setTracks(_ tracks: [Track]) async {
        self.tracks = Dictionary(uniqueKeysWithValues: tracks.map { ($0.id, $0) })
    }
    
    func index(tracks: [Track]) async throws {
        for track in tracks {
            self.tracks[track.id] = track
        }
    }
    
    func remove(track: Track) async throws {
        tracks.removeValue(forKey: track.id)
    }
    
    func clear() async throws {
        tracks.removeAll()
    }
    
    func getTrack(by id: UUID) async -> Track? {
        if shouldFailGetTrack {
            return nil
        }
        return tracks[id]
    }
    
    func getIndexedTrackCount() async -> Int {
        tracks.count
    }
    
    func getAllTracks() async -> [Track] {
        Array(tracks.values)
    }
}

// MARK: - Helper Functions

extension XCTestCase {
    func createTestTrack(
        id: UUID,
        title: String,
        artist: String = "Test Artist",
        rating: Int? = nil
    ) -> Track {
        Track(
            id: id,
            title: title,
            artist: artist,
            album: "Test Album",
            duration: 180.0,
            filePath: "/path/to/\(title).mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100,
            rating: rating
        )
    }
}
