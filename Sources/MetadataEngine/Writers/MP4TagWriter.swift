//
//  MP4TagWriter.swift
//  MetadataEngine
//
//  Writer for MP4/M4A metadata tags
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Writer for MP4/M4A metadata tags
public final class MP4TagWriter: TagWriterProtocol, @unchecked Sendable {
    
    /// Supported file extensions for MP4 (MP4, M4A)
    public let supportedExtensions: Set<String> = ["mp4", "m4a"]
    
    public init() {}
    
    /// Check if this writer can handle the given file
    /// - Parameter fileURL: The file URL to check
    /// - Returns: True if this writer can handle the file
    public func canWrite(fileURL: URL) -> Bool {
        let fileExtension = fileURL.pathExtension.lowercased()
        return supportedExtensions.contains(fileExtension)
    }
    
    /// Write tags to an audio file
    /// - Parameters:
    ///   - track: The Track object containing metadata to write
    ///   - fileURL: The URL of the audio file
    /// - Throws: Error if writing fails
    public func write(track: Track, to fileURL: URL) async throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw TagWriterError.fileNotFound(fileURL)
        }
        
        // Check if file is writable
        guard FileManager.default.isWritableFile(atPath: fileURL.path) else {
            throw TagWriterError.readOnlyFile(fileURL)
        }
        
        guard canWrite(fileURL: fileURL) else {
            throw TagWriterError.unsupportedFormat(fileURL.pathExtension)
        }
        
        // Read existing file data
        let fileData: Data
        do {
            fileData = try Data(contentsOf: fileURL)
        } catch {
            throw TagWriterError.readError(fileURL, error)
        }
        
        // Find ftyp box (must be preserved)
        guard let ftypOffset = findBox(data: fileData, boxType: "ftyp", startOffset: 0) else {
            throw TagWriterError.invalidTagData("MP4 file missing ftyp box")
        }
        let ftypSize = readBoxSize(data: fileData, offset: ftypOffset)
        let ftypBox = fileData.subdata(in: ftypOffset..<(ftypOffset + ftypSize))
        
        // Find mdat box (audio data - must be preserved)
        let mdatOffset = findBox(data: fileData, boxType: "mdat", startOffset: ftypOffset + ftypSize)
        let mdatBox: Data
        if let mdatOffset = mdatOffset {
            let mdatSize = readBoxSize(data: fileData, offset: mdatOffset)
            mdatBox = fileData.subdata(in: mdatOffset..<(mdatOffset + mdatSize))
        } else {
            // No mdat box found - create empty one
            mdatBox = Data()
        }
        
        // Build moov box with metadata
        let moovBox = try buildMoovBox(with: track, existingMoovOffset: findBox(data: fileData, boxType: "moov", startOffset: ftypOffset + ftypSize))
        
        // Write new file: ftyp + moov + mdat
        var newFileData = Data()
        newFileData.append(ftypBox)
        newFileData.append(moovBox)
        newFileData.append(mdatBox)
        
        // Write to file
        do {
            try newFileData.write(to: fileURL)
        } catch {
            throw TagWriterError.writeError(fileURL, error)
        }
    }
    
    /// Update existing tags in an audio file
    /// - Parameters:
    ///   - track: The Track object containing updated metadata
    ///   - fileURL: The URL of the audio file
    /// - Throws: Error if updating fails
    public func update(track: Track, in fileURL: URL) async throws {
        // For MP4, update is the same as write (we rebuild the moov box)
        try await write(track: track, to: fileURL)
    }
    
    // MARK: - Private Methods
    
    /// Find a box of a specific type in the MP4 file
    private func findBox(data: Data, boxType: String, startOffset: Int) -> Int? {
        var offset = startOffset
        
        while offset < data.count - 8 {
            guard offset + 8 <= data.count else {
                break
            }
            
            let boxSize = readBoxSize(data: data, offset: offset)
            guard boxSize >= 8, offset + boxSize <= data.count else {
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
            
            offset += boxSize
        }
        
        return nil
    }
    
    /// Read box size from offset (big-endian)
    private func readBoxSize(data: Data, offset: Int) -> Int {
        guard offset + 4 <= data.count else {
            return 0
        }
        let sizeBytes = data.subdata(in: offset..<(offset + 4))
        var size: UInt32 = 0
        sizeBytes.withUnsafeBytes { bytes in
            size = UInt32(bigEndian: bytes.load(as: UInt32.self))
        }
        return Int(size)
    }
    
    /// Write box size (big-endian)
    private func writeBoxSize(_ size: UInt32) -> Data {
        var sizeBE = size.bigEndian
        return Data(bytes: &sizeBE, count: 4)
    }
    
    /// Build moov box with metadata
    private func buildMoovBox(with track: Track, existingMoovOffset: Int?) throws -> Data {
        var moovData = Data()
        
        // moov box header (will update size later)
        moovData.append(writeBoxSize(0)) // Placeholder for size
        moovData.append("moov".data(using: .ascii) ?? Data())
        
        // Build udta box with metadata
        let udtaBox = try buildUdtaBox(with: track)
        moovData.append(udtaBox)
        
        // Update moov box size
        let moovSize = UInt32(moovData.count)
        moovData.replaceSubrange(0..<4, with: writeBoxSize(moovSize))
        
        return moovData
    }
    
    /// Build udta (user data) box with metadata
    private func buildUdtaBox(with track: Track) throws -> Data {
        var udtaData = Data()
        
        // udta box header (will update size later)
        udtaData.append(writeBoxSize(0)) // Placeholder for size
        udtaData.append("udta".data(using: .ascii) ?? Data())
        
        // Build meta box
        let metaBox = try buildMetaBox(with: track)
        udtaData.append(metaBox)
        
        // Update udta box size
        let udtaSize = UInt32(udtaData.count)
        udtaData.replaceSubrange(0..<4, with: writeBoxSize(udtaSize))
        
        return udtaData
    }
    
    /// Build meta box with metadata
    private func buildMetaBox(with track: Track) throws -> Data {
        var metaData = Data()
        
        // meta box header (will update size later)
        metaData.append(writeBoxSize(0)) // Placeholder for size
        metaData.append("meta".data(using: .ascii) ?? Data())
        
        // Version and flags (4 bytes, all zeros)
        metaData.append(Data(repeating: 0x00, count: 4))
        
        // Build ilst box
        let ilstBox = try buildIlstBox(with: track)
        metaData.append(ilstBox)
        
        // Update meta box size
        let metaSize = UInt32(metaData.count)
        metaData.replaceSubrange(0..<4, with: writeBoxSize(metaSize))
        
        return metaData
    }
    
    /// Build ilst (item list) box with metadata atoms
    private func buildIlstBox(with track: Track) throws -> Data {
        var ilstData = Data()
        
        // ilst box header (will update size later)
        ilstData.append(writeBoxSize(0)) // Placeholder for size
        ilstData.append("ilst".data(using: .ascii) ?? Data())
        
        // Add metadata atoms
        if !track.title.isEmpty {
            ilstData.append(try buildTextAtom(atomType: "©nam", text: track.title))
        }
        if !track.artist.isEmpty {
            ilstData.append(try buildTextAtom(atomType: "©ART", text: track.artist))
        }
        if !track.album.isEmpty {
            ilstData.append(try buildTextAtom(atomType: "©alb", text: track.album))
        }
        if let year = track.year {
            ilstData.append(try buildTextAtom(atomType: "©day", text: String(year)))
        }
        if let genre = track.genre, !genre.isEmpty {
            ilstData.append(try buildTextAtom(atomType: "©gen", text: genre))
        }
        if let trackNumber = track.trackNumber {
            ilstData.append(try buildTrackNumberAtom(trackNumber: trackNumber))
        }
        if let discNumber = track.discNumber {
            ilstData.append(try buildDiscNumberAtom(discNumber: discNumber))
        }
        
        // Update ilst box size
        let ilstSize = UInt32(ilstData.count)
        ilstData.replaceSubrange(0..<4, with: writeBoxSize(ilstSize))
        
        return ilstData
    }
    
    /// Build a text atom (e.g., ©nam, ©ART, ©alb, ©gen, ©day)
    private func buildTextAtom(atomType: String, text: String) throws -> Data {
        var atomData = Data()
        
        // Atom header (will update size later)
        atomData.append(writeBoxSize(0)) // Placeholder for size
        // Atom type (can contain non-ASCII like © = 0xA9)
        guard let atomTypeData = atomType.data(using: .isoLatin1) else {
            throw TagWriterError.encodingError("Failed to encode atom type: \(atomType)")
        }
        atomData.append(atomTypeData)
        
        // Build data atom
        let dataAtom = try buildDataAtom(text: text)
        atomData.append(dataAtom)
        
        // Update atom size
        let atomSize = UInt32(atomData.count)
        atomData.replaceSubrange(0..<4, with: writeBoxSize(atomSize))
        
        return atomData
    }
    
    /// Build a data atom (contains the actual text data)
    private func buildDataAtom(text: String) throws -> Data {
        var dataAtom = Data()
        
        // Data atom header (will update size later)
        dataAtom.append(writeBoxSize(0)) // Placeholder for size
        dataAtom.append("data".data(using: .ascii) ?? Data())
        
        // Flags/version (4 bytes: 0x00000001 = text data)
        dataAtom.append(Data([0x00, 0x00, 0x00, 0x01]))
        
        // Locale (4 bytes: 0x00000000 = no language)
        dataAtom.append(Data(repeating: 0x00, count: 4))
        
        // Text data (UTF-8)
        guard let textData = text.data(using: .utf8) else {
            throw TagWriterError.encodingError("Failed to encode text: \(text)")
        }
        dataAtom.append(textData)
        
        // Update data atom size
        let dataSize = UInt32(dataAtom.count)
        dataAtom.replaceSubrange(0..<4, with: writeBoxSize(dataSize))
        
        return dataAtom
    }
    
    /// Build a track number atom (trkn)
    private func buildTrackNumberAtom(trackNumber: Int) throws -> Data {
        var atomData = Data()
        
        // Atom header (will update size later)
        atomData.append(writeBoxSize(0)) // Placeholder for size
        atomData.append("trkn".data(using: .ascii) ?? Data())
        
        // Build data atom for track number
        var dataAtom = Data()
        dataAtom.append(writeBoxSize(0)) // Placeholder
        dataAtom.append("data".data(using: .ascii) ?? Data())
        dataAtom.append(Data([0x00, 0x00, 0x00, 0x00])) // Flags (integer data)
        dataAtom.append(Data(repeating: 0x00, count: 4)) // Locale
        // Track number: 2 bytes track, 2 bytes total tracks (0 = unknown)
        var trackNum = UInt16(trackNumber).bigEndian
        dataAtom.append(Data(bytes: &trackNum, count: 2))
        dataAtom.append(Data([0x00, 0x00])) // Total tracks (unknown)
        
        // Update data atom size
        let dataSize = UInt32(dataAtom.count)
        dataAtom.replaceSubrange(0..<4, with: writeBoxSize(dataSize))
        
        atomData.append(dataAtom)
        
        // Update atom size
        let atomSize = UInt32(atomData.count)
        atomData.replaceSubrange(0..<4, with: writeBoxSize(atomSize))
        
        return atomData
    }
    
    /// Build a disc number atom (disk)
    private func buildDiscNumberAtom(discNumber: Int) throws -> Data {
        var atomData = Data()
        
        // Atom header (will update size later)
        atomData.append(writeBoxSize(0)) // Placeholder for size
        atomData.append("disk".data(using: .ascii) ?? Data())
        
        // Build data atom for disc number
        var dataAtom = Data()
        dataAtom.append(writeBoxSize(0)) // Placeholder
        dataAtom.append("data".data(using: .ascii) ?? Data())
        dataAtom.append(Data([0x00, 0x00, 0x00, 0x00])) // Flags (integer data)
        dataAtom.append(Data(repeating: 0x00, count: 4)) // Locale
        // Disc number: 2 bytes disc, 2 bytes total discs (0 = unknown)
        var discNum = UInt16(discNumber).bigEndian
        dataAtom.append(Data(bytes: &discNum, count: 2))
        dataAtom.append(Data([0x00, 0x00])) // Total discs (unknown)
        
        // Update data atom size
        let dataSize = UInt32(dataAtom.count)
        dataAtom.replaceSubrange(0..<4, with: writeBoxSize(dataSize))
        
        atomData.append(dataAtom)
        
        // Update atom size
        let atomSize = UInt32(atomData.count)
        atomData.replaceSubrange(0..<4, with: writeBoxSize(atomSize))
        
        return atomData
    }
}
