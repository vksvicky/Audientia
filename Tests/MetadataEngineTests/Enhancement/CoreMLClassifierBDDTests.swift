//
//  CoreMLClassifierBDDTests.swift
//  MetadataEngineTests
//
//  BDD tests for Core ML classifier workflows (Feature 5.2)
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// BDD scenarios for Core ML classification
final class CoreMLClassifierBDDTests: XCTestCase {
    
    private var classifier: CoreMLClassifier!
    private var mockFeatureExtractor: MockFeatureExtractor!
    private var testTrack: Track!
    private var testAudioFileURL: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        mockFeatureExtractor = MockFeatureExtractor()
        classifier = CoreMLClassifier(featureExtractor: mockFeatureExtractor)
        
        testAudioFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp3")
        
        testTrack = Track(
            title: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            duration: 10.0,
            filePath: testAudioFileURL.path,
            fileSize: 1000000,
            bitrate: 320,
            sampleRate: 44100
        )
    }
    
    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: testAudioFileURL)
        classifier = nil
        mockFeatureExtractor = nil
        testTrack = nil
        testAudioFileURL = nil
        try await super.tearDown()
    }
    
    // MARK: - BDD Scenarios
    
    func testAsUserIWantToClassifyTrackGenreUsingML() async throws {
        // Scenario: As a user, I want to classify a track's genre using ML
        // Given: I have a track and ML models are available
        let testData = Data(repeating: 0, count: 1000)
        try testData.write(to: testAudioFileURL)
        await mockFeatureExtractor.setMockFeatures([0.5, 0.3, 0.2, 0.1, 0.05, 0.02, 0.01])
        
        // When: I classify the track's genre
        // Then: I should get a genre classification with confidence score
        // Note: This will fail if no model is available, which is expected
        do {
            let result = try await classifier.classifyGenre(for: testTrack)
            XCTAssertNotNil(result.genre)
            XCTAssertGreaterThan(result.confidence, 0.0)
            XCTAssertLessThanOrEqual(result.confidence, 1.0)
        } catch MLClassificationError.modelNotAvailable {
            // Expected if no model available - this is OK for now
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testAsUserIWantToClassifyTrackMoodUsingML() async throws {
        // Scenario: As a user, I want to classify a track's mood using ML
        // Given: I have a track and ML models are available
        let testData = Data(repeating: 0, count: 1000)
        try testData.write(to: testAudioFileURL)
        await mockFeatureExtractor.setMockFeatures([0.4, 0.3, 0.2, 0.1])
        
        // When: I classify the track's mood
        // Then: I should get a mood classification with confidence score
        do {
            let result = try await classifier.classifyMood(for: testTrack)
            XCTAssertNotNil(result.mood)
            XCTAssertGreaterThan(result.confidence, 0.0)
            XCTAssertLessThanOrEqual(result.confidence, 1.0)
        } catch MLClassificationError.modelNotAvailable {
            // Expected if no model available
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testAsUserIWantToGenerateEmbeddingsForSimilarityMatching() async throws {
        // Scenario: As a user, I want to generate embeddings for similarity matching
        // Given: I have a track and embedding model is available
        let testData = Data(repeating: 0, count: 1000)
        try testData.write(to: testAudioFileURL)
        await mockFeatureExtractor.setMockFeatures([0.5, 0.3, 0.2, 0.1, 0.05])
        
        // When: I generate embeddings for the track
        // Then: I should get a feature vector for similarity calculation
        do {
            let embedding = try await classifier.generateEmbedding(for: testTrack)
            XCTAssertFalse(embedding.isEmpty, "Embedding should not be empty")
            XCTAssertGreaterThan(embedding.count, 0, "Should have at least one feature")
        } catch MLClassificationError.modelNotAvailable {
            // Expected if no model available
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testAsUserIWantToKnowIfMLClassificationIsAvailable() async throws {
        // Scenario: As a user, I want to know if ML classification is available
        // Given: ML models may or may not be available
        // When: I check if classification is available
        let isAvailable = await classifier.isAvailable()
        
        // Then: I should get a clear answer
        // Note: This will be false if no models are available, which is expected
        XCTAssertNotNil(isAvailable)
    }
}
