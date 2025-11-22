//
//  AudioFeatureExtractorProtocol.swift
//  MetadataEngine
//
//  Protocol for audio feature extraction (Feature 5.2)
//

import Foundation
@preconcurrency import Shared

/// Protocol for extracting audio features for ML classification
public protocol AudioFeatureExtractorProtocol: Sendable {
    /// Extract audio features from a track
    /// - Parameter track: Track to extract features from
    /// - Returns: Feature vector (e.g., MFCC, spectral features)
    /// - Throws: MLClassificationError if extraction fails
    func extractFeatures(from track: Track) async throws -> [Float]
}

/// Audio feature extraction errors
public enum AudioFeatureExtractionError: Error, Sendable, Equatable {
    case fileNotFound
    case unsupportedFormat
    case extractionFailed(String)
    case insufficientAudioData
}
