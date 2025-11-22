//
//  AcoustIDService.swift
//  MetadataEngine
//
//  Service for AcoustID fingerprinting and metadata lookup
//

import Foundation
@preconcurrency import Shared

/// Service that coordinates fingerprint generation and AcoustID lookup
public final class AcoustIDService: @unchecked Sendable {
    private let fingerprintGenerator: FingerprintGeneratorProtocol
    private let lookupService: AcoustIDLookupProtocol
    private let fingerprintCache: (any FingerprintCacheProtocol)?
    
    /// Initialize with fingerprint generator and lookup service
    /// - Parameters:
    ///   - fingerprintGenerator: Service for generating audio fingerprints
    ///   - lookupService: Service for AcoustID lookup
    ///   - fingerprintCache: Optional fingerprint cache for performance optimization
    public init(
        fingerprintGenerator: FingerprintGeneratorProtocol,
        lookupService: AcoustIDLookupProtocol,
        fingerprintCache: (any FingerprintCacheProtocol)? = nil
    ) {
        self.fingerprintGenerator = fingerprintGenerator
        self.lookupService = lookupService
        self.fingerprintCache = fingerprintCache
    }
    
    /// Identify a track by generating a fingerprint and looking it up
    /// - Parameter fileURL: The URL of the audio file
    /// - Returns: Array of potential matches with metadata, sorted by confidence score (highest first)
    /// - Throws: Error if fingerprinting or lookup fails
    public func identifyTrack(fileURL: URL) async throws -> [AcoustIDMatch] {
        // Get fingerprint (from cache or generate)
        let fingerprint = try await getFingerprint(fileURL: fileURL)
        
        // Get track duration (required for lookup)
        // Note: In a real implementation, this would extract duration from the audio file
        // For now, we'll use a placeholder - this should be extracted from the Track or file metadata
        let duration: TimeInterval = 180.0 // Default duration
        
        // Lookup matches
        var matches = try await lookupService.lookup(fingerprint: fingerprint, duration: duration)
        
        // Sort by score (highest first)
        matches.sort { $0.score > $1.score }
        
        return matches
    }
    
    /// Identify a track using an existing Track object (uses duration from track)
    /// - Parameter track: The track to identify
    /// - Returns: Array of potential matches with metadata, sorted by confidence score (highest first)
    /// - Throws: Error if fingerprinting or lookup fails
    public func identifyTrack(_ track: Track) async throws -> [AcoustIDMatch] {
        let fileURL = URL(fileURLWithPath: track.filePath)
        
        // Get fingerprint (from cache or generate)
        let fingerprint = try await getFingerprint(fileURL: fileURL)
        
        // Use track duration
        let duration = track.duration
        
        // Lookup matches
        var matches = try await lookupService.lookup(fingerprint: fingerprint, duration: duration)
        
        // Sort by score (highest first)
        matches.sort { $0.score > $1.score }
        
        return matches
    }
    
    // MARK: - Private Methods
    
    /// Get fingerprint from cache or generate new one
    private func getFingerprint(fileURL: URL) async throws -> String {
        let filePath = fileURL.path
        
        // Check cache first if available
        if let cache = fingerprintCache {
            // Get file modification time
            let fileAttributes = try? FileManager.default.attributesOfItem(atPath: filePath)
            let modificationTime = (fileAttributes?[.modificationDate] as? Date) ?? Date()
            
            // Check cache
            if let cachedEntry = try await cache.get(filePath: filePath) {
                // Verify file hasn't changed
                if cachedEntry.fileModificationTime == modificationTime {
                    // Cache hit - return cached fingerprint
                    return cachedEntry.fingerprint
                } else {
                    // File has changed - remove from cache
                    try? await cache.remove(filePath: filePath)
                }
            }
        }
        
        // Cache miss or no cache - generate fingerprint
        let fingerprint = try await fingerprintGenerator.generateFingerprint(fileURL: fileURL)
        
        // Store in cache if available
        if let cache = fingerprintCache {
            let fileAttributes = try? FileManager.default.attributesOfItem(atPath: filePath)
            let modificationTime = (fileAttributes?[.modificationDate] as? Date) ?? Date()
            
            let entry = FingerprintCacheEntry(
                filePath: filePath,
                fileModificationTime: modificationTime,
                fingerprint: fingerprint
            )
            
            try? await cache.store(entry)
        }
        
        return fingerprint
    }
}

extension AcoustIDService: AcoustIDServicing {}
