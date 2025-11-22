//
//  RecommendationEngine.swift
//  MetadataEngine
//
//  Recommendation engine implementation (Feature 5.2)
//

import Foundation
import os.log
@preconcurrency import Shared

/// Recommendation engine implementation
public actor RecommendationEngine: RecommendationEngineProtocol {
    private let logger = Logger(subsystem: "club.cycleruncode.audientia", category: "RecommendationEngine")
    private let similarityEngine: any SimilarityEngineProtocol
    private var allTracks: [Track] = []
    
    public init(similarityEngine: any SimilarityEngineProtocol) {
        self.similarityEngine = similarityEngine
    }
    
    // MARK: - RecommendationEngineProtocol
    
    public func recommendSimilar(to track: Track, limit: Int) async throws -> [Recommendation] {
        guard !allTracks.isEmpty else {
            throw RecommendationError.noTracksAvailable
        }
        
        // Find similar tracks using similarity engine
        let similarResults = try await similarityEngine.findSimilar(to: track, in: allTracks, limit: limit)
        
        // Convert to recommendations with reasons
        return similarResults.map { result in
            let reason = generateReason(for: result, basedOn: track)
            return Recommendation(track: result.track, score: result.similarity, reason: reason)
        }
    }
    
    public func recommendBasedOnHistory(limit: Int) async throws -> [Recommendation] {
        guard !allTracks.isEmpty else {
            throw RecommendationError.noTracksAvailable
        }
        
        // swiftlint:disable:next todo
        // TODO: Implement history-based recommendations
        // This would analyze:
        // - Play counts
        // - Skip rates
        // - Time-of-day patterns
        // - Day-of-week patterns
        
        // For now, return empty list
        logger.warning("History-based recommendations not yet implemented")
        return []
    }
    
    public func recommendContextAware(limit: Int) async throws -> [Recommendation] {
        guard !allTracks.isEmpty else {
            throw RecommendationError.noTracksAvailable
        }
        
        // swiftlint:disable:next todo
        // TODO: Implement context-aware recommendations
        // This would consider:
        // - Time of day
        // - Day of week
        // - Recent listening history
        // - Current activity (if available)
        
        // For now, return empty list
        logger.warning("Context-aware recommendations not yet implemented")
        return []
    }
    
    // MARK: - Public Helpers
    
    /// Update the track library for recommendations
    public func updateTrackLibrary(_ tracks: [Track]) {
        self.allTracks = tracks
        logger.info("Updated recommendation engine with \(tracks.count) tracks")
    }
    
    // MARK: - Private Helpers
    
    private func generateReason(for result: SimilarityResult, basedOn track: Track) -> String {
        var reasons: [String] = []
        
        // Add similarity-based reason
        if result.similarity > 0.9 {
            reasons.append("Very similar audio features")
        } else if result.similarity > 0.7 {
            reasons.append("Similar audio features")
        } else {
            reasons.append("Somewhat similar audio features")
        }
        
        // Add metadata-based reasons
        if result.track.artist == track.artist {
            reasons.append("same artist")
        }
        
        if result.track.album == track.album {
            reasons.append("same album")
        }
        
        if let genre1 = track.genre, let genre2 = result.track.genre, genre1 == genre2 {
            reasons.append("same genre")
        }
        
        return reasons.joined(separator: ", ")
    }
}
