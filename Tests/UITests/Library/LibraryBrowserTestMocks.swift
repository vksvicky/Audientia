//
//  LibraryBrowserTestMocks.swift
//  UITests
//
//  Shared mocks for library browser tests
//

@testable import Audientia
@testable import DataLayer
import Foundation
@testable import Shared

actor MockLibraryIndexer: LibraryIndexerProtocol {
    private var storedTracks: [Track] = []
    private var shouldThrowError = false
    private(set) var lastError: Error?
    
    func setTracks(_ tracks: [Track]) {
        storedTracks = tracks
    }
    
    func setShouldThrowError(_ shouldThrow: Bool) async {
        shouldThrowError = shouldThrow
    }
    
    func index(tracks: [Track]) async throws {
        storedTracks.append(contentsOf: tracks)
    }
    
    func remove(track: Track) async throws {
        storedTracks.removeAll { $0.id == track.id }
    }
    
    func clear() async throws {
        storedTracks.removeAll()
    }
    
    func getTrack(by id: UUID) async -> Track? {
        storedTracks.first { $0.id == id }
    }
    
    func getIndexedTrackCount() async -> Int {
        storedTracks.count
    }
    
    func getAllTracks() async -> [Track] {
        // Note: Protocol doesn't allow throwing, so return empty array when error should occur
        if shouldThrowError {
            lastError = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
            return []
        }
        lastError = nil
        return storedTracks
    }
}

actor MockArtworkExtractor: ArtworkExtractorProtocol {
    private(set) var requestedTrackIDs: [UUID] = []
    private var artworkToReturn: TrackArtwork?

    func extractArtwork(for track: Track) async -> TrackArtwork? {
        requestedTrackIDs.append(track.id)
        return artworkToReturn
    }
    
    func setArtworkToReturn(_ artwork: TrackArtwork?) {
        artworkToReturn = artwork
    }
    
    func getRequestedTrackIDs() -> [UUID] {
        requestedTrackIDs
    }
    
    func clearRequestedTrackIDs() {
        requestedTrackIDs.removeAll()
    }
}

actor MockLibraryViewConfigurationManager: LibraryViewConfigurationManagerProtocol {
    private(set) var configuration: LibraryViewConfiguration = .default
    
    func setConfiguration(_ config: LibraryViewConfiguration) {
        configuration = config
    }
    
    func saveConfiguration(_ config: LibraryViewConfiguration) async throws {
        configuration = config
    }
    
    func loadConfiguration() async -> LibraryViewConfiguration {
        configuration
    }
    
    func resetToDefault() async throws {
        configuration = .default
    }
}
