//
//  MinimisedPlayerArtworkHelper.swift
//  Audientia
//
//  Helper functions for loading artwork in minimized player view
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import AVFoundation
import Foundation
import Shared

/// Helper functions for extracting artwork images for tracks
enum MinimisedPlayerArtworkHelper {
    /// Extracts artwork for the given track, preferring embedded artwork and falling back to sidecar images.
    static func extractArtworkImage(for track: Track) async -> NSImage? {
        let fileURL = URL(fileURLWithPath: track.filePath)

        // 1) Try embedded artwork via AVFoundation
        if let embeddedData = await extractEmbeddedArtworkData(from: fileURL),
           let image = NSImage(data: embeddedData) {
            return image
        }

        // 2) Fallback to sidecar files next to the track
        if let sidecarData = try? loadSidecarArtworkData(for: fileURL),
           let image = NSImage(data: sidecarData) {
            return image
        }

        return nil
    }

    private static func extractEmbeddedArtworkData(from fileURL: URL) async -> Data? {
        let asset = AVURLAsset(url: fileURL)
        do {
            let metadata = try await asset.load(.metadata)

            for item in metadata {
                let commonKey = item.commonKey
                let identifier = item.identifier
                
                // Check for artwork by commonKey (works across all key spaces)
                if commonKey == .commonKeyArtwork,
                   let data = try? await item.load(.dataValue) {
                    return data
                }
                
                // Check for artwork by identifier (for files without commonKey mapping)
                if let idRaw = identifier?.rawValue {
                    // iTunes/M4A: identifier contains "covr"
                    if idRaw.contains("covr"),
                       let data = try? await item.load(.dataValue) {
                        return data
                    }
                    
                    // ID3/MP3: identifier is "APIC" or contains "PICTURE"
                    if idRaw == "APIC" || idRaw.contains("PICTURE"),
                       let data = try? await item.load(.dataValue) {
                        return data
                    }
                }
            }
        } catch {
            // Silently ignore errors and fall back to sidecar files
        }
        return nil
    }

    private static func loadSidecarArtworkData(for fileURL: URL) throws -> Data? {
        let directoryURL = fileURL.deletingLastPathComponent()
        let baseName = fileURL.deletingPathExtension().lastPathComponent
        let candidateNames = [baseName, "cover", "folder", "front", "album"]
        let supportedExtensions = ["png", "jpg", "jpeg", "gif"]

        for name in candidateNames {
            for ext in supportedExtensions {
                let candidate = directoryURL.appendingPathComponent("\(name).\(ext)")
                if FileManager.default.fileExists(atPath: candidate.path),
                   let data = try? Data(contentsOf: candidate),
                   !data.isEmpty {
                    return data
                }
            }
        }
        return nil
    }
}
