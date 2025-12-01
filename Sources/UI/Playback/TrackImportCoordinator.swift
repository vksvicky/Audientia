//
//  TrackImportCoordinator.swift
//  Audientia
//
//  Coordinates track import from files, drag-and-drop, and file picker
//

import AudioCore
import DataLayer
import Foundation
import os.log
import Shared

/// Errors that can occur during track import
public enum TrackImportError: Error, LocalizedError, Equatable {
    case unsupportedFormat
    case fileNotFound
    case importFailed(String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "Unsupported audio file format"
        case .fileNotFound:
            return "File not found"
        case let .importFailed(reason):
            return "Import failed: \(reason)"
        }
    }
}

/// Coordinates importing audio files and queueing them for playback
@MainActor
public final class TrackImportCoordinator: ObservableObject {
    private let audioEngine: AudioEngineProtocol
    private let indexer: LibraryIndexerProtocol
    private let logger = Logger.userInterface

    public init(
        audioEngine: AudioEngineProtocol,
        indexer: LibraryIndexerProtocol
    ) {
        self.audioEngine = audioEngine
        self.indexer = indexer
    }

    /// Import a single audio file
    /// - Parameter url: File URL to import
    /// - Throws: TrackImportError if import fails
    public func importFile(url: URL) async throws {
        try await importFiles(urls: [url])
    }

    /// Import multiple audio files
    /// - Parameter urls: File URLs to import
    /// - Throws: TrackImportError if any file fails to import
    /// - Note: When importing via drag-and-drop, the first track will immediately start playing,
    ///         replacing any currently playing track. This provides immediate user feedback.
    public func importFiles(urls: [URL]) async throws {
        guard !urls.isEmpty else { return }

        var tracks: [Track] = []

        for url in urls {
            // Validate file exists
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw TrackImportError.fileNotFound
            }

            // Validate format
            let fileExtension = url.pathExtension.lowercased()
            guard AudioFormats.isSupported(fileExtension) else {
                throw TrackImportError.unsupportedFormat
            }

            // Create track from file
            let track = createTrack(from: url)
            tracks.append(track)
        }

        // Index tracks in library
        do {
            try await indexer.index(tracks: tracks)
            logger.info("Indexed \(tracks.count) tracks")
        } catch {
            logger.error("Failed to index tracks: \(error.localizedDescription)")
            throw TrackImportError.importFailed("Indexing failed: \(error.localizedDescription)")
        }

        // Queue tracks for playback
        for track in tracks {
            audioEngine.addToQueue(track)
        }

        logger.info("Queued \(tracks.count) tracks for playback")

        // Always load and play first track for immediate user feedback
        // BDD: As a user, when I drag-and-drop a track, I want it to play immediately
        if let firstTrack = tracks.first {
            do {
                try await audioEngine.loadTrack(firstTrack)
                try await audioEngine.play()
                logger.info("Started playback for imported track: \(firstTrack.title, privacy: .public)")
            } catch {
                logger.error("Failed to play imported track: \(error.localizedDescription)")
                throw TrackImportError.importFailed("Playback failed: \(error.localizedDescription)")
            }
        }
    }

    /// Create a Track from a file URL
    /// - Parameter fileURL: The file URL
    /// - Returns: A Track object with basic file information
    private func createTrack(from fileURL: URL) -> Track {
        let fileName = fileURL.deletingPathExtension().lastPathComponent
        let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0

        return Track(
            id: UUID(),
            title: fileName,
            artist: "Unknown Artist",
            album: "Unknown Album",
            duration: 0.0,
            filePath: fileURL.path,
            fileSize: Int64(fileSize),
            bitrate: 0,
            sampleRate: 0,
            year: nil,
            trackNumber: nil,
            discNumber: nil
        )
    }
}
