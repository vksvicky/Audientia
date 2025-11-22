//
//  MockSimilarityEngine.swift
//  MetadataEngineTests
//
//  Mock implementation of SimilarityEngineProtocol for testing
//

import Foundation
@testable import MetadataEngine
@testable import Shared

/// Mock implementation of SimilarityEngineProtocol for testing
public actor MockSimilarityEngine: SimilarityEngineProtocol {
    public var mockSimilarity: Double = 0.5
    public var mockSimilarityResults: [SimilarityResult] = []
    public var shouldFail = false
    public var mockError: SimilarityError?
    
    public var calculateSimilarityCalled = false
    public var findSimilarCalled = false
    public var cosineSimilarityCalled = false
    
    public init() {}
    
    public func calculateSimilarity(track1: Track, track2: Track) async throws -> Double {
        calculateSimilarityCalled = true
        
        if shouldFail {
            throw mockError ?? SimilarityError.calculationFailed("Mock error")
        }
        
        return mockSimilarity
    }
    
    public func findSimilar(to track: Track, in tracks: [Track], limit: Int) async throws -> [SimilarityResult] {
        findSimilarCalled = true
        
        if shouldFail {
            throw mockError ?? SimilarityError.calculationFailed("Mock error")
        }
        
        // Return mock results sorted by similarity (descending)
        return Array(mockSimilarityResults.sorted { $0.similarity > $1.similarity }.prefix(limit))
    }
    
    public nonisolated func cosineSimilarity(embedding1: [Float], embedding2: [Float]) -> Double {
        // Note: This is nonisolated to match the actual implementation
        // Simple mock implementation: return 1.0 if identical, 0.0 if orthogonal
        if embedding1 == embedding2 {
            return 1.0
        }
        
        // Check if orthogonal (dot product would be 0)
        let dotProduct = zip(embedding1, embedding2).map(*).reduce(0, +)
        if abs(dotProduct) < 0.0001 {
            return 0.0
        }
        
        // For nonisolated method, we can't access actor-isolated properties
        // Return a default value or calculate based on inputs
        return 0.5
    }
    
    // Helper methods for test setup
    public func setMockSimilarity(_ similarity: Double) {
        self.mockSimilarity = similarity
    }
    
    public func setMockSimilarityResults(_ results: [SimilarityResult]) {
        self.mockSimilarityResults = results
    }
    
    public func setShouldFail(_ shouldFail: Bool, error: SimilarityError? = nil) {
        self.shouldFail = shouldFail
        self.mockError = error
    }
}
