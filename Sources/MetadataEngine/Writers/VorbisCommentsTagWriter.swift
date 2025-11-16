//
//  VorbisCommentsTagWriter.swift
//  MetadataEngine
//
//  Writer for Vorbis Comments tags (FLAC, OGG, Opus files)
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Writer for Vorbis Comments tags (FLAC, OGG, Opus files)
public final class VorbisCommentsTagWriter: TagWriterProtocol, @unchecked Sendable {
    
    /// Supported file extensions for Vorbis Comments (FLAC, OGG, Opus)
    public let supportedExtensions: Set<String> = ["flac", "ogg", "opus"]
    
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
        
        // Find audio data start (after OGG header and metadata blocks)
        let audioDataStart = findAudioDataStart(data: fileData)
        let audioData = fileData.suffix(from: audioDataStart)
        
        // Build Vorbis Comments
        let commentsData = try buildVorbisComments(from: track)
        
        // Write new file: OGG header + Vorbis Comments + audio data
        var newFileData = Data()
        
        // Preserve OGG header if present, otherwise create one
        if fileData.count >= 27,
           String(data: fileData.prefix(4), encoding: .ascii) == "OggS" {
            // Use existing OGG header
            newFileData.append(fileData.prefix(27))
        } else {
            // Create new OGG header
            guard let oggHeader = "OggS".data(using: .ascii) else {
                throw TagWriterError.encodingError("Failed to encode OGG header")
            }
            newFileData.append(oggHeader)
            newFileData.append(Data(repeating: 0x00, count: 23)) // Rest of OGG header
        }
        
        // Append Vorbis Comments
        newFileData.append(commentsData)
        
        // Append audio data
        newFileData.append(audioData)
        
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
        // For Vorbis Comments, update is the same as write (we replace the entire comment block)
        try await write(track: track, to: fileURL)
    }
    
    // MARK: - Private Methods
    
    /// Find the start of audio data (after OGG header and metadata blocks)
    private func findAudioDataStart(data: Data) -> Int {
        // Check for OGG header
        guard data.count >= 27,
              String(data: data.prefix(4), encoding: .ascii) == "OggS" else {
            // No OGG header, audio starts at beginning
            return 0
        }
        
        // For now, assume audio data starts after OGG header
        // A more sophisticated implementation would parse OGG pages
        return 27
    }
    
    /// Build Vorbis Comments from Track metadata
    private func buildVorbisComments(from track: Track) throws -> Data {
        var commentsData = Data()
        
        // Vendor string (simplified - use app name)
        let vendorString = "Audientia"
        guard let vendorData = vendorString.data(using: .utf8) else {
            throw TagWriterError.encodingError("Failed to encode vendor string")
        }
        
        // Vendor string length (4 bytes, little-endian)
        var vendorLength = UInt32(vendorData.count).littleEndian
        commentsData.append(Data(bytes: &vendorLength, count: 4))
        commentsData.append(vendorData)
        
        // Build comment list
        var comments: [String] = []
        
        if !track.title.isEmpty {
            comments.append("TITLE=\(track.title)")
        }
        if !track.artist.isEmpty {
            comments.append("ARTIST=\(track.artist)")
        }
        if !track.album.isEmpty {
            comments.append("ALBUM=\(track.album)")
        }
        if let year = track.year {
            comments.append("DATE=\(year)")
        }
        if let trackNumber = track.trackNumber {
            comments.append("TRACKNUMBER=\(trackNumber)")
        }
        if let discNumber = track.discNumber {
            comments.append("DISCNUMBER=\(discNumber)")
        }
        if let genre = track.genre, !genre.isEmpty {
            comments.append("GENRE=\(genre)")
        }
        
        // Comment vector length (4 bytes, little-endian)
        var commentVectorLength = UInt32(comments.count).littleEndian
        commentsData.append(Data(bytes: &commentVectorLength, count: 4))
        
        // Append each comment
        for comment in comments {
            guard let commentData = comment.data(using: .utf8) else {
                throw TagWriterError.encodingError("Failed to encode comment: \(comment)")
            }
            
            // Comment length (4 bytes, little-endian)
            var commentLength = UInt32(commentData.count).littleEndian
            commentsData.append(Data(bytes: &commentLength, count: 4))
            commentsData.append(commentData)
        }
        
        return commentsData
    }
}
