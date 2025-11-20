//
//  DeviceSyncTrackProvider.swift
//  DataLayer
//
//  Provides tracks for Device Sync operations by leveraging the library indexer/scanner.
//

import Foundation
import Shared

public protocol DeviceSyncTrackProviderProtocol: Sendable {
    func loadTracks() async -> [Track]
    func currentTracks() async -> [Track]
}

public actor DeviceSyncTrackProvider: DeviceSyncTrackProviderProtocol {
    
    public struct Config {
        public var fallbackDirectories: [URL]
        public var maxTracks: Int
        
        public init(
            fallbackDirectories: [URL] = DeviceSyncTrackProvider.defaultDirectories,
            maxTracks: Int = 10_000
        ) {
            self.fallbackDirectories = fallbackDirectories
            self.maxTracks = maxTracks
        }
    }
    
    private let indexer: LibraryIndexerProtocol
    private let scanner: LibraryScannerProtocol
    private let config: Config
    private var cache: [Track] = []
    
    public init(
        indexer: LibraryIndexerProtocol = LibraryIndexer(),
        scanner: LibraryScannerProtocol = LibraryScanner(),
        config: Config = Config()
    ) {
        self.indexer = indexer
        self.scanner = scanner
        self.config = config
    }
    
    public func currentTracks() async -> [Track] {
        if !cache.isEmpty {
            return cache
        }
        let indexed = await indexer.getAllTracks()
        if !indexed.isEmpty {
            cache = indexed
        }
        return cache
    }
    
    public func loadTracks() async -> [Track] {
        if !cache.isEmpty {
            return cache
        }
        
        let indexed = await indexer.getAllTracks()
        if !indexed.isEmpty {
            cache = indexed
            return cache
        }
        
        var aggregated: [Track] = []
        for directory in config.fallbackDirectories.prefix(3) { // limit to avoid long scans
            if aggregated.count >= config.maxTracks {
                break
            }
            guard FileManager.default.fileExists(atPath: directory.path, isDirectory: nil) else {
                continue
            }
            if let scanned = try? await scanner.scan(directory: directory) {
                aggregated.append(contentsOf: scanned)
            }
        }
        
        if !aggregated.isEmpty {
            do {
                try await indexer.index(tracks: aggregated)
            } catch {
                // Ignore indexing errors; we can still return scanned tracks
            }
            cache = aggregated
            return cache
        }
        
        return []
    }
    
    public static var defaultDirectories: [URL] {
        var directories: [URL] = []
        if let music = FileManager.default.urls(for: .musicDirectory, in: .userDomainMask).first {
            directories.append(music.appendingPathComponent("Audientia", isDirectory: true))
            directories.append(music)
        }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        if let documents {
            directories.append(documents)
        }
        return directories
    }
}
