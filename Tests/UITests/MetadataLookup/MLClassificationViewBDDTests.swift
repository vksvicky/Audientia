//
//  MLClassificationViewBDDTests.swift
//  UITests
//
//  BDD tests for MLClassificationView (Feature 5.2)
//

@testable import MetadataEngine
@testable import Shared
import SwiftUI
import XCTest

/// BDD tests for MLClassificationView
/// Following user-centric scenarios
@MainActor
final class MLClassificationViewBDDTests: XCTestCase {
    
    var viewModel: MLClassificationViewModel!
    var mockClassifier: MockMLClassifier!
    var track: Track!
    
    override func setUp() async throws {
        try await super.setUp()
        mockClassifier = MockMLClassifier()
        viewModel = MLClassificationViewModel(classifier: mockClassifier)
        track = Track(
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
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockClassifier = nil
        track = nil
        try await super.tearDown()
    }
    
    // MARK: - User Scenario: Viewing ML Classification
    
    /// BDD: As a user, I want to see the genre classification for a track
    func testUserWantsToSeeGenreClassification() async throws {
        // Given: A track and classifier ready
        await mockClassifier.setMockGenreClassification(GenreClassification(
            genre: "Rock",
            confidence: 0.85,
            allProbabilities: ["Rock": 0.85, "Jazz": 0.10, "Classical": 0.05]
        ))
        
        // When: User classifies the track
        await viewModel.classifyGenre(for: track)
        
        // Then: User should see the genre classification
        XCTAssertNotNil(viewModel.genreClassification)
        XCTAssertEqual(viewModel.genreClassification?.genre, "Rock")
        XCTAssertGreaterThan(viewModel.genreClassification?.confidence ?? 0, 0.0)
    }
    
    /// BDD: As a user, I want to see the confidence level of classifications
    func testUserWantsToSeeClassificationConfidence() async throws {
        // Given: A track with classification
        await mockClassifier.setMockGenreClassification(GenreClassification(
            genre: "Jazz",
            confidence: 0.92,
            allProbabilities: ["Jazz": 0.92, "Blues": 0.05, "Rock": 0.03]
        ))
        await viewModel.classifyGenre(for: track)
        
        // When: User views the classification
        // Then: User should see confidence level
        let confidence = viewModel.genreClassification?.confidence
        XCTAssertNotNil(confidence, "Confidence should exist")
        XCTAssertEqual(confidence ?? 0.0, 0.92, accuracy: 0.01)
        XCTAssertNotNil(viewModel.genreClassification?.allProbabilities)
    }
    
    /// BDD: As a user, I want to classify both genre and mood at once
    func testUserWantsToClassifyGenreAndMood() async throws {
        // Given: A track
        await mockClassifier.setMockGenreClassification(GenreClassification(
            genre: "Rock",
            confidence: 0.85,
            allProbabilities: ["Rock": 0.85, "Jazz": 0.10, "Classical": 0.05]
        ))
        await mockClassifier.setMockMoodClassification(MoodClassification(
            mood: "Energetic",
            confidence: 0.75,
            allProbabilities: ["Energetic": 0.75, "Calm": 0.15, "Happy": 0.10]
        ))
        
        // When: User classifies all
        await viewModel.classifyAll(for: track)
        
        // Then: User should see both genre and mood
        XCTAssertNotNil(viewModel.genreClassification)
        XCTAssertNotNil(viewModel.moodClassification)
        XCTAssertEqual(viewModel.genreClassification?.genre, "Rock")
        XCTAssertEqual(viewModel.moodClassification?.mood, "Energetic")
    }
}
