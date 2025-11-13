//
//  LibraryScanner.swift
//  DataLayer
//
//  Library scanner implementation using FileManager
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import MetadataEngine
@preconcurrency import Shared // For AudioFormats

/// Library scanner for finding audio files in directories
public final class LibraryScanner: LibraryScannerProtocol, @unchecked Sendable {
    
    /// Supported audio file extensions (from shared constants)
    private let supportedExtensions: Set<String> = AudioFormats.allSupportedExtensions
    
    private let fileManager: FileManager
    private let metadataExtractor: MetadataExtractorProtocol?
    
    /// Initialize with a FileManager instance and optional metadata extractor
    /// - Parameters:
    ///   - fileManager: FileManager to use (defaults to .default)
    ///   - metadataExtractor: Optional metadata extractor for extracting track metadata
    public init(fileManager: FileManager = .default, metadataExtractor: MetadataExtractorProtocol? = nil) {
        self.fileManager = fileManager
        self.metadataExtractor = metadataExtractor
    }
    
    /// Scan a directory for audio files
    /// - Parameter directory: The directory to scan
    /// - Returns: Array of Track objects representing found audio files
    /// - Throws: Error if scanning fails
    public func scan(directory: URL) async throws -> [Track] {
        // Collect file URLs in a synchronous context to avoid Swift 6 concurrency issues
        let fileURLs = try await Task.detached { [fileManager, supportedExtensions] in
            var urls: [URL] = []
            
            // Check if directory exists and is a directory
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: directory.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                throw LibraryScannerError.directoryNotFound
            }
            
            // Get all files in directory recursively
            guard let enumerator = fileManager.enumerator(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                throw LibraryScannerError.directoryNotFound
            }
            
            // Use nextObject() instead of for...in to avoid Swift 6 async iterator issues
            while let element = enumerator.nextObject() as? URL {
                // Check if it's a regular file
                let resourceValues = try? element.resourceValues(forKeys: [.isRegularFileKey])
                guard resourceValues?.isRegularFile == true else {
                    continue
                }
                
                // Check if it's an audio file
                let fileExtension = element.pathExtension.lowercased()
                guard supportedExtensions.contains(fileExtension) else {
                    continue
                }
                
                urls.append(element)
            }
            
            return urls
        }.value
        
        // Process files and extract metadata in async context
        var tracks: [Track] = []
        for fileURL in fileURLs {
            // Extract metadata if extractor is available, otherwise create basic Track
            let track: Track
            if let extractor = metadataExtractor,
               let extractedTrack = try? await extractor.extractMetadata(from: fileURL) {
                track = extractedTrack
            } else {
                track = createTrack(from: fileURL)
            }
            tracks.append(track)
        }
        
        return tracks
    }
    
    /// Create a Track from a file URL
    /// - Parameter fileURL: The file URL
    /// - Returns: A Track object with basic file information
    private func createTrack(from fileURL: URL) -> Track {
        let fileName = fileURL.deletingPathExtension().lastPathComponent
        let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        
        return Track(
            id: UUID(),
            title: fileName,
            artist: "Unknown Artist",
            album: "Unknown Album",
            duration: 0.0,
            filePath: fileURL.path,
            fileSize: Int64(fileSize),
            bitrate: 0,
            sampleRate: 0,
            year: nil,
            trackNumber: nil,
            discNumber: nil
        )
    }
}

/// Errors that can occur during library scanning
public enum LibraryScannerError: Error {
    case directoryNotFound
    case permissionDenied
    case scanInterrupted
}
