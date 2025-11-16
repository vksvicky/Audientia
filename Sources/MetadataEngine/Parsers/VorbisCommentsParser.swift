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
        // Try to parse proper Vorbis Comments structure first
        // This handles files written by our writer (OGG header + Vorbis Comments)
        if let parsed = try? parseVorbisCommentsStructure(data: data),
           hasAnyMetadata(parsed) {
            return parsed
        }
        
        // Fallback to simplified pattern search for existing files
        return parseVorbisCommentsByPattern(data: data)
    }
    
    /// Check if parsed comments contain any metadata
    private func hasAnyMetadata(_ comments: ParsedComments) -> Bool {
        comments.title != nil || comments.artist != nil || comments.album != nil ||
        comments.year != nil || comments.trackNumber != nil ||
        comments.discNumber != nil || comments.genre != nil
    }
    
    /// Parse Vorbis Comments using pattern search (fallback method)
    private func parseVorbisCommentsByPattern(data: Data) -> ParsedComments {
        var comments = ParsedComments()
        
        // Limit search to first 10KB to avoid false matches in audio data
        let searchLimit = min(10_000, data.count)
        let searchData = Data(data.prefix(searchLimit))
        
        // Extract comments using pattern matching
        extractCommentsFromPattern(data: searchData, comments: &comments)
        
        return comments
    }
    
    /// Extract comments from data using pattern search
    private func extractCommentsFromPattern(data: Data, comments: inout ParsedComments) {
        if let titleRange = findComment(data: data, field: "TITLE") {
            comments.title = extractCommentValue(data: data, range: titleRange)
        }
        
        if let artistRange = findComment(data: data, field: "ARTIST") {
            comments.artist = extractCommentValue(data: data, range: artistRange)
        }
        
        if let albumRange = findComment(data: data, field: "ALBUM") {
            comments.album = extractCommentValue(data: data, range: albumRange)
        }
        
        if let dateRange = findComment(data: data, field: "DATE"),
           let dateString = extractCommentValue(data: data, range: dateRange) {
            comments.year = extractYear(from: dateString)
        }
        
        if let trackRange = findComment(data: data, field: "TRACKNUMBER"),
           let trackString = extractCommentValue(data: data, range: trackRange) {
            comments.trackNumber = Int(trackString)
        }
        
        if let discRange = findComment(data: data, field: "DISCNUMBER"),
           let discString = extractCommentValue(data: data, range: discRange) {
            comments.discNumber = Int(discString)
        }
        
        if let genreRange = findComment(data: data, field: "GENRE") {
            comments.genre = extractCommentValue(data: data, range: genreRange)
        }
    }
    
    /// Parse Vorbis Comments structure (vendor string + comment vector)
    private func parseVorbisCommentsStructure(data: Data) throws -> ParsedComments {
        var comments = ParsedComments()
        let offset = try findVorbisCommentsStart(data: data)
        var currentOffset = offset
        
        // Read and skip vendor string
        currentOffset = try skipVendorString(data: data, offset: currentOffset)
        
        // Read comment vector length
        let commentVectorLength = try readCommentVectorLength(data: data, offset: &currentOffset)
        
        // Parse each comment
        for _ in 0..<commentVectorLength {
            guard let comment = try? readNextComment(data: data, offset: &currentOffset) else {
                break
            }
            applyCommentToMetadata(comment: comment, metadata: &comments)
        }
        
        return comments
    }
    
    /// Find the start offset of Vorbis Comments in the data
    private func findVorbisCommentsStart(data: Data) throws -> Int {
        // Skip OGG header if present (starts with "OggS")
        if data.count >= 27, String(data: data.prefix(4), encoding: .ascii) == "OggS" {
            return 27
        }
        
        // Search for vendor string "Audientia" to find Vorbis Comments start
        let vendorPattern = Data("Audientia".utf8)
        if let vendorRange = data.range(of: vendorPattern),
           vendorRange.lowerBound >= 4 {
            return vendorRange.lowerBound - 4
        }
        
        // Try to find vendor string length pattern (reasonable length: 1-100 bytes)
        return try findVendorStringByLength(data: data)
    }
    
    /// Find vendor string by searching for length patterns
    private func findVendorStringByLength(data: Data) throws -> Int {
        let searchLimit = min(1000, data.count - 4)
        for searchOffset in 0..<searchLimit {
            let lengthBytes = data.subdata(in: searchOffset..<(searchOffset + 4))
            let length = readUInt32LittleEndian(lengthBytes)
            if length > 0 && length < 1000 && searchOffset + 4 + Int(length) <= data.count {
                let vendorString = data.subdata(in: (searchOffset + 4)..<(searchOffset + 4 + Int(length)))
                if let vendor = String(data: vendorString, encoding: .utf8), !vendor.isEmpty {
                    return searchOffset
                }
            }
        }
        throw TagParserError.corruptedTag("Vorbis Comments")
    }
    
    /// Skip vendor string and return new offset
    private func skipVendorString(data: Data, offset: Int) throws -> Int {
        guard offset + 4 <= data.count else {
            throw TagParserError.corruptedTag("Vorbis Comments")
        }
        let vendorLengthBytes = data.subdata(in: offset..<(offset + 4))
        let vendorLength = readUInt32LittleEndian(vendorLengthBytes)
        let newOffset = offset + 4 + Int(vendorLength)
        guard newOffset <= data.count else {
            throw TagParserError.corruptedTag("Vorbis Comments")
        }
        return newOffset
    }
    
    /// Read comment vector length and update offset
    private func readCommentVectorLength(data: Data, offset: inout Int) throws -> UInt32 {
        guard offset + 4 <= data.count else {
            throw TagParserError.corruptedTag("Vorbis Comments")
        }
        let lengthBytes = data.subdata(in: offset..<(offset + 4))
        let length = readUInt32LittleEndian(lengthBytes)
        offset += 4
        return length
    }
    
    /// Read next comment and update offset
    private func readNextComment(data: Data, offset: inout Int) throws -> String? {
        guard offset + 4 <= data.count else {
            return nil
        }
        
        let commentLengthBytes = data.subdata(in: offset..<(offset + 4))
        let commentLength = readUInt32LittleEndian(commentLengthBytes)
        offset += 4
        
        guard offset + Int(commentLength) <= data.count else {
            return nil
        }
        
        let commentData = data.subdata(in: offset..<(offset + Int(commentLength)))
        offset += Int(commentLength)
        
        return String(data: commentData, encoding: .utf8)
    }
    
    /// Apply a comment string to metadata structure
    private func applyCommentToMetadata(comment: String?, metadata: inout ParsedComments) {
        guard let comment = comment,
              let equalsIndex = comment.firstIndex(of: "=") else {
            return
        }
        
        let fieldName = String(comment[..<equalsIndex]).uppercased()
        let value = String(comment[comment.index(after: equalsIndex)...])
        
        switch fieldName {
        case "TITLE":
            metadata.title = value
        case "ARTIST":
            metadata.artist = value
        case "ALBUM":
            metadata.album = value
        case "DATE":
            metadata.year = extractYear(from: value)
        case "TRACKNUMBER":
            metadata.trackNumber = Int(value)
        case "DISCNUMBER":
            metadata.discNumber = Int(value)
        case "GENRE":
            metadata.genre = value
        default:
            break
        }
    }
    
    /// Read UInt32 from little-endian bytes
    private func readUInt32LittleEndian(_ bytes: Data) -> UInt32 {
        guard bytes.count >= 4 else { return 0 }
        var value: UInt32 = 0
        value |= UInt32(bytes[0])
        value |= UInt32(bytes[1]) << 8
        value |= UInt32(bytes[2]) << 16
        value |= UInt32(bytes[3]) << 24
        return value
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
        guard yearString.count == 4,
              let year = Int(yearString),
              year > 0 else {
            return nil
        }
        return year
    }
}
