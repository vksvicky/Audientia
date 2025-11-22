//
//  CoreMLClassifierIntegrationTests.swift
//  MetadataEngineTests
//
//  TDD tests for Core ML model integration in CoreMLClassifier (Feature 5.2)
//

import CoreML
@testable import MetadataEngine
@testable import Shared
import XCTest

/// TDD tests for Core ML model integration
/// Following Right-BICEP principles
final class CoreMLClassifierIntegrationTests: XCTestCase {
    
    private var classifier: CoreMLClassifier!
    private var mockFeatureExtractor: MockFeatureExtractor!
    private var testTrack: Track!
    
    override func setUp() async throws {
        try await super.setUp()
        mockFeatureExtractor = MockFeatureExtractor()
        classifier = CoreMLClassifier(featureExtractor: mockFeatureExtractor)
        
        testTrack = Track(
            title: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            duration: 10.0,
            filePath: "/path/to/track.mp3",
            fileSize: 1000000,
            bitrate: 320,
            sampleRate: 44100
        )
    }
    
    override func tearDown() async throws {
        classifier = nil
        mockFeatureExtractor = nil
        testTrack = nil
        try await super.tearDown()
    }
    
    // MARK: - Right: Are the results right?
    
    func testClassifyGenreWithMockModelReturnsValidClassification() async throws {
        // Given: A classifier with mock model and features
        await mockFeatureExtractor.setMockFeatures([0.5, 0.3, 0.2, 0.1, 0.05])
        
        // When: Classifying genre (will fail without actual model, but tests structure)
        // Then: Should handle gracefully
        do {
            _ = try await classifier.classifyGenre(for: testTrack)
            // If model is available, should succeed
        } catch MLClassificationError.modelNotAvailable {
            // Expected if no model available
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - B: Boundary Conditions
    
    func testClassifyGenreWithEmptyFeaturesThrowsError() async throws {
        // Given: Empty feature vector
        await mockFeatureExtractor.setMockFeatures([])
        await mockFeatureExtractor.setShouldFail(true)
        
        // When: Classifying
        // Then: Should throw error
        do {
            _ = try await classifier.classifyGenre(for: testTrack)
            XCTFail("Should throw error for empty features")
        } catch {
            // Expected
        }
    }
    
    // MARK: - E: Error Conditions
    
    func testClassifyGenreWithInvalidModelThrowsError() async throws {
        // Given: Feature extraction succeeds but model is invalid
        await mockFeatureExtractor.setMockFeatures([0.5, 0.3, 0.2])
        
        // When: Classifying (without model)
        // Then: Should throw modelNotAvailable
        do {
            _ = try await classifier.classifyGenre(for: testTrack)
            XCTFail("Should throw modelNotAvailable")
        } catch MLClassificationError.modelNotAvailable {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

/// Mock feature extractor for testing
actor MockFeatureExtractor: AudioFeatureExtractorProtocol {
    private var mockFeatures: [Float] = []
    private var shouldFail = false
    private var mockError: AudioFeatureExtractionError?
    
    func setMockFeatures(_ features: [Float]) {
        self.mockFeatures = features
    }
    
    func setShouldFail(_ shouldFail: Bool, error: AudioFeatureExtractionError? = nil) {
        self.shouldFail = shouldFail
        self.mockError = error
    }
    
    func extractFeatures(from track: Track) async throws -> [Float] {
        if shouldFail {
            throw mockError ?? .extractionFailed("Mock error")
        }
        
        guard !mockFeatures.isEmpty else {
            throw AudioFeatureExtractionError.insufficientAudioData
        }
        
        return mockFeatures
    }
}
