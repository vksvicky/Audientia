//
//  TagWriterProtocol.swift
//  MetadataEngine
//
//  Protocol for writing audio file tags
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Protocol for writing audio file tags
public protocol TagWriterProtocol: Sendable {
    /// Supported file extensions for this writer
    var supportedExtensions: Set<String> { get }
    
    /// Check if this writer can handle the given file
    /// - Parameter fileURL: The file URL to check
    /// - Returns: True if this writer can handle the file
    func canWrite(fileURL: URL) -> Bool
    
    /// Write tags to an audio file
    /// - Parameters:
    ///   - fileURL: The URL of the audio file
    ///   - track: The Track object containing metadata to write
    /// - Throws: Error if writing fails
    func write(track: Track, to fileURL: URL) async throws
    
    /// Update existing tags in an audio file
    /// - Parameters:
    ///   - fileURL: The URL of the audio file
    ///   - track: The Track object containing updated metadata
    /// - Throws: Error if updating fails
    func update(track: Track, in fileURL: URL) async throws
}

/// Errors that can occur during tag writing
public enum TagWriterError: Error, LocalizedError {
    case unsupportedFormat(String)
    case fileNotFound(URL)
    case readError(URL, Error)
    case writeError(URL, Error)
    case invalidTagData(String)
    case readOnlyFile(URL)
    case diskFull(URL)
    case encodingError(String)
    case validationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case let .unsupportedFormat(format):
            return "Unsupported format: \(format)"
        case let .fileNotFound(url):
            return "File not found: \(url.path)"
        case let .readError(url, error):
            return "Error reading file \(url.path): \(error.localizedDescription)"
        case let .writeError(url, error):
            return "Error writing file \(url.path): \(error.localizedDescription)"
        case let .invalidTagData(data):
            return "Invalid tag data: \(data)"
        case let .readOnlyFile(url):
            return "File is read-only: \(url.path)"
        case let .diskFull(url):
            return "Disk full: \(url.path)"
        case let .encodingError(encoding):
            return "Encoding error: \(encoding)"
        case let .validationFailed(reason):
            return "Tag validation failed: \(reason)"
        }
    }
}
