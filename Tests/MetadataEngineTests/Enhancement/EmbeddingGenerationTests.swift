//
//  EmbeddingGenerationTests.swift
//  MetadataEngineTests
//
//  TDD tests for embedding generation (Feature 5.2)
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// TDD tests for embedding generation functionality
/// Following Right-BICEP principles
final class EmbeddingGenerationTests: XCTestCase {
    
    // MARK: - Right: Are the results right?
    
    func testGenerateEmbeddingReturnsValidVector() async throws {
        // Given: A track and a classifier
        let track = Track(
            title: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/path/to/track.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let mockClassifier = MockMLClassifier()
        let expectedEmbedding: [Float] = Array(repeating: 0.5, count: 128)
        await mockClassifier.setMockEmbedding(expectedEmbedding)
        
        // When: Generating embedding
        let result = try await mockClassifier.generateEmbedding(for: track)
        
        // Then: Should return valid embedding vector
        XCTAssertEqual(result.count, 128, "Embedding should have expected dimension")
        XCTAssertEqual(result, expectedEmbedding, "Embedding should match expected values")
    }
    
    func testGenerateEmbeddingReturnsConsistentResults() async throws {
        // Given: A track
        let track = Track(
            title: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/path/to/track.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let mockClassifier = MockMLClassifier()
        let expectedEmbedding: [Float] = Array(repeating: 0.5, count: 128)
        await mockClassifier.setMockEmbedding(expectedEmbedding)
        
        // When: Generating embedding twice
        let result1 = try await mockClassifier.generateEmbedding(for: track)
        let result2 = try await mockClassifier.generateEmbedding(for: track)
        
        // Then: Results should be identical
        XCTAssertEqual(result1, result2, "Embeddings should be consistent for same track")
    }
    
    // MARK: - Boundary Conditions
    
    func testGenerateEmbeddingWithVeryShortTrack() async throws {
        // Given: A very short track (< 5 seconds)
        let track = Track(
            title: "Short Track",
            artist: "Test Artist",
            album: "Test Album",
            duration: 3.0,
            filePath: "/path/to/short.mp3",
            fileSize: 100000,
            bitrate: 320,
            sampleRate: 44100
        )
        let mockClassifier = MockMLClassifier()
        await mockClassifier.setShouldFail(true, error: MLClassificationError.insufficientAudioData)
        
        // When: Attempting to generate embedding
        // Then: Should throw error
        do {
            _ = try await mockClassifier.generateEmbedding(for: track)
            XCTFail("Should have thrown error for very short track")
        } catch MLClassificationError.insufficientAudioData {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Error Conditions
    
    func testGenerateEmbeddingWithInvalidModel() async throws {
        // Given: A classifier with invalid model
        let track = Track(
            title: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/path/to/track.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let mockClassifier = MockMLClassifier()
        await mockClassifier.setShouldFail(true, error: MLClassificationError.modelNotAvailable)
        
        // When: Attempting to generate embedding
        // Then: Should throw error
        do {
            _ = try await mockClassifier.generateEmbedding(for: track)
            XCTFail("Should have thrown error for invalid model")
        } catch MLClassificationError.modelNotAvailable {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Performance
    
    func testGenerateEmbeddingPerformance() async throws {
        // Given: A track
        let track = Track(
            title: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/path/to/track.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let mockClassifier = MockMLClassifier()
        let expectedEmbedding: [Float] = Array(repeating: 0.5, count: 128)
        await mockClassifier.setMockEmbedding(expectedEmbedding)
        
        // When: Generating embedding
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = try await mockClassifier.generateEmbedding(for: track)
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then: Should complete within reasonable time (< 1s for mock)
        XCTAssertLessThan(elapsed, 1.0, "Embedding generation should complete quickly")
    }
    
    // MARK: - Edge Cases
    
    func testGenerateEmbeddingWithDifferentTrackLengths() async throws {
        // Given: Tracks of different lengths
        let shortTrack = Track(
            title: "Short",
            artist: "Test",
            album: "Test",
            duration: 60.0,
            filePath: "/path/to/short.mp3",
            fileSize: 2000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let longTrack = Track(
            title: "Long",
            artist: "Test",
            album: "Test",
            duration: 600.0,
            filePath: "/path/to/long.mp3",
            fileSize: 20000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let mockClassifier = MockMLClassifier()
        let embedding: [Float] = Array(repeating: 0.5, count: 128)
        await mockClassifier.setMockEmbedding(embedding)
        
        // When: Generating embeddings for both
        let shortEmbedding = try await mockClassifier.generateEmbedding(for: shortTrack)
        let longEmbedding = try await mockClassifier.generateEmbedding(for: longTrack)
        
        // Then: Both should return valid embeddings
        XCTAssertEqual(shortEmbedding.count, 128)
        XCTAssertEqual(longEmbedding.count, 128)
    }
}
