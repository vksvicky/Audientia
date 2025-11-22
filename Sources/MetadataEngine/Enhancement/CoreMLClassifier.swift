//
//  CoreMLClassifier.swift
//  MetadataEngine
//
//  Core ML-based classifier implementation (Feature 5.2)
//

import CoreML
import Foundation
import os.log
@preconcurrency import Shared

/// Core ML-based classifier implementation
/// Uses Core ML models for genre/mood classification and embedding generation
public actor CoreMLClassifier: MLClassifierProtocol {
    private let logger = Logger(subsystem: "club.cycleruncode.audientia", category: "MLClassifier")
    private let featureExtractor: AudioFeatureExtractorProtocol
    private var genreModel: MLModel?
    private var moodModel: MLModel?
    private var embeddingModel: MLModel?
    private var modelsLoaded = false
    
    public init(featureExtractor: AudioFeatureExtractorProtocol = AVFoundationFeatureExtractor()) {
        self.featureExtractor = featureExtractor
        // Models will be loaded lazily when needed
    }
    
    // MARK: - MLClassifierProtocol
    
    public func classifyGenre(for track: Track) async throws -> GenreClassification {
        // Validate track duration
        guard track.duration >= 5.0 else {
            throw MLClassificationError.insufficientAudioData
        }
        
        // Load model if needed
        try await ensureModelsLoaded()
        
        guard genreModel != nil else {
            throw MLClassificationError.modelNotAvailable
        }
        
        // Extract audio features
        let features = try await featureExtractor.extractFeatures(from: track)
        
        logger.debug("Classifying genre for track: \(track.title) with \(features.count) features")
        
        // Create model input and get prediction
        guard let model = genreModel else {
            throw MLClassificationError.modelNotAvailable
        }
        
        let input = try createGenreModelInput(features: features)
        let prediction = try await model.prediction(from: input)
        
        return try parseGenreClassification(from: prediction)
    }
    
    public func classifyMood(for track: Track) async throws -> MoodClassification {
        // Validate track duration
        guard track.duration >= 5.0 else {
            throw MLClassificationError.insufficientAudioData
        }
        
        // Load model if needed
        try await ensureModelsLoaded()
        
        guard moodModel != nil else {
            throw MLClassificationError.modelNotAvailable
        }
        
        // Extract audio features
        let features = try await featureExtractor.extractFeatures(from: track)
        
        logger.debug("Classifying mood for track: \(track.title) with \(features.count) features")
        
        // Create model input and get prediction
        guard let model = moodModel else {
            throw MLClassificationError.modelNotAvailable
        }
        
        let input = try createMoodModelInput(features: features)
        let prediction = try await model.prediction(from: input)
        
        return try parseMoodClassification(from: prediction)
    }
    
    public func generateEmbedding(for track: Track) async throws -> [Float] {
        // Validate track duration
        guard track.duration >= 5.0 else {
            throw MLClassificationError.insufficientAudioData
        }
        
        // Load model if needed
        try await ensureModelsLoaded()
        
        guard embeddingModel != nil else {
            throw MLClassificationError.modelNotAvailable
        }
        
        // Extract audio features
        let features = try await featureExtractor.extractFeatures(from: track)
        
        logger.debug("Generating embedding for track: \(track.title) with \(features.count) features")
        
        // Create model input and get prediction
        guard let model = embeddingModel else {
            throw MLClassificationError.modelNotAvailable
        }
        
        let input = try createEmbeddingModelInput(features: features)
        let prediction = try await model.prediction(from: input)
        
        return try parseEmbedding(from: prediction)
    }
    
    public func isAvailable() async -> Bool {
        do {
            try await ensureModelsLoaded()
            return genreModel != nil || moodModel != nil || embeddingModel != nil
        } catch {
            return false
        }
    }
    
    // MARK: - Private Helpers
    
    private func ensureModelsLoaded() async throws {
        guard !modelsLoaded else { return }
        
        // Try to load models from app bundle
        // Models should be in Resources folder: GenreClassifier.mlmodel, MoodClassifier.mlmodel, EmbeddingModel.mlmodel
        if let genreModelURL = Bundle.main.url(forResource: "GenreClassifier", withExtension: "mlmodel") {
            do {
                genreModel = try MLModel(contentsOf: genreModelURL)
                logger.info("Genre classifier model loaded")
            } catch {
                logger.warning("Failed to load genre classifier model: \(error.localizedDescription)")
            }
        }
        
        if let moodModelURL = Bundle.main.url(forResource: "MoodClassifier", withExtension: "mlmodel") {
            do {
                moodModel = try MLModel(contentsOf: moodModelURL)
                logger.info("Mood classifier model loaded")
            } catch {
                logger.warning("Failed to load mood classifier model: \(error.localizedDescription)")
            }
        }
        
        if let embeddingModelURL = Bundle.main.url(forResource: "EmbeddingModel", withExtension: "mlmodel") {
            do {
                embeddingModel = try MLModel(contentsOf: embeddingModelURL)
                logger.info("Embedding model loaded")
            } catch {
                logger.warning("Failed to load embedding model: \(error.localizedDescription)")
            }
        }
        
        modelsLoaded = true
    }
    
    // MARK: - Model Input Creation
    
    private func createGenreModelInput(features: [Float]) throws -> MLFeatureProvider {
        // Create MLMultiArray from features
        // The exact structure depends on the model, but typically it's a 1D array
        let shape = [NSNumber(value: features.count)]
        guard let multiArray = try? MLMultiArray(shape: shape, dataType: .float32) else {
            throw MLClassificationError.invalidModel
        }
        
        for (index, value) in features.enumerated() {
            multiArray[index] = NSNumber(value: value)
        }
        
        // Create feature provider
        // Model input name is typically "features" or "input" - adjust based on actual model
        let inputName = "features" // This should match the model's input name
        let featureValue = MLFeatureValue(multiArray: multiArray)
        
        return try MLDictionaryFeatureProvider(dictionary: [inputName: featureValue])
    }
    
    private func createMoodModelInput(features: [Float]) throws -> MLFeatureProvider {
        // Same structure as genre model
        try createGenreModelInput(features: features)
    }
    
    private func createEmbeddingModelInput(features: [Float]) throws -> MLFeatureProvider {
        // Same structure as genre model
        try createGenreModelInput(features: features)
    }
    
    // MARK: - Prediction Parsing
    
    private func parseGenreClassification(from prediction: MLFeatureProvider) throws -> GenreClassification {
        // Parse prediction output
        // Model output structure depends on the model, but typically:
        // - Output name: "genre" or "output" or "classLabelProbs"
        // - Format: Dictionary of genre -> probability or MLMultiArray
        
        // Try common output names
        let possibleOutputNames = ["genre", "output", "classLabelProbs", "probabilities"]
        
        for outputName in possibleOutputNames {
            if let featureValue = prediction.featureValue(for: outputName) {
                // Check if the feature value is a dictionary type
                if featureValue.type == .dictionary {
                    let dictionary = featureValue.dictionaryValue
                    // Dictionary format: ["Rock": 0.85, "Jazz": 0.10, ...]
                    // dictionaryValue returns [AnyHashable: NSNumber]
                    var probabilities: [String: Double] = [:]
                    for (key, value) in dictionary {
                        // Convert AnyHashable key to String
                        guard let stringKey = key as? String else {
                            continue
                        }
                        // NSNumber can be converted to Double
                        probabilities[stringKey] = value.doubleValue
                    }
                    
                    // Find genre with highest probability
                    guard let (genre, confidence) = probabilities.max(by: { $0.value < $1.value }) else {
                        throw MLClassificationError.classificationFailed("No genre probabilities found")
                    }
                    
                    return GenreClassification(
                        genre: genre,
                        confidence: confidence,
                        allProbabilities: probabilities
                    )
                } else if let multiArray = featureValue.multiArrayValue {
                    // MultiArray format: Need to map indices to genre names
                    // This requires model metadata - for now, use generic approach
                    let probabilities = try parseMultiArrayToProbabilities(multiArray)
                    
                    guard let (genre, confidence) = probabilities.max(by: { $0.value < $1.value }) else {
                        throw MLClassificationError.classificationFailed("No genre probabilities found")
                    }
                    
                    return GenreClassification(
                        genre: genre,
                        confidence: confidence,
                        allProbabilities: probabilities
                    )
                }
            }
        }
        
        throw MLClassificationError.classificationFailed("Could not parse genre prediction")
    }
    
    private func parseMoodClassification(from prediction: MLFeatureProvider) throws -> MoodClassification {
        // Similar to genre classification
        let possibleOutputNames = ["mood", "output", "classLabelProbs", "probabilities"]
        
        for outputName in possibleOutputNames {
            if let featureValue = prediction.featureValue(for: outputName) {
                // Check if the feature value is a dictionary type
                if featureValue.type == .dictionary {
                    let dictionary = featureValue.dictionaryValue
                    // dictionaryValue returns [AnyHashable: NSNumber]
                    var probabilities: [String: Double] = [:]
                    for (key, value) in dictionary {
                        // Convert AnyHashable key to String
                        guard let stringKey = key as? String else {
                            continue
                        }
                        // NSNumber can be converted to Double
                        probabilities[stringKey] = value.doubleValue
                    }
                    
                    guard let (mood, confidence) = probabilities.max(by: { $0.value < $1.value }) else {
                        throw MLClassificationError.classificationFailed("No mood probabilities found")
                    }
                    
                    return MoodClassification(
                        mood: mood,
                        confidence: confidence,
                        allProbabilities: probabilities
                    )
                } else if let multiArray = featureValue.multiArrayValue {
                    let probabilities = try parseMultiArrayToProbabilities(multiArray)
                    
                    guard let (mood, confidence) = probabilities.max(by: { $0.value < $1.value }) else {
                        throw MLClassificationError.classificationFailed("No mood probabilities found")
                    }
                    
                    return MoodClassification(
                        mood: mood,
                        confidence: confidence,
                        allProbabilities: probabilities
                    )
                }
            }
        }
        
        throw MLClassificationError.classificationFailed("Could not parse mood prediction")
    }
    
    private func parseEmbedding(from prediction: MLFeatureProvider) throws -> [Float] {
        // Parse embedding output
        // Typically a 1D MLMultiArray
        let possibleOutputNames = ["embedding", "output", "features"]
        
        for outputName in possibleOutputNames {
            if let featureValue = prediction.featureValue(for: outputName),
               let multiArray = featureValue.multiArrayValue {
                var embedding: [Float] = []
                for i in 0..<multiArray.count {
                    embedding.append(Float(truncating: multiArray[i]))
                }
                return embedding
            }
        }
        
        throw MLClassificationError.classificationFailed("Could not parse embedding")
    }
    
    private func parseMultiArrayToProbabilities(_ multiArray: MLMultiArray) throws -> [String: Double] {
        // Map multiArray indices to genre/mood names
        // In a real implementation, this would use model metadata
        // For now, use generic labels
        let labels = ["Rock", "Jazz", "Classical", "Electronic", "Pop", "Hip-Hop", "Country", "Blues"]
        var probabilities: [String: Double] = [:]
        
        let count = min(multiArray.count, labels.count)
        for i in 0..<count {
            let value = Double(truncating: multiArray[i])
            probabilities[labels[i]] = value
        }
        
        return probabilities
    }
}
