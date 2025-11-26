//
//  HeuristicArtworkExtractor.swift
//  DataLayer
//
//  Attempts to find artwork by inspecting sidecar image files located next to the track.
//

import Foundation
import Shared

public actor HeuristicArtworkExtractor: ArtworkExtractorProtocol {
    private let fileManager: FileManager
    private let maxFileSize: Int
    private let candidateNames = ["cover", "folder", "front", "album"]
    private let supportedExtensions = ["png", "jpg", "jpeg", "gif"]

    public init(
        fileManager: FileManager = .default,
        maxFileSize: Int = 2 * 1024 * 1024
    ) {
        self.fileManager = fileManager
        self.maxFileSize = maxFileSize
    }

    public func extractArtwork(for track: Track) async -> TrackArtwork? {
        let trackURL = URL(fileURLWithPath: track.filePath)
        let directoryURL = trackURL.deletingLastPathComponent()
        var searchOrder = [trackURL.deletingPathExtension().lastPathComponent]
        searchOrder.append(contentsOf: candidateNames)

        for basename in searchOrder {
            for ext in supportedExtensions {
                let candidate = directoryURL.appendingPathComponent("\(basename).\(ext)")
                if let artwork = tryLoadArtwork(at: candidate) {
                    return artwork
                }
            }
        }

        return nil
    }

    private func tryLoadArtwork(at url: URL) -> TrackArtwork? {
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        guard let data = try? Data(contentsOf: url), data.count <= maxFileSize else { return nil }
        guard let mimeType = mimeType(forExtension: url.pathExtension.lowercased()) else { return nil }
        return TrackArtwork(data: data, mimeType: mimeType, source: .sidecar(url: url))
    }

    private func mimeType(forExtension ext: String) -> String? {
        switch ext {
        case "png":
            return "image/png"
        case "jpg", "jpeg":
            return "image/jpeg"
        case "gif":
            return "image/gif"
        default:
            return nil
        }
    }
}
