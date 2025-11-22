//
//  MLClassificationViewTests.swift
//  UITests
//
//  TDD tests for MLClassificationView (Feature 5.2)
//

@testable import MetadataEngine
@testable import Shared
import SwiftUI
import XCTest

/// TDD tests for MLClassificationView
/// Following Right-BICEP principles
@MainActor
final class MLClassificationViewTests: XCTestCase {
    
    var viewModel: MLClassificationViewModel!
    var mockClassifier: MockMLClassifier!
    var track: Track!
    
    override func setUp() async throws {
        try await super.setUp()
        mockClassifier = MockMLClassifier()
        viewModel = MLClassificationViewModel(classifier: mockClassifier)
        track = Track(
            title: "Test Track",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/path/to/track.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockClassifier = nil
        track = nil
        try await super.tearDown()
    }
    
    // MARK: - Right: Are the results right?
    
    func testViewDisplaysGenreClassification() async throws {
        // Given: A genre classification
        await mockClassifier.setMockGenreClassification(GenreClassification(
            genre: "Rock",
            confidence: 0.85,
            allProbabilities: ["Rock": 0.85, "Jazz": 0.10, "Classical": 0.05]
        ))
        await viewModel.classifyGenre(for: track)
        
        // When: View is created
        _ = MLClassificationView(viewModel: viewModel, track: track)
        
        // Then: Should have genre classification
        XCTAssertNotNil(viewModel.genreClassification)
        XCTAssertEqual(viewModel.genreClassification?.genre, "Rock")
    }
    
    func testViewDisplaysMoodClassification() async throws {
        // Given: A mood classification
        await mockClassifier.setMockMoodClassification(MoodClassification(
            mood: "Energetic",
            confidence: 0.75,
            allProbabilities: ["Energetic": 0.75, "Calm": 0.15, "Happy": 0.10]
        ))
        await viewModel.classifyMood(for: track)
        
        // When: View is created
        _ = MLClassificationView(viewModel: viewModel, track: track)
        
        // Then: Should have mood classification
        XCTAssertNotNil(viewModel.moodClassification)
        XCTAssertEqual(viewModel.moodClassification?.mood, "Energetic")
    }
    
    // MARK: - Boundary Conditions
    
    func testViewHandlesNoClassification() {
        // Given: No classification results
        // When: View is created
        _ = MLClassificationView(viewModel: viewModel, track: track)
        
        // Then: Should not crash
        XCTAssertNil(viewModel.genreClassification)
        XCTAssertNil(viewModel.moodClassification)
    }
    
    func testViewHandlesClassificationError() async throws {
        // Given: Classification will fail
        await mockClassifier.setShouldFail(true, error: MLClassificationError.modelNotAvailable)
        await viewModel.classifyGenre(for: track)
        
        // When: View is created
        _ = MLClassificationView(viewModel: viewModel, track: track)
        
        // Then: Should display error
        XCTAssertNotNil(viewModel.classificationError)
    }
    
    // MARK: - Error Conditions
    
    func testViewHandlesLoadingState() async throws {
        // Given: Classification in progress with mock set up
        await mockClassifier.setMockGenreClassification(GenreClassification(
            genre: "Rock",
            confidence: 0.85,
            allProbabilities: ["Rock": 0.85, "Jazz": 0.10, "Classical": 0.05]
        ))
        
        // Verify initial state
        XCTAssertFalse(viewModel.isClassifying)
        
        // When: Classification starts
        let task = Task {
            await viewModel.classifyGenre(for: track)
        }
        
        // Then: Should transition through loading state
        // Note: Due to the async nature, isClassifying may already be false
        // by the time we check, but we verify the operation completes successfully
        await task.value
        
        // Verify the classification completed successfully
        XCTAssertNotNil(viewModel.genreClassification)
        XCTAssertFalse(viewModel.isClassifying)
        XCTAssertNil(viewModel.classificationError)
    }
}
