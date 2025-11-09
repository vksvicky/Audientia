//
//  TagParserCoordinator.swift
//  MetadataEngine
//
//  Coordinator for routing audio files to appropriate tag parsers
//  Provides a unified interface for parsing metadata from various audio formats
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Protocol for tag parser coordination
public protocol TagParserCoordinating: Sendable {
    /// Check if any parser can handle the given file
    /// - Parameter fileURL: The file URL to check
    /// - Returns: True if any parser can handle the file
    func canParse(fileURL: URL) -> Bool
    
    /// Parse tags from an audio file using the appropriate parser
    /// - Parameter fileURL: The URL of the audio file
    /// - Returns: Parsed metadata as a Track object, or nil if parsing fails
    /// - Throws: Error if parsing fails or format is unsupported
    func parse(fileURL: URL) async throws -> Track?
}

/// Coordinator that routes files to appropriate tag parsers
public final class TagParserCoordinator: TagParserCoordinating, @unchecked Sendable {
    private let parsers: [TagParserProtocol]
    
    /// Initialize with a list of parsers
    /// - Parameter parsers: Array of tag parsers to use (in priority order)
    public init(parsers: [TagParserProtocol]) {
        self.parsers = parsers
    }
    
    /// Initialize with default parsers (ID3v2, Vorbis Comments, MP4)
    public convenience init() {
        self.init(parsers: [
            ID3v2Parser(),
            VorbisCommentsParser(),
            MP4Parser()
        ])
    }
    
    /// Check if any parser can handle the given file
    /// - Parameter fileURL: The file URL to check
    /// - Returns: True if any parser can handle the file
    public func canParse(fileURL: URL) -> Bool {
        let fileExtension = fileURL.pathExtension.lowercased()
        
        guard !fileExtension.isEmpty else {
            return false
        }
        
        return parsers.contains { parser in
            parser.supportedExtensions.contains(fileExtension)
        }
    }
    
    /// Parse tags from an audio file using the appropriate parser
    /// - Parameter fileURL: The URL of the audio file
    /// - Returns: Parsed metadata as a Track object, or nil if parsing fails
    /// - Throws: Error if parsing fails or format is unsupported
    public func parse(fileURL: URL) async throws -> Track? {
        let fileExtension = fileURL.pathExtension.lowercased()
        
        guard !fileExtension.isEmpty else {
            throw TagParserError.unsupportedFormat("")
        }
        
        // Find the first parser that can handle this file type
        guard let parser = parsers.first(where: { $0.supportedExtensions.contains(fileExtension) }) else {
            throw TagParserError.unsupportedFormat(fileExtension)
        }
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw TagParserError.fileNotFound(fileURL)
        }
        
        // Delegate to the appropriate parser
        return try await parser.parse(fileURL: fileURL)
    }
}
