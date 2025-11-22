//
//  RecommendationEngineProtocol.swift
//  MetadataEngine
//
//  Protocol for recommendation engine (Feature 5.2)
//

import Foundation
@preconcurrency import Shared

/// Recommendation result
public struct Recommendation: Sendable, Equatable {
    public let track: Track
    public let score: Double
    public let reason: String
    
    public init(track: Track, score: Double, reason: String) {
        self.track = track
        self.score = score
        self.reason = reason
    }
}

/// Recommendation errors
public enum RecommendationError: Error, Sendable, Equatable {
    case noTracksAvailable
    case insufficientData
    case recommendationFailed(String)
}

/// Protocol for recommendation engine
public protocol RecommendationEngineProtocol: Sendable {
    /// Get recommendations based on a track
    func recommendSimilar(to track: Track, limit: Int) async throws -> [Recommendation]
    
    /// Get recommendations based on listening history
    func recommendBasedOnHistory(limit: Int) async throws -> [Recommendation]
    
    /// Get context-aware recommendations (time of day, recent plays, etc.)
    func recommendContextAware(limit: Int) async throws -> [Recommendation]
}
