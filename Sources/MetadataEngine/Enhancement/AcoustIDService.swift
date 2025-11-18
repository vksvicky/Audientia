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
    
    /// Initialize with fingerprint generator and lookup service
    /// - Parameters:
    ///   - fingerprintGenerator: Service for generating audio fingerprints
    ///   - lookupService: Service for AcoustID lookup
    public init(
        fingerprintGenerator: FingerprintGeneratorProtocol,
        lookupService: AcoustIDLookupProtocol
    ) {
        self.fingerprintGenerator = fingerprintGenerator
        self.lookupService = lookupService
    }
    
    /// Identify a track by generating a fingerprint and looking it up
    /// - Parameter fileURL: The URL of the audio file
    /// - Returns: Array of potential matches with metadata, sorted by confidence score (highest first)
    /// - Throws: Error if fingerprinting or lookup fails
    public func identifyTrack(fileURL: URL) async throws -> [AcoustIDMatch] {
        // Generate fingerprint
        let fingerprint = try await fingerprintGenerator.generateFingerprint(fileURL: fileURL)
        
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
        
        // Generate fingerprint
        let fingerprint = try await fingerprintGenerator.generateFingerprint(fileURL: fileURL)
        
        // Use track duration
        let duration = track.duration
        
        // Lookup matches
        var matches = try await lookupService.lookup(fingerprint: fingerprint, duration: duration)
        
        // Sort by score (highest first)
        matches.sort { $0.score > $1.score }
        
        return matches
    }
}

extension AcoustIDService: AcoustIDServicing {}
