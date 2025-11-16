//
//  ID3v2TagWriter.swift
//  MetadataEngine
//
//  Writer for ID3v2 tags (MP3 files)
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Writer for ID3v2 tags (MP3 files)
public final class ID3v2TagWriter: TagWriterProtocol, @unchecked Sendable {
    
    /// Supported file extensions for ID3v2 (MP3)
    public let supportedExtensions: Set<String> = ["mp3"]
    
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
        
        // Read existing file data
        let fileData: Data
        do {
            fileData = try Data(contentsOf: fileURL)
        } catch {
            throw TagWriterError.readError(fileURL, error)
        }
        
        // Find audio data start (after ID3v2 tag if present)
        let audioDataStart = findAudioDataStart(data: fileData)
        let audioData = fileData.suffix(from: audioDataStart)
        
        // Build ID3v2 tag
        let tagData = try buildID3v2Tag(from: track)
        
        // Write new file: ID3v2 tag + audio data
        let newFileData = tagData + audioData
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
        // For ID3v2, update is the same as write (we replace the entire tag)
        try await write(track: track, to: fileURL)
    }
    
    // MARK: - Private Methods
    
    /// Find the start of audio data (after ID3v2 tag if present)
    private func findAudioDataStart(data: Data) -> Int {
        // Check for ID3v2 tag
        guard data.count >= 10,
              String(data: data.prefix(3), encoding: .ascii) == "ID3" else {
            // No ID3v2 tag, audio starts at beginning
            return 0
        }
        
        // Parse ID3v2 header to get tag size
        let tagSize = parseSynchsafeInteger(
            bytes: [data[6], data[7], data[8], data[9]]
        )
        
        // Audio data starts after ID3v2 header (10 bytes) + tag size
        return 10 + tagSize
    }
    
    /// Build ID3v2 tag from Track metadata
    private func buildID3v2Tag(from track: Track) throws -> Data {
        var tagData = Data()
        
        // ID3v2.3 header (10 bytes)
        // Bytes 0-2: "ID3"
        guard let id3Data = "ID3".data(using: .ascii) else {
            throw TagWriterError.encodingError("Failed to encode ID3 header")
        }
        tagData.append(id3Data)
        // Byte 3: Version (0x03 for ID3v2.3)
        tagData.append(0x03)
        // Byte 4: Revision (0x00)
        tagData.append(0x00)
        // Byte 5: Flags (0x00 = no flags)
        tagData.append(0x00)
        // Bytes 6-9: Tag size (synchsafe integer, will be updated later)
        let sizePlaceholder = tagData.count
        tagData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
        
        // Build frames
        var frames = Data()
        
        // TIT2 - Title
        if !track.title.isEmpty {
            frames.append(try buildTextFrame(frameID: "TIT2", text: track.title))
        }
        
        // TPE1 - Artist
        if !track.artist.isEmpty {
            frames.append(try buildTextFrame(frameID: "TPE1", text: track.artist))
        }
        
        // TALB - Album
        if !track.album.isEmpty {
            frames.append(try buildTextFrame(frameID: "TALB", text: track.album))
        }
        
        // TYER - Year
        if let year = track.year {
            frames.append(try buildTextFrame(frameID: "TYER", text: String(year)))
        }
        
        // TRCK - Track number
        if let trackNumber = track.trackNumber {
            frames.append(try buildTextFrame(frameID: "TRCK", text: String(trackNumber)))
        }
        
        // TPOS - Disc number
        if let discNumber = track.discNumber {
            frames.append(try buildTextFrame(frameID: "TPOS", text: String(discNumber)))
        }
        
        // TCON - Genre
        if let genre = track.genre, !genre.isEmpty {
            frames.append(try buildTextFrame(frameID: "TCON", text: genre))
        }
        
        // Append frames to tag
        tagData.append(frames)
        
        // Update tag size in header (synchsafe integer)
        let tagSize = frames.count
        let synchsafeSize = toSynchsafeInteger(tagSize)
        tagData.replaceSubrange(sizePlaceholder..<sizePlaceholder + 4, with: synchsafeSize)
        
        return tagData
    }
    
    /// Build a text frame (ID3v2.3)
    private func buildTextFrame(frameID: String, text: String) throws -> Data {
        var frameData = Data()
        
        // Frame ID (4 bytes, ASCII)
        guard let frameIDData = frameID.data(using: .ascii), frameIDData.count == 4 else {
            throw TagWriterError.invalidTagData("Invalid frame ID: \(frameID)")
        }
        frameData.append(frameIDData)
        
        // Frame size (4 bytes, synchsafe integer)
        let textData = text.data(using: .utf8) ?? Data()
        let frameSize = 1 + textData.count // 1 byte for encoding + text data
        let synchsafeSize = toSynchsafeInteger(frameSize)
        frameData.append(synchsafeSize)
        
        // Flags (2 bytes, 0x0000 = no flags)
        frameData.append(contentsOf: [0x00, 0x00])
        
        // Encoding (1 byte, 0x03 = UTF-8)
        frameData.append(0x03)
        
        // Text data
        frameData.append(textData)
        
        return frameData
    }
    
    /// Convert integer to synchsafe integer (ID3v2 format)
    private func toSynchsafeInteger(_ value: Int) -> Data {
        // Synchsafe integer: each byte has bit 7 set to 0
        // Value is stored in bits 0-6 of each byte
        var result = Data()
        var remaining = value
        
        for _ in 0..<4 {
            let byte = UInt8(remaining & 0x7F)
            result.insert(byte, at: 0)
            remaining >>= 7
        }
        
        return result
    }
    
    /// Parse synchsafe integer (ID3v2 format)
    private func parseSynchsafeInteger(bytes: [UInt8]) -> Int {
        guard bytes.count == 4 else {
            return 0
        }
        
        var result = 0
        for byte in bytes {
            result = (result << 7) | Int(byte & 0x7F)
        }
        
        return result
    }
}
