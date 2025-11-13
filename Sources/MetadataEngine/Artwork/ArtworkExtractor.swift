//
//  ArtworkExtractor.swift
//  MetadataEngine
//
//  Artwork extraction from audio files
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import Foundation

/// Errors that can occur during artwork extraction
public enum ArtworkExtractorError: Error {
    case unsupportedFormat
    case fileNotFound
    case noArtworkFound
    case extractionFailed
    case invalidImageData
}

/// Artwork data extracted from audio files
public struct ArtworkData: Sendable {
    /// Image data (JPEG, PNG, etc.)
    public let data: Data
    
    /// MIME type of the image (e.g., "image/jpeg", "image/png")
    public let mimeType: String
    
    /// Image width in pixels (if available)
    public let width: Int?
    
    /// Image height in pixels (if available)
    public let height: Int?
    
    public init(data: Data, mimeType: String, width: Int? = nil, height: Int? = nil) {
        self.data = data
        self.mimeType = mimeType
        self.width = width
        self.height = height
    }
}

/// Extracts artwork from audio files
public final class ArtworkExtractor: @unchecked Sendable {
    
    /// Supported file extensions for artwork extraction
    public let supportedExtensions: Set<String> = ["mp3", "m4a", "mp4", "flac", "ogg", "opus"]
    
    /// Initialize the artwork extractor
    public init() {}
    
    /// Extract artwork from an audio file
    /// - Parameter fileURL: URL of the audio file
    /// - Returns: ArtworkData if artwork is found, nil otherwise
    /// - Throws: ArtworkExtractorError if extraction fails
    public func extractArtwork(from fileURL: URL) async throws -> ArtworkData? {
        // Validate file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw ArtworkExtractorError.fileNotFound
        }
        
        // Validate file extension
        let fileExtension = fileURL.pathExtension.lowercased()
        guard supportedExtensions.contains(fileExtension) else {
            throw ArtworkExtractorError.unsupportedFormat
        }
        
        // Route to appropriate extractor based on file type
        switch fileExtension {
        case "mp3":
            return try await extractFromMP3(fileURL: fileURL)
        case "m4a", "mp4":
            return try await extractFromMP4(fileURL: fileURL)
        case "flac", "ogg", "opus":
            return try await extractFromVorbis(fileURL: fileURL)
        default:
            throw ArtworkExtractorError.unsupportedFormat
        }
    }
    
    // MARK: - Private Extraction Methods
    
    /// Extract artwork from MP3 file (ID3v2)
    private func extractFromMP3(fileURL: URL) async throws -> ArtworkData? {
        // Read file data
        let fileData: Data
        do {
            fileData = try Data(contentsOf: fileURL)
        } catch {
            throw ArtworkExtractorError.extractionFailed
        }
        
        // Check for ID3v2 tag
        guard fileData.count >= 10,
              String(data: fileData.prefix(3), encoding: .ascii) == "ID3" else {
            return nil // No ID3v2 tag
        }
        
        // Parse ID3v2 header
        let tagSize = parseSynchsafeInteger(
            bytes: [fileData[6], fileData[7], fileData[8], fileData[9]]
        )
        
        let headerOffset = 10
        let frameDataEnd = min(headerOffset + tagSize, fileData.count)
        
        // Search for APIC frame
        return try findAndExtractAPICFrame(
            in: fileData,
            startOffset: headerOffset,
            endOffset: frameDataEnd
        )
    }
    
    /// Find and extract APIC frame from ID3v2 tag data
    private func findAndExtractAPICFrame(
        in fileData: Data,
        startOffset: Int,
        endOffset: Int
    ) throws -> ArtworkData? {
        var offset = startOffset
        while offset < endOffset - 10 {
            // Check for padding
            if fileData[offset] == 0 {
                break
            }
            
            // Parse frame ID
            guard let frameID = String(
                data: fileData.subdata(in: offset..<(offset + 4)),
                encoding: .ascii
            ) else {
                offset += 1
                continue
            }
            
            // Parse frame size
            let frameSize = parseSynchsafeInteger(
                bytes: [
                    fileData[offset + 4],
                    fileData[offset + 5],
                    fileData[offset + 6],
                    fileData[offset + 7]
                ]
            )
            
            // Check if this is an APIC frame
            if frameID == "APIC" {
                let frameContentStart = offset + 10
                guard frameContentStart + frameSize <= endOffset else {
                    break
                }
                
                let frameContent = fileData.subdata(
                    in: frameContentStart..<(frameContentStart + frameSize)
                )
                
                return try extractArtworkFromAPICFrame(frameContent)
            }
            
            offset += 10 + frameSize
        }
        
        return nil // No artwork found
    }
    
    /// Extract artwork data from ID3v2 APIC frame
    private func extractArtworkFromAPICFrame(_ frameData: Data) throws -> ArtworkData {
        guard !frameData.isEmpty else {
            throw ArtworkExtractorError.invalidImageData
        }
        
        var offset = 0
        
        // First byte: text encoding (skip, not needed for artwork extraction)
        _ = frameData[offset]
        offset += 1
        
        // MIME type (null-terminated string)
        var mimeTypeEnd = offset
        while mimeTypeEnd < frameData.count && frameData[mimeTypeEnd] != 0 {
            mimeTypeEnd += 1
        }
        
        guard mimeTypeEnd < frameData.count else {
            throw ArtworkExtractorError.invalidImageData
        }
        
        let mimeTypeData = frameData.subdata(in: offset..<mimeTypeEnd)
        let mimeType = String(data: mimeTypeData, encoding: .utf8) ?? "image/jpeg"
        offset = mimeTypeEnd + 1
        
        // Picture type (1 byte, skip)
        offset += 1
        
        // Description (null-terminated string, encoding based on first byte)
        // Skip description
        while offset < frameData.count && frameData[offset] != 0 {
            offset += 1
        }
        if offset < frameData.count {
            offset += 1 // Skip null terminator
        }
        
        // Remaining data is the image
        guard offset < frameData.count else {
            throw ArtworkExtractorError.invalidImageData
        }
        
        let imageData = frameData.subdata(in: offset..<frameData.count)
        
        // Determine dimensions if possible (for JPEG/PNG)
        let (width, height) = extractImageDimensions(data: imageData, mimeType: mimeType)
        
        return ArtworkData(
            data: imageData,
            mimeType: mimeType,
            width: width,
            height: height
        )
    }
    
    /// Extract image dimensions from image data
    private func extractImageDimensions(data: Data, mimeType: String) -> (Int?, Int?) {
        // Basic dimension extraction for JPEG and PNG
        // This is a simplified implementation
        // For production, consider using ImageIO or similar
        (nil, nil) // Dimensions extraction can be enhanced later
    }
    
    /// Parse synchsafe integer (ID3v2 format)
    private func parseSynchsafeInteger(bytes: [UInt8]) -> Int {
        guard bytes.count == 4 else { return 0 }
        return Int(bytes[0]) << 21 |
               Int(bytes[1]) << 14 |
               Int(bytes[2]) << 7 |
               Int(bytes[3])
    }
    
    /// Extract artwork from MP4/M4A file
    private func extractFromMP4(fileURL: URL) async throws -> ArtworkData? {
        // MP4 covr atom extraction not yet implemented
        // For now, return nil (no artwork found)
        nil
    }
    
    /// Extract artwork from Vorbis-based files (FLAC, OGG, Opus)
    private func extractFromVorbis(fileURL: URL) async throws -> ArtworkData? {
        // Vorbis Comments METADATA_BLOCK_PICTURE extraction not yet implemented
        // For now, return nil (no artwork found)
        nil
    }
}
