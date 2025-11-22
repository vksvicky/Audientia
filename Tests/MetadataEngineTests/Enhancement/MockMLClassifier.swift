//
//  MockMLClassifier.swift
//  MetadataEngineTests
//
//  Mock implementation of MLClassifierProtocol for testing
//

import Foundation
@testable import MetadataEngine
@testable import Shared

/// Mock implementation of MLClassifierProtocol for testing
public actor MockMLClassifier: MLClassifierProtocol {
    public var mockGenreClassification: GenreClassification?
    public var mockMoodClassification: MoodClassification?
    public var mockEmbedding: [Float]?
    public var shouldFailClassification = false
    public var mockError: MLClassificationError?
    public var isAvailableValue = true
    
    public var classifyGenreCalled = false
    public var classifyMoodCalled = false
    public var generateEmbeddingCalled = false
    
    public init() {}
    
    public func classifyGenre(for track: Track) async throws -> GenreClassification {
        classifyGenreCalled = true
        
        if shouldFailClassification {
            throw mockError ?? MLClassificationError.classificationFailed("Mock error")
        }
        
        guard let classification = mockGenreClassification else {
            throw MLClassificationError.classificationFailed("No mock classification set")
        }
        
        return classification
    }
    
    public func classifyMood(for track: Track) async throws -> MoodClassification {
        classifyMoodCalled = true
        
        if shouldFailClassification {
            throw mockError ?? MLClassificationError.classificationFailed("Mock error")
        }
        
        guard let classification = mockMoodClassification else {
            throw MLClassificationError.classificationFailed("No mock mood classification set")
        }
        
        return classification
    }
    
    public func generateEmbedding(for track: Track) async throws -> [Float] {
        generateEmbeddingCalled = true
        
        if shouldFailClassification {
            throw mockError ?? MLClassificationError.classificationFailed("Mock error")
        }
        
        guard let embedding = mockEmbedding else {
            throw MLClassificationError.classificationFailed("No mock embedding set")
        }
        
        return embedding
    }
    
    public func isAvailable() async -> Bool {
        isAvailableValue
    }
    
    // Helper methods for test setup
    public func setMockGenreClassification(_ classification: GenreClassification) {
        self.mockGenreClassification = classification
    }
    
    public func setMockMoodClassification(_ classification: MoodClassification) {
        self.mockMoodClassification = classification
    }
    
    public func setMockEmbedding(_ embedding: [Float]) {
        self.mockEmbedding = embedding
    }
    
    public func setShouldFail(_ shouldFail: Bool, error: MLClassificationError? = nil) {
        self.shouldFailClassification = shouldFail
        self.mockError = error
    }
    
    public func setIsAvailable(_ available: Bool) {
        self.isAvailableValue = available
    }
}
