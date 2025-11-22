//
//  MLClassificationProtocol.swift
//  MetadataEngine
//
//  Protocol for ML classification features (Feature 5.2)
//

import Foundation
@preconcurrency import Shared

/// Genre classification result
public struct GenreClassification: Sendable, Equatable {
    public let genre: String
    public let confidence: Double
    public let allProbabilities: [String: Double]
    
    public init(genre: String, confidence: Double, allProbabilities: [String: Double]) {
        self.genre = genre
        self.confidence = confidence
        self.allProbabilities = allProbabilities
    }
}

/// Mood classification result
public struct MoodClassification: Sendable, Equatable {
    public let mood: String
    public let confidence: Double
    public let allProbabilities: [String: Double]
    
    public init(mood: String, confidence: Double, allProbabilities: [String: Double]) {
        self.mood = mood
        self.confidence = confidence
        self.allProbabilities = allProbabilities
    }
}

/// ML classification errors
public enum MLClassificationError: Error, Sendable, Equatable {
    case modelNotAvailable
    case insufficientAudioData
    case audioProcessingFailed
    case invalidModel
    case classificationFailed(String)
}

/// Protocol for ML classification functionality
public protocol MLClassifierProtocol: Sendable {
    /// Classify genre for a track
    func classifyGenre(for track: Track) async throws -> GenreClassification
    
    /// Classify mood for a track
    func classifyMood(for track: Track) async throws -> MoodClassification
    
    /// Generate audio embedding for similarity calculation
    func generateEmbedding(for track: Track) async throws -> [Float]
    
    /// Check if classification models are available
    func isAvailable() async -> Bool
}
