//
//  SimilarityEngine.swift
//  MetadataEngine
//
//  Similarity calculation engine implementation (Feature 5.2)
//

import Foundation
import os.log
@preconcurrency import Shared

/// Similarity calculation engine implementation
public actor SimilarityEngine: SimilarityEngineProtocol {
    private let logger = Logger(subsystem: "club.cycleruncode.audientia", category: "SimilarityEngine")
    private let classifier: any MLClassifierProtocol
    private var embeddingCache: [UUID: [Float]] = [:]
    
    public init(classifier: any MLClassifierProtocol) {
        self.classifier = classifier
    }
    
    // MARK: - SimilarityEngineProtocol
    
    public func calculateSimilarity(track1: Track, track2: Track) async throws -> Double {
        // Get embeddings for both tracks
        let embedding1 = try await getEmbedding(for: track1)
        let embedding2 = try await getEmbedding(for: track2)
        
        // Calculate cosine similarity
        return cosineSimilarity(embedding1: embedding1, embedding2: embedding2)
    }
    
    public func findSimilar(to track: Track, in tracks: [Track], limit: Int) async throws -> [SimilarityResult] {
        // Get embedding for query track
        let queryEmbedding = try await getEmbedding(for: track)
        
        // Calculate similarities for all candidate tracks
        var similarities: [SimilarityResult] = []
        
        for candidateTrack in tracks {
            // Skip the query track itself
            guard candidateTrack.id != track.id else { continue }
            
            do {
                let candidateEmbedding = try await getEmbedding(for: candidateTrack)
                let similarity = cosineSimilarity(embedding1: queryEmbedding, embedding2: candidateEmbedding)
                similarities.append(SimilarityResult(track: candidateTrack, similarity: similarity))
            } catch {
                // Skip tracks without embeddings
                logger.debug("Skipping track \(candidateTrack.title) - no embedding available")
                continue
            }
        }
        
        // Sort by similarity (descending) and return top N
        return Array(similarities.sorted { $0.similarity > $1.similarity }.prefix(limit))
    }
    
    public nonisolated func cosineSimilarity(embedding1: [Float], embedding2: [Float]) -> Double {
        // Validate embeddings have same dimension
        guard embedding1.count == embedding2.count else {
            // Can't use logger here since it's nonisolated, but that's okay for this pure function
            return 0.0
        }
        
        // Calculate dot product
        let dotProduct = zip(embedding1, embedding2).map { $0 * $1 }.reduce(0, +)
        
        // Calculate magnitudes
        let magnitude1 = sqrt(embedding1.map { $0 * $0 }.reduce(0, +))
        let magnitude2 = sqrt(embedding2.map { $0 * $0 }.reduce(0, +))
        
        // Avoid division by zero
        guard magnitude1 > 0 && magnitude2 > 0 else {
            return 0.0
        }
        
        // Cosine similarity = dot product / (magnitude1 * magnitude2)
        return Double(dotProduct) / (Double(magnitude1) * Double(magnitude2))
    }
    
    // MARK: - Private Helpers
    
    private func getEmbedding(for track: Track) async throws -> [Float] {
        // Check cache first
        if let cached = embeddingCache[track.id] {
            return cached
        }
        
        // Generate embedding using classifier
        let embedding = try await classifier.generateEmbedding(for: track)
        
        // Cache the embedding
        embeddingCache[track.id] = embedding
        
        return embedding
    }
    
    public func clearCache() {
        embeddingCache.removeAll()
    }
}
