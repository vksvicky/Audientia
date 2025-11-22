//
//  MLClassificationTests.swift
//  MetadataEngineTests
//
//  TDD tests for ML classification features (Feature 5.2)
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// TDD tests for ML classification functionality
/// Following Right-BICEP principles
final class MLClassificationTests: XCTestCase {
    
    // MARK: - Right: Are the results right?
    
    func testClassifyGenreReturnsValidGenre() async throws {
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
        await mockClassifier.setMockGenreClassification(GenreClassification(
            genre: "Rock",
            confidence: 0.85,
            allProbabilities: ["Rock": 0.85, "Jazz": 0.10, "Classical": 0.05]
        ))
        
        // When: Classifying the track
        let result = try await mockClassifier.classifyGenre(for: track)
        
        // Then: Should return valid genre classification
        XCTAssertEqual(result.genre, "Rock")
        XCTAssertGreaterThan(result.confidence, 0.0)
        XCTAssertLessThanOrEqual(result.confidence, 1.0)
    }
    
    func testClassifyMoodReturnsValidMood() async throws {
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
        await mockClassifier.setMockMoodClassification(MoodClassification(
            mood: "Energetic",
            confidence: 0.75,
            allProbabilities: ["Energetic": 0.75, "Calm": 0.15, "Happy": 0.10]
        ))
        
        // When: Classifying the mood
        let result = try await mockClassifier.classifyMood(for: track)
        
        // Then: Should return valid mood classification
        XCTAssertEqual(result.mood, "Energetic")
        XCTAssertGreaterThan(result.confidence, 0.0)
        XCTAssertLessThanOrEqual(result.confidence, 1.0)
    }
    
    // MARK: - Boundary Conditions
    
    func testClassifyGenreWithVeryShortTrack() async throws {
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
        
        // When: Attempting to classify
        // Then: Should throw error
        do {
            _ = try await mockClassifier.classifyGenre(for: track)
            XCTFail("Should have thrown error for very short track")
        } catch MLClassificationError.insufficientAudioData {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testClassifyGenreWithInstrumentalTrack() async throws {
        // Given: An instrumental track (no vocals)
        let track = Track(
            title: "Instrumental",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/path/to/instrumental.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let mockClassifier = MockMLClassifier()
        await mockClassifier.setMockGenreClassification(GenreClassification(
            genre: "Classical",
            confidence: 0.60,
            allProbabilities: ["Classical": 0.60, "Jazz": 0.30, "Electronic": 0.10]
        ))
        
        // When: Classifying
        let result = try await mockClassifier.classifyGenre(for: track)
        
        // Then: Should still return valid classification
        XCTAssertNotNil(result.genre)
        XCTAssertGreaterThan(result.confidence, 0.0)
    }
    
    // MARK: - Inverse Relationships
    
    func testClassifyThenReclassifyReturnsConsistentResults() async throws {
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
        await mockClassifier.setMockGenreClassification(GenreClassification(
            genre: "Rock",
            confidence: 0.85,
            allProbabilities: ["Rock": 0.85, "Jazz": 0.10, "Classical": 0.05]
        ))
        
        // When: Classifying twice
        let result1 = try await mockClassifier.classifyGenre(for: track)
        let result2 = try await mockClassifier.classifyGenre(for: track)
        
        // Then: Results should be consistent
        XCTAssertEqual(result1.genre, result2.genre)
        XCTAssertEqual(result1.confidence, result2.confidence, accuracy: 0.01)
    }
    
    // MARK: - Error Conditions
    
    func testClassifyGenreWithInvalidModel() async throws {
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
        
        // When: Attempting to classify
        // Then: Should throw error
        do {
            _ = try await mockClassifier.classifyGenre(for: track)
            XCTFail("Should have thrown error for invalid model")
        } catch MLClassificationError.modelNotAvailable {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testClassifyGenreWithCorruptedAudioFile() async throws {
        // Given: A corrupted audio file
        let track = Track(
            title: "Corrupted Track",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/path/to/corrupted.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let mockClassifier = MockMLClassifier()
        await mockClassifier.setShouldFail(true, error: MLClassificationError.audioProcessingFailed)
        
        // When: Attempting to classify
        // Then: Should throw error
        do {
            _ = try await mockClassifier.classifyGenre(for: track)
            XCTFail("Should have thrown error for corrupted file")
        } catch MLClassificationError.audioProcessingFailed {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Performance
    
    func testClassifyGenrePerformance() async throws {
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
        await mockClassifier.setMockGenreClassification(GenreClassification(
            genre: "Rock",
            confidence: 0.85,
            allProbabilities: ["Rock": 0.85, "Jazz": 0.10, "Classical": 0.05]
        ))
        
        // When: Classifying
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = try await mockClassifier.classifyGenre(for: track)
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then: Should complete within SLA (< 500ms)
        XCTAssertLessThan(elapsed, 0.5, "Classification should complete within 500ms")
    }
    
    // MARK: - Edge Cases
    
    func testClassifyGenreWithMixedGenres() async throws {
        // Given: A track with mixed genre characteristics
        let track = Track(
            title: "Mixed Genre Track",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/path/to/mixed.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let mockClassifier = MockMLClassifier()
        await mockClassifier.setMockGenreClassification(GenreClassification(
            genre: "Rock",
            confidence: 0.45, // Lower confidence for mixed genres
            allProbabilities: ["Rock": 0.45, "Jazz": 0.35, "Electronic": 0.20]
        ))
        
        // When: Classifying
        let result = try await mockClassifier.classifyGenre(for: track)
        
        // Then: Should return classification with lower confidence
        XCTAssertNotNil(result.genre)
        XCTAssertLessThan(result.confidence, 0.5, "Mixed genres should have lower confidence")
    }
    
    func testClassifyGenreWithExperimentalMusic() async throws {
        // Given: An experimental track
        let track = Track(
            title: "Experimental",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/path/to/experimental.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let mockClassifier = MockMLClassifier()
        await mockClassifier.setMockGenreClassification(GenreClassification(
            genre: "Electronic",
            confidence: 0.30, // Very low confidence for experimental
            allProbabilities: ["Electronic": 0.30, "Jazz": 0.25, "Classical": 0.20, "Rock": 0.15, "Other": 0.10]
        ))
        
        // When: Classifying
        let result = try await mockClassifier.classifyGenre(for: track)
        
        // Then: Should still return a classification
        XCTAssertNotNil(result.genre)
        XCTAssertGreaterThan(result.confidence, 0.0)
    }
}
