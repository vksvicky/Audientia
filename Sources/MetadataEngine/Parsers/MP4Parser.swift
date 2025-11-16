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
        let fileData = try readFileData(fileURL: fileURL)
        guard let moovOffset = try findMoovBox(data: fileData) else {
            return nil
        }
        let metadata = try parseMetadataFromMoov(data: fileData, moovOffset: moovOffset)
        guard hasAnyMetadata(metadata) else {
            return nil
        }
        return createTrackFromMetadata(metadata: metadata, fileURL: fileURL, fileData: fileData)
    }
    
    private func readFileData(fileURL: URL) throws -> Data {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw TagParserError.fileNotFound(fileURL)
        }
        do {
            return try Data(contentsOf: fileURL)
        } catch {
            throw TagParserError.readError(fileURL, error)
        }
    }
    
    private func findMoovBox(data: Data) throws -> Int? {
        guard data.count >= 8 else {
            throw TagParserError.corruptedTag("MP4")
        }
        guard let ftypOffset = findBox(data: data, boxType: "ftyp", startOffset: 0) else {
            throw TagParserError.invalidTagFormat("MP4")
        }
        let ftypSize = readBoxSize(data: data, offset: ftypOffset)
        return findBox(data: data, boxType: "moov", startOffset: ftypOffset + ftypSize)
    }
    
    private func createTrackFromMetadata(metadata: ParsedMetadata, fileURL: URL, fileData: Data) -> Track {
        let fileSize = Int64(fileData.count)
        let fileName = fileURL.deletingPathExtension().lastPathComponent
        return createTrack(from: metadata, fileName: fileName, filePath: fileURL.path, fileSize: fileSize)
    }
    
    // MARK: - Helper Methods
    
    /// Check if metadata has any valid fields
    private func hasAnyMetadata(_ metadata: ParsedMetadata) -> Bool {
        metadata.title != nil || metadata.artist != nil || metadata.album != nil ||
        metadata.year != nil || metadata.trackNumber != nil ||
        metadata.discNumber != nil || metadata.genre != nil
    }
    
    /// Create a Track from parsed metadata with fallback values
    private func createTrack(
        from metadata: ParsedMetadata,
        fileName: String,
        filePath: String,
        fileSize: Int64
    ) -> Track {
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
        
        let finalGenre = metadata.genre?.isEmpty == false ? metadata.genre : nil
        
        return Track(
            title: finalTitle,
            artist: finalArtist,
            album: finalAlbum,
            duration: 0.0, // Duration would need to be extracted from audio stream
            filePath: filePath,
            fileSize: fileSize,
            bitrate: 0, // Bitrate would need to be extracted from audio stream
            sampleRate: 0, // Sample rate would need to be extracted from audio stream
            year: metadata.year,
            trackNumber: metadata.trackNumber,
            discNumber: metadata.discNumber,
            genre: finalGenre
        )
    }
    
    // MARK: - MP4 Box Structure Parsing
}

// MARK: - Box Parsing Extension

