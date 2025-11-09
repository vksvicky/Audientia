import Foundation
@preconcurrency import Shared

/// Parser for ID3v2 tags (MP3 files)
public final class ID3v2Parser: TagParserProtocol, @unchecked Sendable {
    
    /// Supported file extensions for ID3v2 (MP3)
    public let supportedExtensions: Set<String> = ["mp3"]
    
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
        
        // Check for ID3v2 tag (starts with "ID3")
        guard fileData.count >= 10,
              String(data: fileData.prefix(3), encoding: .ascii) == "ID3" else {
            // No ID3v2 tag found - return nil (file may have no tags or only ID3v1)
            return nil
        }
        
        // Parse ID3v2 header
        let header = try parseID3v2Header(data: fileData)
        
        // Parse ID3v2 frames
        let frames = try parseID3v2Frames(
            data: fileData,
            headerOffset: 10,
            tagSize: header.tagSize
        )
        
        // Extract file metadata
        let fileSize = Int64(fileData.count)
        let fileName = fileURL.deletingPathExtension().lastPathComponent
        
        // Create Track from parsed frames
        return Track(
            title: frames.title ?? fileName,
            artist: frames.artist ?? "Unknown Artist",
            album: frames.album ?? "Unknown Album",
            duration: 0.0, // Duration would need to be extracted from audio stream
            filePath: fileURL.path,
            fileSize: fileSize,
            bitrate: 0, // Bitrate would need to be extracted from audio stream
            sampleRate: 0, // Sample rate would need to be extracted from audio stream
            year: frames.year,
            trackNumber: frames.trackNumber,
            discNumber: frames.discNumber,
            genre: frames.genre
        )
    }
    
    // MARK: - ID3v2 Header Parsing
    
    private struct ID3v2Header {
        let version: UInt8
        let revision: UInt8
        let flags: UInt8
        let tagSize: Int
    }
    
    private func parseID3v2Header(data: Data) throws -> ID3v2Header {
        guard data.count >= 10 else {
            throw TagParserError.corruptedTag("ID3v2")
        }
        
        // ID3v2 header structure:
        // Bytes 0-2: "ID3"
        // Byte 3: Version (e.g., 0x03 for ID3v2.3)
        // Byte 4: Revision
        // Byte 5: Flags
        // Bytes 6-9: Tag size (synchsafe integer)
        
        let version = data[3]
        let revision = data[4]
        let flags = data[5]
        
        // Parse synchsafe integer for tag size
        let tagSize = parseSynchsafeInteger(
            bytes: [data[6], data[7], data[8], data[9]]
        )
        
        return ID3v2Header(
            version: version,
            revision: revision,
            flags: flags,
            tagSize: tagSize
        )
    }
    
    // MARK: - ID3v2 Frame Parsing
    
    private struct ParsedFrames {
        var title: String?
        var artist: String?
        var album: String?
        var year: Int?
        var trackNumber: Int?
        var discNumber: Int?
        var genre: String?
    }
    
    private func parseID3v2Frames(data: Data, headerOffset: Int, tagSize: Int) throws -> ParsedFrames {
        var frames = ParsedFrames()
        
        let frameDataStart = headerOffset
        let frameDataEnd = min(frameDataStart + tagSize, data.count)
        
        guard frameDataEnd > frameDataStart else {
            return frames
        }
        
        var offset = frameDataStart
        
        // Parse frames until we reach the end or find padding
        while offset < frameDataEnd - 10 {
            // Check for frame header (4 bytes frame ID + 4 bytes size + 2 bytes flags)
            guard offset + 10 <= frameDataEnd else {
                break
            }
            
            // Check if we've hit padding (all zeros)
            if data[offset] == 0 {
                break
            }
            
            // Parse frame ID (4 bytes, ASCII)
            guard let frameID = String(data: data.subdata(in: offset..<(offset + 4)), encoding: .ascii) else {
                offset += 1
                continue
            }
            
            // Parse frame size (4 bytes, synchsafe integer)
            let frameSize = parseSynchsafeInteger(
                bytes: [data[offset + 4], data[offset + 5], data[offset + 6], data[offset + 7]]
            )
            
            // Skip flags (2 bytes)
            offset += 10
            
            // Parse frame content
            guard offset + frameSize <= frameDataEnd else {
                break
            }
            
            let frameContent = data.subdata(in: offset..<(offset + frameSize))
            
            // Extract text from frame based on frame ID
            parseFrame(frameID: frameID, content: frameContent, frames: &frames)
            
            offset += frameSize
        }
        
        return frames
    }
    
    // MARK: - Frame Content Extraction
    
    /// Parse a single frame and update the ParsedFrames structure
    private func parseFrame(frameID: String, content: Data, frames: inout ParsedFrames) {
        switch frameID {
        case "TIT2", "TT2": // Title
            frames.title = extractTextFromFrame(content)
        case "TPE1", "TP1": // Artist
            frames.artist = extractTextFromFrame(content)
        case "TALB", "TAL": // Album
            frames.album = extractTextFromFrame(content)
        case "TDRC", "TYER": // Year
            frames.year = extractYearFromFrame(content)
        case "TRCK", "TRK": // Track number
            frames.trackNumber = extractTrackNumberFromFrame(content)
        case "TPOS": // Disc number
            frames.discNumber = extractDiscNumberFromFrame(content)
        case "TCON", "TCO": // Genre
            frames.genre = extractGenreFromFrame(content)
        default:
            break
        }
    }
    
    private func extractTextFromFrame(_ data: Data) -> String? {
        guard !data.isEmpty else { return nil }
        
        // First byte is encoding (0 = ISO-8859-1, 1 = UTF-16 with BOM, 2 = UTF-16BE, 3 = UTF-8)
        let encodingByte = data[0]
        let textData = data.dropFirst()
        
        guard !textData.isEmpty else { return nil }
        
        let encoding: String.Encoding
        switch encodingByte {
        case 0:
            encoding = .isoLatin1
        case 1:
            encoding = .utf16
        case 2:
            encoding = .utf16BigEndian
        case 3:
            encoding = .utf8
        default:
            encoding = .utf8
        }
        
        // Remove null terminators
        let cleanedData = textData.filter { $0 != 0 }
        
        return String(data: cleanedData, encoding: encoding)
    }
    
    private func extractYearFromFrame(_ data: Data) -> Int? {
        guard let text = extractTextFromFrame(data) else { return nil }
        
        // Extract 4-digit year
        let yearString = String(text.prefix(4))
        guard yearString.count == 4,
              let year = Int(yearString),
              year > 0 else {
            return nil
        }
        return year
    }
    
    private func extractTrackNumberFromFrame(_ data: Data) -> Int? {
        guard let text = extractTextFromFrame(data) else { return nil }
        
        // Track number format: "1" or "1/10"
        let trackString = text.components(separatedBy: "/").first?.trimmingCharacters(in: .whitespaces)
        return trackString.flatMap { Int($0) }
    }
    
    private func extractDiscNumberFromFrame(_ data: Data) -> Int? {
        guard let text = extractTextFromFrame(data) else { return nil }
        
        // Disc number format: "1" or "1/2"
        let discString = text.components(separatedBy: "/").first?.trimmingCharacters(in: .whitespaces)
        return discString.flatMap { Int($0) }
    }
    
    private func extractGenreFromFrame(_ data: Data) -> String? {
        guard let text = extractTextFromFrame(data) else { return nil }
        
        // Genre format: "(17)" or "Rock" or "(17)Rock"
        // Remove ID3v1 genre number if present
        let genreString = text.replacingOccurrences(of: #"^\(\d+\)"#, with: "", options: .regularExpression)
        return genreString.isEmpty ? nil : genreString
    }
    
    // MARK: - Helper Functions
    
    /// Parse synchsafe integer (7 bits per byte, most significant bit always 0)
    private func parseSynchsafeInteger(bytes: [UInt8]) -> Int {
        guard bytes.count == 4 else { return 0 }
        
        var result = 0
        for byte in bytes {
            result = (result << 7) | Int(byte)
        }
        return result
    }
}
