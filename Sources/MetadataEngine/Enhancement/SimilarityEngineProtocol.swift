//
//  SimilarityEngineProtocol.swift
//  MetadataEngine
//
//  Protocol for similarity calculation (Feature 5.2)
//

import Foundation
@preconcurrency import Shared

/// Similarity calculation result
public struct SimilarityResult: Sendable, Equatable {
    public let track: Track
    public let similarity: Double
    
    public init(track: Track, similarity: Double) {
        self.track = track
        self.similarity = similarity
    }
}

/// Similarity calculation errors
public enum SimilarityError: Error, Sendable, Equatable {
    case noEmbedding(Track)
    case embeddingGenerationFailed
    case invalidEmbedding
    case calculationFailed(String)
}

/// Protocol for similarity calculation
public protocol SimilarityEngineProtocol: Sendable {
    /// Calculate similarity between two tracks
    func calculateSimilarity(track1: Track, track2: Track) async throws -> Double
    
    /// Find similar tracks to a given track
    func findSimilar(to track: Track, in tracks: [Track], limit: Int) async throws -> [SimilarityResult]
    
    /// Calculate cosine similarity between two embeddings
    func cosineSimilarity(embedding1: [Float], embedding2: [Float]) -> Double
}