private extension MP4Parser {
    /// Find a box of a specific type in the MP4 file
    /// - Parameters:
    ///   - data: The file data
    ///   - boxType: The 4-character box type to find
    ///   - startOffset: The offset to start searching from
    /// - Returns: The offset of the box if found, nil otherwise
    func findBox(data: Data, boxType: String, startOffset: Int) -> Int? {
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
    func parseMetadataFromMoov(data: Data, moovOffset: Int) throws -> ParsedMetadata {
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
    func findBoxInRange(data: Data, boxType: String, startOffset: Int, endOffset: Int) -> Int? {
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
    func readBoxSize(data: Data, offset: Int) -> Int {
        guard offset + 4 <= data.count else {
            return 0
        }
        let sizeBytes = data.subdata(in: offset..<(offset + 4))
        return Int(readUInt32BigEndian(sizeBytes))
    }
    
    /// Parse a single atom and update metadata
    func parseAtom(
        atomType: String,
        data: Data,
        offset: Int,
        size: Int,
        metadata: inout ParsedMetadata
    ) throws {
        if atomType == "©nam" || atomType == "©ART" || atomType == "©alb" || atomType == "©gen" {
            try parseTextAtomIntoMetadata(
                atomType: atomType,
                data: data,
                offset: offset,
                size: size,
                metadata: &metadata
            )
        } else if atomType == "©day" {
            try parseYearAtom(data: data, offset: offset, size: size, metadata: &metadata)
        } else if atomType == "trkn" {
            metadata.trackNumber = try parseTrackNumberAtom(data: data, offset: offset, size: size)
        } else if atomType == "disk" {
            metadata.discNumber = try parseDiscNumberAtom(data: data, offset: offset, size: size)
        }
    }
    
    func parseTextAtomIntoMetadata(
        atomType: String,
        data: Data,
        offset: Int,
        size: Int,
        metadata: inout ParsedMetadata
    ) throws {
        let text = try parseTextAtom(data: data, offset: offset, size: size)
        switch atomType {
        case "©nam":
            metadata.title = text
        case "©ART":
            metadata.artist = text
        case "©alb":
            metadata.album = text
        case "©gen":
            metadata.genre = text
        default:
            break
        }
    }
    
    func parseYearAtom(data: Data, offset: Int, size: Int, metadata: inout ParsedMetadata) throws {
        if let yearString = try parseTextAtom(data: data, offset: offset, size: size) {
            metadata.year = extractYear(from: yearString)
        }
    }
    
    /// Parse atoms in ilst box
    func parseIlstAtoms(data: Data, ilstOffset: Int, metadata: inout ParsedMetadata) throws {
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
            try parseAtom(atomType: atomType, data: data, offset: offset + 8, size: atomSize - 8, metadata: &metadata)
            
            offset += atomSize
        }
    }
    
    /// Parse a text atom (data atom with text content)
    func parseTextAtom(data: Data, offset: Int, size: Int) throws -> String? {
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
    func parseDataAtomContent(data: Data, dataOffset: Int, atomContentEnd: Int) throws -> String? {
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
    func parseTrackNumberAtom(data: Data, offset: Int, size: Int) throws -> Int? {
        guard offset + 8 <= data.count, size >= 8 else {
            return nil
        }
        
        // Check if there's a data atom inside (typical MP4 format)
        let typeBytes = data.subdata(in: (offset + 4)..<(offset + 8))
        if let typeString = String(data: typeBytes, encoding: .ascii), typeString == "data" {
            // Data atom format: 8 bytes header + 4 bytes flags + 4 bytes locale + 2 bytes track number + 2 bytes total
            // Track number is at: offset + 8 (data header) + 4 (flags) + 4 (locale) = offset + 16
            guard offset + 16 + 2 <= data.count else {
                return nil
            }
            let trackNumberBytes = data.subdata(in: (offset + 16)..<(offset + 18))
            let trackNumber = readUInt16BigEndian(trackNumberBytes)
            return trackNumber > 0 ? Int(trackNumber) : nil
        }
        
        // Direct format: 4 bytes reserved (0) + 2 bytes track number (big-endian) + 2 bytes total tracks
        guard offset + 6 <= data.count else {
            return nil
        }
        let trackNumberBytes = data.subdata(in: (offset + 4)..<(offset + 6))
        let trackNumber = readUInt16BigEndian(trackNumberBytes)
        
        return trackNumber > 0 ? Int(trackNumber) : nil
    }
    
    /// Parse disc number atom (binary format)
    func parseDiscNumberAtom(data: Data, offset: Int, size: Int) throws -> Int? {
        guard offset + 8 <= data.count, size >= 8 else {
            return nil
        }
        
        // Check if there's a data atom inside (typical MP4 format)
        let typeBytes = data.subdata(in: (offset + 4)..<(offset + 8))
        if let typeString = String(data: typeBytes, encoding: .ascii), typeString == "data" {
            // Data atom format: 8 bytes header + 4 bytes flags + 4 bytes locale + 2 bytes disc number + 2 bytes total
            // Disc number is at: offset + 8 (data header) + 4 (flags) + 4 (locale) = offset + 16
            guard offset + 16 + 2 <= data.count else {
                return nil
            }
            let discNumberBytes = data.subdata(in: (offset + 16)..<(offset + 18))
            let discNumber = readUInt16BigEndian(discNumberBytes)
            return discNumber > 0 ? Int(discNumber) : nil
        }
        
        // Direct format: 4 bytes reserved (0) + 2 bytes disc number (big-endian) + 2 bytes total discs
        guard offset + 6 <= data.count else {
            return nil
        }
        let discNumberBytes = data.subdata(in: (offset + 4)..<(offset + 6))
        let discNumber = readUInt16BigEndian(discNumberBytes)
        
        return discNumber > 0 ? Int(discNumber) : nil
    }
    
    /// Extract year from date string (e.g., "2023" or "2023-01-01")
    func extractYear(from dateString: String) -> Int? {
        // Try to extract 4-digit year from the beginning
        let yearString = String(dateString.prefix(4))
        guard yearString.count == 4,
              let year = Int(yearString),
              year > 0 else {
            return nil
        }
        return year
    }
    
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

// MARK: - Helper Functions Extension

private extension MP4Parser {
    /// Read UInt32 in big-endian format
    func readUInt32BigEndian(_ data: Data) -> UInt32 {
        guard data.count >= 4 else {
            return 0
        }
        return UInt32(data[0]) << 24 | UInt32(data[1]) << 16 | UInt32(data[2]) << 8 | UInt32(data[3])
    }
    
    /// Read UInt16 in big-endian format
    func readUInt16BigEndian(_ data: Data) -> UInt16 {
        guard data.count >= 2 else {
            return 0
        }
        return UInt16(data[0]) << 8 | UInt16(data[1])
    }
}
