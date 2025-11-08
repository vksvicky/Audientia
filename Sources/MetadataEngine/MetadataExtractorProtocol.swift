//
//  MetadataExtractorProtocol.swift
//  MetadataEngine
//
//  Protocol for extracting metadata from audio files
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Protocol for extracting metadata from audio files
public protocol MetadataExtractorProtocol: Sendable {
    /// Extract metadata from an audio file
    /// - Parameter fileURL: The URL of the audio file
    /// - Returns: Track object with extracted metadata, or nil if extraction fails
    /// - Throws: Error if metadata extraction fails
    func extractMetadata(from fileURL: URL) async throws -> Track?
}
