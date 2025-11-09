//
//  MP4Parser.swift
//  MetadataEngine
//
//  Parser for MP4/M4A metadata tags
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

// swiftlint:disable:file type_body_length function_body_length cyclomatic_complexity
/// Parser for MP4/M4A metadata tags
public final class MP4Parser: TagParserProtocol, @unchecked Sendable {
    
    /// Supported file extensions for MP4 (MP4, M4A)
    public let supportedExtensions: Set<String> = ["mp4", "m4a"]
    
    public init() {}
    
    /// Check if this parser can handle the given file
    /// - Parameter fileURL: The file URL to check
    /// - Returns: True if this parser can handle the file
    public func canParse(fileURL: URL) -> Bool {
        let fileExtension = fileURL.pathExtension.lowercased()
        return supportedExtensions.contains(fileExtension)
    }
    
    /// Parse tags from an audio file
    /// - Parameter fileURL: The URL of the audio file
    /// - Returns: Parsed metadata as a Track object, or nil if parsing fails
    /// - Throws: Error if parsing fails
    public func parse(fileURL: URL) async throws -> Track? {
        // Check if file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw TagParserError.fileNotFound(fileURL)
        }
        
        // Read file data
        let fileData: Data
        do {
            fileData = try Data(contentsOf: fileURL)
        } catch {
            throw TagParserError.readError(fileURL, error)
        }
        
        // Check for MP4 file (must have ftyp box)
        guard fileData.count >= 8 else {
            throw TagParserError.corruptedTag("MP4")
        }
        
        // Find and validate ftyp box
        guard let ftypOffset = findBox(data: fileData, boxType: "ftyp", startOffset: 0) else {
            // No ftyp box found - not a valid MP4 file
            throw TagParserError.invalidTagFormat("MP4")
        }
        
        // Get ftyp box size to skip past it
        let ftypSize = readBoxSize(data: fileData, offset: ftypOffset)
        
        // Find moov box (contains metadata) - start searching after ftyp box
        guard let moovOffset = findBox(data: fileData, boxType: "moov", startOffset: ftypOffset + ftypSize) else {
            // No moov box found - no metadata present
            return nil
        }
        
        // Parse metadata from moov box
        let metadata = try parseMetadataFromMoov(data: fileData, moovOffset: moovOffset)
        
        // If no metadata found, return nil
        // Check if we have any metadata atoms (even if empty, the atom exists)
        // Empty strings mean the atom exists but is empty, nil means no atom was found
        let hasAnyMetadata = metadata.title != nil ||  // Empty string means atom exists
                            metadata.artist != nil ||
                            metadata.album != nil ||
                            metadata.year != nil ||
                            metadata.trackNumber != nil ||
                            metadata.discNumber != nil ||
                            metadata.genre != nil
        
        guard hasAnyMetadata else {
            return nil
        }
        
        // Extract file metadata
        let fileSize = Int64(fileData.count)
        let fileName = fileURL.deletingPathExtension().lastPathComponent
        
        // Return Track with parsed metadata or fallback to defaults
        let finalTitle: String
        if let title = metadata.title, !title.isEmpty {
            finalTitle = title
        } else {
            finalTitle = fileName
        }
        
        let finalArtist: String
        if let artist = metadata.artist, !artist.isEmpty {
            finalArtist = artist
        } else {
            finalArtist = "Unknown Artist"
        }
        
        let finalAlbum: String
        if let album = metadata.album, !album.isEmpty {
            finalAlbum = album
        } else {
            finalAlbum = "Unknown Album"
        }
        
