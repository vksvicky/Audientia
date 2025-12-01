//
//  TagWriterCoordinator.swift
//  MetadataEngine
//
//  Coordinator for routing audio files to appropriate tag writers
//  Provides a unified interface for writing metadata to various audio formats
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Protocol for tag writer coordination
public protocol TagWriterCoordinating: Sendable {
    /// Check if any writer can handle the given file
    /// - Parameter fileURL: The file URL to check
    /// - Returns: True if any writer can handle the file
    func canWrite(fileURL: URL) -> Bool
    
    /// Write tags to an audio file using the appropriate writer
    /// - Parameters:
    ///   - track: The Track object containing metadata to write
    ///   - fileURL: The URL of the audio file
    /// - Throws: Error if writing fails or format is unsupported
    func write(track: Track, to fileURL: URL) async throws
    
    /// Update existing tags in an audio file using the appropriate writer
    /// - Parameters:
    ///   - track: The Track object containing updated metadata
    ///   - fileURL: The URL of the audio file
    /// - Throws: Error if updating fails or format is unsupported
    func update(track: Track, in fileURL: URL) async throws
}

/// Coordinator that routes files to appropriate tag writers
public final class TagWriterCoordinator: TagWriterCoordinating, @unchecked Sendable {
    private let writers: [TagWriterProtocol]
    
    /// Initialise with a list of writers
    /// - Parameter writers: Array of tag writers to use (in priority order)
    public init(writers: [TagWriterProtocol]) {
        self.writers = writers
    }
    
    /// Initialise with default writers (ID3v2, Vorbis Comments, MP4)
    public convenience init() {
        self.init(writers: [
            ID3v2TagWriter(),
            VorbisCommentsTagWriter(),
            MP4TagWriter()
        ])
    }
    
    /// Check if any writer can handle the given file
    /// - Parameter fileURL: The file URL to check
    /// - Returns: True if any writer can handle the file
    public func canWrite(fileURL: URL) -> Bool {
        let fileExtension = fileURL.pathExtension.lowercased()
        
        guard !fileExtension.isEmpty else {
            return false
        }
        
        return writers.contains { writer in
            writer.supportedExtensions.contains(fileExtension)
        }
    }
    
    /// Write tags to an audio file using the appropriate writer
    /// - Parameters:
    ///   - track: The Track object containing metadata to write
    ///   - fileURL: The URL of the audio file
    /// - Throws: Error if writing fails or format is unsupported
    public func write(track: Track, to fileURL: URL) async throws {
        let fileExtension = fileURL.pathExtension.lowercased()
        
        guard !fileExtension.isEmpty else {
            throw TagWriterError.unsupportedFormat("")
        }
        
        // Find the first writer that can handle this file type
        guard let writer = writers.first(where: { $0.supportedExtensions.contains(fileExtension) }) else {
            throw TagWriterError.unsupportedFormat(fileExtension)
        }
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw TagWriterError.fileNotFound(fileURL)
        }
        
        // Delegate to the appropriate writer
        try await writer.write(track: track, to: fileURL)
    }
    
    /// Update existing tags in an audio file using the appropriate writer
    /// - Parameters:
    ///   - track: The Track object containing updated metadata
    ///   - fileURL: The URL of the audio file
    /// - Throws: Error if updating fails or format is unsupported
    public func update(track: Track, in fileURL: URL) async throws {
        let fileExtension = fileURL.pathExtension.lowercased()
        
        guard !fileExtension.isEmpty else {
            throw TagWriterError.unsupportedFormat("")
        }
        
        // Find the first writer that can handle this file type
        guard let writer = writers.first(where: { $0.supportedExtensions.contains(fileExtension) }) else {
            throw TagWriterError.unsupportedFormat(fileExtension)
        }
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw TagWriterError.fileNotFound(fileURL)
        }
        
        // Delegate to the appropriate writer
        try await writer.update(track: track, in: fileURL)
    }
}
