//
//  LibraryBrowserTestMocks.swift
//  UITests
//
//  Shared mocks for library browser tests
//

import Foundation

@testable import Audientia
@testable import Shared

actor MockLibraryIndexer: LibraryIndexerProtocol {
    private var storedTracks: [Track] = []
    
    func setTracks(_ tracks: [Track]) {
        storedTracks = tracks
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
        storedTracks
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
