//
//  MockRecommendationEngine.swift
//  MetadataEngineTests
//
//  Mock implementation of RecommendationEngineProtocol for testing
//

import Foundation
@testable import MetadataEngine
@testable import Shared

/// Mock implementation of RecommendationEngineProtocol for testing
public actor MockRecommendationEngine: RecommendationEngineProtocol {
    public var mockRecommendations: [Recommendation] = []
    public var shouldFail = false
    public var mockError: RecommendationError?
    
    public var recommendSimilarCalled = false
    public var recommendBasedOnHistoryCalled = false
    public var recommendContextAwareCalled = false
    
    public init() {}
    
    public func recommendSimilar(to track: Track, limit: Int) async throws -> [Recommendation] {
        recommendSimilarCalled = true
        
        if shouldFail {
            throw mockError ?? RecommendationError.recommendationFailed("Mock error")
        }
        
        return Array(mockRecommendations.sorted { $0.score > $1.score }.prefix(limit))
    }
    
    public func recommendBasedOnHistory(limit: Int) async throws -> [Recommendation] {
        recommendBasedOnHistoryCalled = true
        
        if shouldFail {
            throw mockError ?? RecommendationError.recommendationFailed("Mock error")
        }
        
        return Array(mockRecommendations.sorted { $0.score > $1.score }.prefix(limit))
    }
    
    public func recommendContextAware(limit: Int) async throws -> [Recommendation] {
        recommendContextAwareCalled = true
        
        if shouldFail {
            throw mockError ?? RecommendationError.recommendationFailed("Mock error")
        }
        
        return Array(mockRecommendations.sorted { $0.score > $1.score }.prefix(limit))
    }
    
    // Helper methods for test setup
    public func setMockRecommendations(_ recommendations: [Recommendation]) {
        self.mockRecommendations = recommendations
    }
    
    public func setShouldFail(_ shouldFail: Bool, error: RecommendationError? = nil) {
        self.shouldFail = shouldFail
        self.mockError = error
    }
}
