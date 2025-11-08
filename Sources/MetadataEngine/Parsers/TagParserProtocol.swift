import Foundation
@preconcurrency import Shared

/// Protocol for parsing audio file tags
public protocol TagParserProtocol: Sendable {
    /// Supported file extensions for this parser
    var supportedExtensions: Set<String> { get }
    
    /// Check if this parser can handle the given file
    /// - Parameter fileURL: The file URL to check
    /// - Returns: True if this parser can handle the file
    func canParse(fileURL: URL) -> Bool
    
    /// Parse tags from an audio file
    /// - Parameter fileURL: The URL of the audio file
    /// - Returns: Parsed metadata as a Track object, or nil if parsing fails
    /// - Throws: Error if parsing fails
    func parse(fileURL: URL) async throws -> Track?
}

/// Errors that can occur during tag parsing
public enum TagParserError: Error, LocalizedError {
    case unsupportedFormat(String)
    case fileNotFound(URL)
    case readError(URL, Error)
    case invalidTagFormat(String)
    case corruptedTag(String)
    case encodingError(String)
    
    public var errorDescription: String? {
        switch self {
        case let .unsupportedFormat(format):
            return "Unsupported format: \(format)"
        case let .fileNotFound(url):
            return "File not found: \(url.path)"
        case let .readError(url, error):
            return "Error reading file \(url.path): \(error.localizedDescription)"
        case let .invalidTagFormat(format):
            return "Invalid tag format: \(format)"
        case let .corruptedTag(format):
            return "Corrupted tag in format: \(format)"
        case let .encodingError(encoding):
            return "Encoding error: \(encoding)"
        }
    }
}
