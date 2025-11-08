import Foundation
@preconcurrency import Shared

/// Parser for Vorbis Comments tags (OGG, FLAC files)
public final class VorbisCommentsParser: TagParserProtocol, @unchecked Sendable {
    
    /// Supported file extensions for Vorbis Comments (OGG, FLAC, Opus)
    public let supportedExtensions: Set<String> = ["ogg", "flac", "opus"]
    
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
        
        // Check for OGG header (starts with "OggS")
        guard fileData.count >= 27,
              String(data: fileData.prefix(4), encoding: .ascii) == "OggS" else {
            // No OGG header found - return nil (file may not be OGG/FLAC/Opus)
            return nil
        }
        
        // Parse Vorbis Comments
        let comments = try parseVorbisComments(data: fileData)
        
        // Extract file metadata
        let fileSize = Int64(fileData.count)
        let fileName = fileURL.deletingPathExtension().lastPathComponent
        
        // Create Track from parsed comments
        return Track(
            title: comments.title ?? fileName,
            artist: comments.artist ?? "Unknown Artist",
            album: comments.album ?? "Unknown Album",
            duration: 0.0, // Duration would need to be extracted from audio stream
            filePath: fileURL.path,
            fileSize: fileSize,
            bitrate: 0, // Bitrate would need to be extracted from audio stream
            sampleRate: 0, // Sample rate would need to be extracted from audio stream
            year: comments.year,
            trackNumber: comments.trackNumber,
            discNumber: comments.discNumber,
            genre: comments.genre
        )
    }
    
    // MARK: - Vorbis Comments Parsing
    
    private struct ParsedComments {
        var title: String?
        var artist: String?
        var album: String?
        var year: Int?
        var trackNumber: Int?
        var discNumber: Int?
        var genre: String?
    }
    
    private func parseVorbisComments(data: Data) throws -> ParsedComments {
        var comments = ParsedComments()
        
        // Vorbis Comments structure:
        // - OGG page header (27 bytes)
        // - Vorbis identification header
        // - Vorbis comments header (starts with packet type 0x03)
        // - Comment vector length (4 bytes, little-endian)
        // - Comments (each: length (4 bytes) + UTF-8 string)
        
        // Find Vorbis comments packet (packet type 0x03)
        // This is a simplified implementation - real parser would need to:
        // 1. Parse OGG pages
        // 2. Find the comments packet
        // 3. Parse the comment vector
        
        // For now, search for common Vorbis comment patterns
        // Real implementation would properly parse the OGG structure
        
        // Look for comment patterns like "TITLE=...", "ARTIST=...", etc.
        if let titleRange = findComment(data: data, field: "TITLE") {
            comments.title = extractCommentValue(data: data, range: titleRange)
        }
        
        if let artistRange = findComment(data: data, field: "ARTIST") {
            comments.artist = extractCommentValue(data: data, range: artistRange)
        }
        
        if let albumRange = findComment(data: data, field: "ALBUM") {
            comments.album = extractCommentValue(data: data, range: albumRange)
        }
        
        if let dateRange = findComment(data: data, field: "DATE") {
            if let dateString = extractCommentValue(data: data, range: dateRange) {
                comments.year = extractYear(from: dateString)
            }
        }
        
        if let trackRange = findComment(data: data, field: "TRACKNUMBER") {
            if let trackString = extractCommentValue(data: data, range: trackRange) {
                comments.trackNumber = Int(trackString)
            }
        }
        
        if let discRange = findComment(data: data, field: "DISCNUMBER") {
            if let discString = extractCommentValue(data: data, range: discRange) {
                comments.discNumber = Int(discString)
            }
        }
        
        if let genreRange = findComment(data: data, field: "GENRE") {
            comments.genre = extractCommentValue(data: data, range: genreRange)
        }
        
        return comments
    }
    
    // MARK: - Comment Extraction Helpers
    
    /// Find a comment field in the data
    /// - Parameters:
    ///   - data: The file data
    ///   - field: The field name (e.g., "TITLE", "ARTIST")
    /// - Returns: Range of the comment value, or nil if not found
    private func findComment(data: Data, field: String) -> Range<Int>? {
        // Search for field pattern: "FIELDNAME="
        let searchPattern = "\(field.uppercased())="
        guard let patternData = searchPattern.data(using: .utf8) else {
            return nil
        }
        
        // Search for the pattern
        guard let patternRange = data.range(of: patternData) else {
            return nil
        }
        
        let valueStart = patternRange.upperBound
        // Find the end of the value (null terminator or end of data)
        var valueEnd = valueStart
        while valueEnd < data.count && data[valueEnd] != 0 {
            valueEnd += 1
        }
        
        guard valueEnd > valueStart else {
            return nil
        }
        
        return valueStart..<valueEnd
    }
    
    /// Extract comment value from data range
    /// - Parameters:
    ///   - data: The file data
    ///   - range: Range of the comment value
    /// - Returns: Extracted string value, or nil if extraction fails
    private func extractCommentValue(data: Data, range: Range<Int>) -> String? {
        guard range.upperBound <= data.count else {
            return nil
        }
        
        let valueData = data.subdata(in: range)
        return String(data: valueData, encoding: .utf8)
    }
    
    /// Extract year from date string
    /// - Parameter dateString: Date string (may be "2024" or "2024-01-01")
    /// - Returns: Year as Int, or nil if extraction fails
    private func extractYear(from dateString: String) -> Int? {
        // Extract 4-digit year from beginning of string
        let yearString = String(dateString.prefix(4))
        return Int(yearString)
    }
}
