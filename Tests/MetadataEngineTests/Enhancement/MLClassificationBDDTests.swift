//
//  MLClassificationBDDTests.swift
//  MetadataEngineTests
//
//  BDD tests for ML classification features (Feature 5.2)
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// BDD tests for ML classification functionality
/// Following user-centric scenarios
final class MLClassificationBDDTests: XCTestCase {
    
    // MARK: - User Scenario: Genre Classification
    
    /// BDD: As a user, I want unknown tracks to be automatically classified by genre
    func testUserWantsUnknownTracksClassifiedByGenre() async throws {
        // Given: A track with unknown genre
        let track = Track(
            title: "Unknown Track",
            artist: "Unknown Artist",
            album: "Unknown Album",
            duration: 180.0,
            filePath: "/path/to/unknown.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100,
            genre: nil
        )
        let mockClassifier = MockMLClassifier()
        await mockClassifier.setMockGenreClassification(GenreClassification(
            genre: "Rock",
            confidence: 0.85,
            allProbabilities: ["Rock": 0.85, "Jazz": 0.10, "Classical": 0.05]
        ))
        
        // When: Classifying the track
        let result = try await mockClassifier.classifyGenre(for: track)
        
        // Then: Track should be classified with a genre
        XCTAssertNotNil(result.genre)
        XCTAssertFalse(result.genre.isEmpty, "Genre should not be empty")
        XCTAssertGreaterThan(result.confidence, 0.0, "Should have confidence score")
    }
    
    /// BDD: As a user, I want to see the confidence level of genre classifications
    func testUserWantsToSeeGenreClassificationConfidence() async throws {
        // Given: A track being classified
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
            genre: "Jazz",
            confidence: 0.92,
            allProbabilities: ["Jazz": 0.92, "Blues": 0.05, "Rock": 0.03]
        ))
        
        // When: Classifying the track
        let result = try await mockClassifier.classifyGenre(for: track)
        
        // Then: Should see confidence level and all probabilities
        XCTAssertEqual(result.genre, "Jazz")
        XCTAssertEqual(result.confidence, 0.92, accuracy: 0.01)
        let jazzProbability = result.allProbabilities["Jazz"]
        XCTAssertNotNil(jazzProbability, "Jazz probability should exist")
        XCTAssertEqual(jazzProbability ?? 0.0, 0.92, accuracy: 0.01)
        XCTAssertEqual(result.allProbabilities.count, 3, "Should show all genre probabilities")
    }
    
    // MARK: - User Scenario: Mood Detection
    
    /// BDD: As a user, I want tracks to be classified by mood for playlist creation
    func testUserWantsTracksClassifiedByMood() async throws {
        // Given: A track
        let track = Track(
            title: "Energetic Track",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/path/to/energetic.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let mockClassifier = MockMLClassifier()
        await mockClassifier.setMockMoodClassification(MoodClassification(
            mood: "Energetic",
            confidence: 0.88,
            allProbabilities: ["Energetic": 0.88, "Happy": 0.08, "Calm": 0.04]
        ))
        
        // When: Classifying the mood
        let result = try await mockClassifier.classifyMood(for: track)
        
        // Then: Track should be classified with a mood
        XCTAssertEqual(result.mood, "Energetic")
        XCTAssertGreaterThan(result.confidence, 0.0)
    }
    
    // MARK: - User Scenario: Batch Classification
    
    /// BDD: As a user, I want multiple tracks to be classified efficiently
    func testUserWantsMultipleTracksClassifiedEfficiently() async throws {
        // Given: Multiple tracks
        let tracks = (0..<10).map { index in
            Track(
                title: "Track \(index)",
                artist: "Artist",
                album: "Album",
                duration: 180.0,
                filePath: "/path/to/track\(index).mp3",
                fileSize: 5000000,
                bitrate: 320,
                sampleRate: 44100
            )
        }
        let mockClassifier = MockMLClassifier()
        await mockClassifier.setMockGenreClassification(GenreClassification(
            genre: "Rock",
            confidence: 0.85,
            allProbabilities: ["Rock": 0.85, "Jazz": 0.10, "Classical": 0.05]
        ))
        
        // When: Classifying all tracks
        let startTime = CFAbsoluteTimeGetCurrent()
        var results: [GenreClassification] = []
        for track in tracks {
            let result = try await mockClassifier.classifyGenre(for: track)
            results.append(result)
        }
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then: All tracks should be classified efficiently
        XCTAssertEqual(results.count, tracks.count)
        XCTAssertLessThan(elapsed, 5.0, "Batch classification should complete within 5 seconds")
    }
}
