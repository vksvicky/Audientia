//
//  AVFoundationArtworkExtractor.swift
//  DataLayer
//
//  Extracts embedded artwork from audio files using AVFoundation
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import AVFoundation
import Foundation
import os.log
import Shared

/// Extracts embedded artwork from audio files using AVFoundation
public actor AVFoundationArtworkExtractor: ArtworkExtractorProtocol {
    private let logger = Logger.dataLayer
    
    public init() {}
    
    public func extractArtwork(for track: Track) async -> TrackArtwork? {
        let fileURL = URL(fileURLWithPath: track.filePath)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            logger.debug("File does not exist: \(fileURL.path)")
            return nil
        }
        
        let asset = AVURLAsset(url: fileURL)
        
        do {
            // Load metadata
            let metadata = try await asset.load(.metadata)
            
            // Look for artwork in common metadata formats
            for item in metadata {
                // Check for common artwork metadata keys
                if let artworkData = await extractArtworkData(from: item) {
                    let mimeType = determineMimeType(from: artworkData)
                    return TrackArtwork(
                        data: artworkData,
                        mimeType: mimeType,
                        source: .embedded
                    )
                }
            }
            
            logger.debug("No embedded artwork found in: \(track.title)")
            return nil
        } catch {
            logger.error("Failed to extract artwork from \(track.title): \(error.localizedDescription)")
            return nil
        }
    }
    
    private func extractArtworkData(from metadataItem: AVMetadataItem) async -> Data? {
        // Access properties directly (they're not async)
        let commonKey = metadataItem.commonKey
        let identifier = metadataItem.identifier
        
        // Check for artwork by commonKey (works across all key spaces)
        if commonKey == .commonKeyArtwork {
            return await loadArtworkData(from: metadataItem)
        }
        
        // Check for artwork by identifier (for files without commonKey mapping)
        if let idRaw = identifier?.rawValue {
            // iTunes/M4A: identifier contains "covr"
            if idRaw.contains("covr") {
                return await loadArtworkData(from: metadataItem)
            }
            
            // ID3/MP3: identifier is "APIC" or contains "PICTURE"
            if idRaw == "APIC" || idRaw.contains("PICTURE") {
                return await loadArtworkData(from: metadataItem)
            }
        }
        
        return nil
    }
    
    private func loadArtworkData(from metadataItem: AVMetadataItem) async -> Data? {
        do {
            // Try to load as data
            if let dataValue = try await metadataItem.load(.dataValue) {
                return dataValue
            }
            
            // Try to load as string (base64 encoded)
            if let stringValue = try await metadataItem.load(.stringValue),
               let data = Data(base64Encoded: stringValue) {
                return data
            }
            
            // For MP4/M4A, the artwork might be in the value property
            if let value = try await metadataItem.load(.value) as? Data {
                return value
            }
            
            // Try NSImage conversion for macOS
            #if os(macOS)
            if let value = try await metadataItem.load(.value) as? NSImage,
               let tiffData = value.tiffRepresentation,
               let bitmapImage = NSBitmapImageRep(data: tiffData),
               let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                return pngData
            }
            #endif
            
            return nil
        } catch {
            logger.debug("Failed to load artwork data: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func determineMimeType(from data: Data) -> String {
        // Check file signature (magic bytes)
        guard data.count >= 4 else { return "image/jpeg" }
        
        let bytes = data.prefix(4)
        
        // PNG signature: 89 50 4E 47
        if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            return "image/png"
        }
        
        // JPEG signature: FF D8 FF
        if bytes.starts(with: [0xFF, 0xD8, 0xFF]) {
            return "image/jpeg"
        }
        
        // GIF signature: 47 49 46 38
        if bytes.starts(with: [0x47, 0x49, 0x46, 0x38]) {
            return "image/gif"
        }
        
        // Default to JPEG
        return "image/jpeg"
    }
}
