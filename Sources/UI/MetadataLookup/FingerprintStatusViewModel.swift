//
//  FingerprintStatusViewModel.swift
//  Audientia - Fingerprint Status ViewModel
//
//  ViewModel for managing fingerprint status and manual fingerprint generation
//

import Foundation
import MetadataEngine
import os.log
import Shared
import SwiftUI

@MainActor
public final class FingerprintStatusViewModel: ObservableObject {
    @Published public var fingerprintStatus: FingerprintStatus = .unknown
    @Published public var isGenerating = false
    @Published public var lastError: Error?
    @Published public var fingerprint: String?
    
    private let acoustIDService: any AcoustIDServicing
    private let fingerprintCache: (any FingerprintCacheProtocol)?
    private let logger = Logger(subsystem: "club.cycleruncode.audientia", category: "FingerprintStatus")
    
    public enum FingerprintStatus: Equatable {
        case unknown
        case notCached
        case cached
        case generating
        case error(String)
        
        public var displayText: String {
            switch self {
            case .unknown:
                return "Unknown"
            case .notCached:
                return "Not Fingerprinted"
            case .cached:
                return "Fingerprinted"
            case .generating:
                return "Generating..."
            case let .error(message):
                return "Error: \(message)"
            }
        }
        
        public var systemImage: String {
            switch self {
            case .unknown:
                return "questionmark.circle"
            case .notCached:
                return "circle"
            case .cached:
                return "checkmark.circle.fill"
            case .generating:
                return "arrow.triangle.2.circlepath"
            case .error:
                return "exclamationmark.triangle.fill"
            }
        }
        
        public var color: Color {
            switch self {
            case .unknown:
                return .secondary
            case .notCached:
                return .secondary
            case .cached:
                return .green
            case .generating:
                return .blue
            case .error:
                return .red
            }
        }
    }
    
    public init(
        acoustIDService: any AcoustIDServicing,
        fingerprintCache: (any FingerprintCacheProtocol)? = nil
    ) {
        self.acoustIDService = acoustIDService
        self.fingerprintCache = fingerprintCache
    }
    
    /// Check fingerprint status for a track
    public func checkStatus(for track: Track) async {
        guard let cache = fingerprintCache else {
            fingerprintStatus = .unknown
            return
        }
        
        do {
            let filePath = track.filePath
            let isCached = try await cache.isCached(filePath: filePath)
            
            if isCached {
                // Get the cached fingerprint
                if let entry = try await cache.get(filePath: filePath) {
                    fingerprint = entry.fingerprint
                    fingerprintStatus = .cached
                } else {
                    fingerprintStatus = .notCached
                }
            } else {
                fingerprintStatus = .notCached
            }
        } catch {
            logger.error("Failed to check fingerprint status: \(error.localizedDescription, privacy: .public)")
            fingerprintStatus = .error(error.localizedDescription)
            lastError = error
        }
    }
    
    /// Manually generate fingerprint for a track
    public func generateFingerprint(for track: Track) async {
        isGenerating = true
        fingerprintStatus = .generating
        lastError = nil
        
        do {
            let fileURL = URL(fileURLWithPath: track.filePath)
            
            // Use AcoustIDService to identify track (which will generate fingerprint)
            // This will also cache it if cache is available
            _ = try await acoustIDService.identifyTrack(fileURL: fileURL)
            
            // Check status again to update UI
            await checkStatus(for: track)
            
            logger.info("Fingerprint generated successfully for track: \(track.title, privacy: .public)")
        } catch {
            logger.error("Failed to generate fingerprint: \(error.localizedDescription, privacy: .public)")
            fingerprintStatus = .error(error.localizedDescription)
            lastError = error
        }
        
        isGenerating = false
    }
    
    /// Clear fingerprint status (reset to unknown)
    public func clearStatus() {
        fingerprintStatus = .unknown
        fingerprint = nil
        lastError = nil
    }
}