        return Track(
            title: finalTitle,
            artist: finalArtist,
            album: finalAlbum,
            duration: 0.0, // Duration would need to be extracted from audio stream
            filePath: fileURL.path,
            fileSize: fileSize,
            bitrate: 0, // Bitrate would need to be extracted from audio stream
            sampleRate: 0, // Sample rate would need to be extracted from audio stream
            year: metadata.year,
            trackNumber: metadata.trackNumber,
            discNumber: metadata.discNumber,
            genre: (metadata.genre != nil && !(metadata.genre?.isEmpty ?? true)) ? metadata.genre : nil
        )
    }
    
    // MARK: - MP4 Box Structure Parsing
    
    /// Find a box of a specific type in the MP4 file
    /// - Parameters:
    ///   - data: The file data
    ///   - boxType: The 4-character box type to find
    ///   - startOffset: The offset to start searching from
    /// - Returns: The offset of the box if found, nil otherwise
    private func findBox(data: Data, boxType: String, startOffset: Int) -> Int? {
        var offset = startOffset
        
        while offset < data.count - 8 {
            // Read box size (4 bytes, big-endian)
            guard offset + 8 <= data.count else {
                break
            }
            
            let sizeBytes = data.subdata(in: offset..<(offset + 4))
            let boxSize = readUInt32BigEndian(sizeBytes)
            
            // Check for invalid or very large box size
            guard boxSize >= 8, boxSize <= data.count - offset else {
                offset += 1
                continue
            }
            
            // Read box type (4 bytes)
            let typeBytes = data.subdata(in: (offset + 4)..<(offset + 8))
            guard let typeString = String(data: typeBytes, encoding: .ascii) else {
                offset += 1
                continue
            }
            
            if typeString == boxType {
                return offset
            }
            
            // Move to next box
            offset += Int(boxSize)
        }
        
        return nil
    }
    
    /// Parse metadata from moov box
    /// - Parameters:
    ///   - data: The file data
    ///   - moovOffset: The offset of the moov box
    /// - Returns: Parsed metadata
    /// - Throws: Error if parsing fails
    private func parseMetadataFromMoov(data: Data, moovOffset: Int) throws -> ParsedMetadata {
        var metadata = ParsedMetadata()
        
        // Read moov box size
        guard moovOffset + 8 <= data.count else {
            throw TagParserError.corruptedTag("MP4")
        }
        
        let moovSizeBytes = data.subdata(in: moovOffset..<(moovOffset + 4))
        let moovSize = readUInt32BigEndian(moovSizeBytes)
        
        guard moovSize >= 8, moovOffset + Int(moovSize) <= data.count else {
            throw TagParserError.corruptedTag("MP4")
        }
        
        // Find udta box within moov
        guard let udtaOffset = findBoxInRange(
            data: data,
            boxType: "udta",
            startOffset: moovOffset + 8,
            endOffset: moovOffset + Int(moovSize)
        ) else {
            return metadata // No udta box - no metadata
        }
        
        // Find meta box within udta
        guard let metaOffset = findBoxInRange(
            data: data,
            boxType: "meta",
            startOffset: udtaOffset + 8,
            endOffset: udtaOffset + readBoxSize(data: data, offset: udtaOffset)
        ) else {
            return metadata // No meta box - no metadata
        }
        
        // Skip meta box version/flags (4 bytes)
        let metaDataStart = metaOffset + 12
        
        // Find ilst box within meta
        guard let ilstOffset = findBoxInRange(
            data: data,
            boxType: "ilst",
            startOffset: metaDataStart,
            endOffset: metaOffset + readBoxSize(data: data, offset: metaOffset)
        ) else {
            return metadata // No ilst box - no metadata
        }
        
        // Parse atoms in ilst box
        try parseIlstAtoms(data: data, ilstOffset: ilstOffset, metadata: &metadata)
        
        return metadata
    }
    
    /// Find a box within a specific range
    private func findBoxInRange(data: Data, boxType: String, startOffset: Int, endOffset: Int) -> Int? {
        var offset = startOffset
        
        while offset < endOffset - 8 {
            guard offset + 8 <= data.count, offset + 8 <= endOffset else {
                break
            }
            
            let sizeBytes = data.subdata(in: offset..<(offset + 4))
            let boxSize = readUInt32BigEndian(sizeBytes)
            
            guard boxSize >= 8, offset + Int(boxSize) <= endOffset else {
                offset += 1
                continue
            }
            
            let typeBytes = data.subdata(in: (offset + 4)..<(offset + 8))
            guard let typeString = String(data: typeBytes, encoding: .ascii) else {
                offset += 1
                continue
            }
            
            if typeString == boxType {
                return offset
            }
            
            offset += Int(boxSize)
        }
        
        return nil
    }
    
    /// Read box size from offset
    private func readBoxSize(data: Data, offset: Int) -> Int {
        guard offset + 4 <= data.count else {
            return 0
        }
        let sizeBytes = data.subdata(in: offset..<(offset + 4))
        return Int(readUInt32BigEndian(sizeBytes))
    }
    
    /// Parse atoms in ilst box
    private func parseIlstAtoms(data: Data, ilstOffset: Int, metadata: inout ParsedMetadata) throws {
        let ilstSize = readBoxSize(data: data, offset: ilstOffset)
        var offset = ilstOffset + 8
        
        while offset < ilstOffset + ilstSize - 8 {
            guard offset + 8 <= data.count, offset + 8 <= ilstOffset + ilstSize else {
                break
            }
            
            let atomSize = readBoxSize(data: data, offset: offset)
            guard atomSize >= 8, offset + atomSize <= ilstOffset + ilstSize else {
                offset += 1
                continue
            }
            
            let atomTypeBytes = data.subdata(in: (offset + 4)..<(offset + 8))
            // Atom types can contain non-ASCII bytes (e.g., © = 0xA9), so use ISO-8859-1
            guard let atomType = String(data: atomTypeBytes, encoding: .isoLatin1) else {
                offset += atomSize
                continue
            }
            
            // Parse atom based on type
            switch atomType {
            case "©nam": // Title (0xA9 0x6E 0x61 0x6D)
                metadata.title = try parseTextAtom(data: data, offset: offset + 8, size: atomSize - 8)
            case "©ART": // Artist (0xA9 0x41 0x52 0x54)
                metadata.artist = try parseTextAtom(data: data, offset: offset + 8, size: atomSize - 8)
            case "©alb": // Album (0xA9 0x61 0x6C 0x62)
                metadata.album = try parseTextAtom(data: data, offset: offset + 8, size: atomSize - 8)
            case "©day": // Year (0xA9 0x64 0x61 0x79)
                if let yearString = try parseTextAtom(data: data, offset: offset + 8, size: atomSize - 8) {
                    metadata.year = extractYear(from: yearString)
                }
            case "trkn": // Track number
                metadata.trackNumber = try parseTrackNumberAtom(data: data, offset: offset + 8, size: atomSize - 8)
            case "disk": // Disc number
                metadata.discNumber = try parseDiscNumberAtom(data: data, offset: offset + 8, size: atomSize - 8)
            case "©gen": // Genre (0xA9 0x67 0x65 0x6E)
                metadata.genre = try parseTextAtom(data: data, offset: offset + 8, size: atomSize - 8)
            default:
                break
            }
            
            offset += atomSize
        }
    }
    
    /// Parse a text atom (data atom with text content)
    private func parseTextAtom(data: Data, offset: Int, size: Int) throws -> String? {
        guard offset + 8 <= data.count, size >= 8 else {
            return nil
        }
        
        // The data atom should be at the start of the atom content
        // Check if "data" box type is at offset + 4
        guard offset + 8 <= data.count else {
            return nil
        }
        
        let typeBytes = data.subdata(in: (offset + 4)..<(offset + 8))
        guard let typeString = String(data: typeBytes, encoding: .ascii),
              typeString == "data" else {
            // Try searching for it (in case there's padding or other structure)
            guard let dataOffset = findBoxInRange(
                data: data,
                boxType: "data",
                startOffset: offset,
                endOffset: offset + size
            ) else {
                return nil
            }
            // Use the found offset
            return try parseDataAtomContent(data: data, dataOffset: dataOffset, atomContentEnd: offset + size)
        }
        
        // Data atom is at the start - use offset directly
        return try parseDataAtomContent(data: data, dataOffset: offset, atomContentEnd: offset + size)
    }
    
    /// Parse the content of a data atom
    private func parseDataAtomContent(data: Data, dataOffset: Int, atomContentEnd: Int) throws -> String? {
        // Read data atom size
        let dataAtomSize = readBoxSize(data: data, offset: dataOffset)
        guard dataAtomSize >= 16, dataOffset + dataAtomSize <= atomContentEnd else {
            return nil
        }
        
        // Data atom structure:
        // - Box header: 8 bytes (size + type)
        // - Version/flags: 4 bytes
        // - Locale: 4 bytes
        // - Text data: variable
        // Total header = 16 bytes
        let textDataStart = dataOffset + 16
        let textDataSize = dataAtomSize - 16
        
        // Allow empty text data (textDataSize can be 0 for empty atoms)
        if textDataSize == 0 {
            return ""
        }
        
        guard textDataStart + textDataSize <= data.count else {
            return nil
        }
        
        let textData = data.subdata(in: textDataStart..<(textDataStart + textDataSize))
        
        // Remove null terminators
        let cleanedData = textData.filter { $0 != 0 }
        
        // Try UTF-8 first, then fallback to other encodings
        if let text = String(data: cleanedData, encoding: .utf8) {
            return text
        }
        
        if let text = String(data: cleanedData, encoding: .utf16) {
            return text
        }
        
        if let text = String(data: cleanedData, encoding: .isoLatin1) {
            return text
        }
        
        return nil
    }
    
    /// Parse track number atom (binary format)
    private func parseTrackNumberAtom(data: Data, offset: Int, size: Int) throws -> Int? {
        guard offset + 8 <= data.count, size >= 8 else {
            return nil
        }
        
        // Track number format: 4 bytes reserved (0) + 2 bytes track number (big-endian) + 2 bytes total tracks
        let trackNumberBytes = data.subdata(in: (offset + 4)..<(offset + 6))
        let trackNumber = readUInt16BigEndian(trackNumberBytes)
        
        return trackNumber > 0 ? Int(trackNumber) : nil
    }
    
    /// Parse disc number atom (binary format)
    private func parseDiscNumberAtom(data: Data, offset: Int, size: Int) throws -> Int? {
        guard offset + 8 <= data.count, size >= 8 else {
            return nil
        }
        
        // Disc number format: 4 bytes reserved (0) + 2 bytes disc number (big-endian) + 2 bytes total discs
        let discNumberBytes = data.subdata(in: (offset + 4)..<(offset + 6))
        let discNumber = readUInt16BigEndian(discNumberBytes)
        
        return discNumber > 0 ? Int(discNumber) : nil
    }
    
    /// Extract year from date string (e.g., "2023" or "2023-01-01")
    private func extractYear(from dateString: String) -> Int? {
        // Try to extract 4-digit year from the beginning
        let yearString = String(dateString.prefix(4))
        guard yearString.count == 4,
              let year = Int(yearString),
              year > 0 else {
            return nil
        }
        return year
    }
    
    // MARK: - Helper Functions
    
    /// Read UInt32 in big-endian format
    private func readUInt32BigEndian(_ data: Data) -> UInt32 {
        guard data.count >= 4 else {
            return 0
        }
        return UInt32(data[0]) << 24 | UInt32(data[1]) << 16 | UInt32(data[2]) << 8 | UInt32(data[3])
    }
    
    /// Read UInt16 in big-endian format
    private func readUInt16BigEndian(_ data: Data) -> UInt16 {
        guard data.count >= 2 else {
            return 0
        }
        return UInt16(data[0]) << 8 | UInt16(data[1])
    }
    
    // MARK: - Parsed Metadata Structure
    
    private struct ParsedMetadata {
        var title: String?
        var artist: String?
        var album: String?
        var year: Int?
        var trackNumber: Int?
        var discNumber: Int?
        var genre: String?
        
        var hasAnyMetadata: Bool {
            title != nil || artist != nil || album != nil || year != nil ||
            trackNumber != nil || discNumber != nil || genre != nil
        }
    }
}
