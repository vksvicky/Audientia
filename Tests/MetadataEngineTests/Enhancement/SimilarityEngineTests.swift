//
//  SimilarityEngineTests.swift
//  MetadataEngineTests
//
//  TDD tests for similarity calculation (Feature 5.2)
//

@testable import MetadataEngine
@testable import Shared
import XCTest

/// TDD tests for similarity calculation functionality
/// Following Right-BICEP principles
final class SimilarityEngineTests: XCTestCase {
    
    var similarityEngine: (any SimilarityEngineProtocol)?
    var mockClassifier: MockMLClassifier?
    
    override func setUp() async throws {
        try await super.setUp()
        mockClassifier = MockMLClassifier()
        // Will be initialised with mock implementation
    }
    
    override func tearDown() async throws {
        similarityEngine = nil
        mockClassifier = nil
        try await super.tearDown()
    }
    
    // MARK: - Right: Are the results right?
    
    func testCalculateSimilarityReturnsValidScore() async throws {
        // Given: Two tracks with embeddings
        let track1 = Track(
            title: "Track 1",
            artist: "Artist",
            album: "Album",
            duration: 180.0,
            filePath: "/path/to/track1.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let track2 = Track(
            title: "Track 2",
            artist: "Artist",
            album: "Album",
            duration: 180.0,
            filePath: "/path/to/track2.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let mockEngine = MockSimilarityEngine()
        await mockEngine.setMockSimilarity(0.85)
        
        // When: Calculating similarity
        let result = try await mockEngine.calculateSimilarity(track1: track1, track2: track2)
        
        // Then: Should return valid similarity score
        XCTAssertGreaterThanOrEqual(result, 0.0)
        XCTAssertLessThanOrEqual(result, 1.0)
        XCTAssertEqual(result, 0.85, accuracy: 0.01)
    }
    
    func testFindSimilarReturnsOrderedResults() async throws {
        // Given: A query track and candidate tracks
        let queryTrack = Track(
            title: "Query Track",
            artist: "Artist",
            album: "Album",
            duration: 180.0,
            filePath: "/path/to/query.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let candidate1 = Track(
            title: "Candidate 1",
            artist: "Artist",
            album: "Album",
            duration: 180.0,
            filePath: "/path/to/candidate1.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let candidate2 = Track(
            title: "Candidate 2",
            artist: "Artist",
            album: "Album",
            duration: 180.0,
            filePath: "/path/to/candidate2.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let mockEngine = MockSimilarityEngine()
        await mockEngine.setMockSimilarityResults([
            SimilarityResult(track: candidate1, similarity: 0.90),
            SimilarityResult(track: candidate2, similarity: 0.75)
        ])
        
        // When: Finding similar tracks
        let results = try await mockEngine.findSimilar(to: queryTrack, in: [candidate1, candidate2], limit: 10)
        
        // Then: Should return ordered results (highest similarity first)
        XCTAssertEqual(results.count, 2)
        XCTAssertGreaterThanOrEqual(results[0].similarity, results[1].similarity, "Results should be ordered by similarity")
        XCTAssertEqual(results[0].track.id, candidate1.id)
        XCTAssertEqual(results[1].track.id, candidate2.id)
    }
    
    // MARK: - Boundary Conditions
    
    func testFindSimilarWithEmptyTrackList() async throws {
        // Given: A query track and empty candidate list
        let queryTrack = Track(
            title: "Query Track",
            artist: "Artist",
            album: "Album",
            duration: 180.0,
            filePath: "/path/to/query.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let mockEngine = MockSimilarityEngine()
        await mockEngine.setMockSimilarityResults([])
        
        // When: Finding similar tracks
        let results = try await mockEngine.findSimilar(to: queryTrack, in: [], limit: 10)
        
        // Then: Should return empty list
        XCTAssertTrue(results.isEmpty, "Should return empty list for empty candidates")
    }
    
    func testFindSimilarRespectsLimit() async throws {
        // Given: A query track and many candidates
        let queryTrack = Track(
            title: "Query Track",
            artist: "Artist",
            album: "Album",
            duration: 180.0,
            filePath: "/path/to/query.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let candidates = (0..<20).map { index in
            Track(
                title: "Candidate \(index)",
                artist: "Artist",
                album: "Album",
                duration: 180.0,
                filePath: "/path/to/candidate\(index).mp3",
                fileSize: 5000000,
                bitrate: 320,
                sampleRate: 44100
            )
        }
        let mockEngine = MockSimilarityEngine()
        await mockEngine.setMockSimilarityResults(candidates.map { track in
            SimilarityResult(track: track, similarity: Double.random(in: 0.0...1.0))
        })
        
        // When: Finding similar tracks with limit
        let results = try await mockEngine.findSimilar(to: queryTrack, in: candidates, limit: 5)
        
        // Then: Should respect limit
        XCTAssertLessThanOrEqual(results.count, 5, "Should respect limit parameter")
    }
    
    // MARK: - Inverse Relationships
    
    func testSimilarityIsSymmetric() async throws {
        // Given: Two tracks
        let track1 = Track(
            title: "Track 1",
            artist: "Artist",
            album: "Album",
            duration: 180.0,
            filePath: "/path/to/track1.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let track2 = Track(
            title: "Track 2",
            artist: "Artist",
            album: "Album",
            duration: 180.0,
            filePath: "/path/to/track2.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let mockEngine = MockSimilarityEngine()
        await mockEngine.setMockSimilarity(0.85)
        
        // When: Calculating similarity both ways
        let similarity1 = try await mockEngine.calculateSimilarity(track1: track1, track2: track2)
        let similarity2 = try await mockEngine.calculateSimilarity(track1: track2, track2: track1)
        
        // Then: Should be symmetric (same result)
        XCTAssertEqual(similarity1, similarity2, accuracy: 0.01, "Similarity should be symmetric")
    }
    
    // MARK: - Cross-Check
    
    func testCosineSimilarityCalculation() {
        // Given: Two embeddings
        let embedding1: [Float] = [1.0, 0.0, 0.0]
        let embedding2: [Float] = [1.0, 0.0, 0.0]
        let mockEngine = MockSimilarityEngine()
        
        // When: Calculating cosine similarity (nonisolated method, no await needed)
        let similarity = mockEngine.cosineSimilarity(embedding1: embedding1, embedding2: embedding2)
        
        // Then: Should return 1.0 for identical vectors
        XCTAssertEqual(similarity, 1.0, accuracy: 0.01, "Identical vectors should have similarity 1.0")
    }
    
    func testCosineSimilarityWithOrthogonalVectors() {
        // Given: Two orthogonal embeddings
        let embedding1: [Float] = [1.0, 0.0, 0.0]
        let embedding2: [Float] = [0.0, 1.0, 0.0]
        let mockEngine = MockSimilarityEngine()
        
        // When: Calculating cosine similarity (nonisolated method, no await needed)
        let similarity = mockEngine.cosineSimilarity(embedding1: embedding1, embedding2: embedding2)
        
        // Then: Should return 0.0 for orthogonal vectors
        XCTAssertEqual(similarity, 0.0, accuracy: 0.01, "Orthogonal vectors should have similarity 0.0")
    }
    
    // MARK: - Error Conditions
    
    func testCalculateSimilarityWithMissingEmbedding() async throws {
        // Given: A track without embedding
        let track1 = Track(
            title: "Track 1",
            artist: "Artist",
            album: "Album",
            duration: 180.0,
            filePath: "/path/to/track1.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let track2 = Track(
            title: "Track 2",
            artist: "Artist",
            album: "Album",
            duration: 180.0,
            filePath: "/path/to/track2.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let mockEngine = MockSimilarityEngine()
        await mockEngine.setShouldFail(true, error: SimilarityError.noEmbedding(track1))
        
        // When: Attempting to calculate similarity
        // Then: Should throw error
        do {
            _ = try await mockEngine.calculateSimilarity(track1: track1, track2: track2)
            XCTFail("Should have thrown error for missing embedding")
        } catch SimilarityError.noEmbedding {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Performance
    
    func testFindSimilarPerformance() async throws {
        // Given: A query track and many candidates
        let queryTrack = Track(
            title: "Query Track",
            artist: "Artist",
            album: "Album",
            duration: 180.0,
            filePath: "/path/to/query.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let candidates = (0..<1000).map { index in
            Track(
                title: "Candidate \(index)",
                artist: "Artist",
                album: "Album",
                duration: 180.0,
                filePath: "/path/to/candidate\(index).mp3",
                fileSize: 5000000,
                bitrate: 320,
                sampleRate: 44100
            )
        }
        let mockEngine = MockSimilarityEngine()
        await mockEngine.setMockSimilarityResults(Array(candidates.prefix(10).map { track in
            SimilarityResult(track: track, similarity: 0.8)
        }))
        
        // When: Finding similar tracks
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = try await mockEngine.findSimilar(to: queryTrack, in: candidates, limit: 10)
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then: Should complete within SLA (< 200ms)
        XCTAssertLessThan(elapsed, 0.2, "Finding similar tracks should complete within 200ms")
    }
    
    // MARK: - Edge Cases
    
    func testFindSimilarWithIdenticalTracks() async throws {
        // Given: A track and itself in candidates
        let track = Track(
            title: "Track",
            artist: "Artist",
            album: "Album",
            duration: 180.0,
            filePath: "/path/to/track.mp3",
            fileSize: 5000000,
            bitrate: 320,
            sampleRate: 44100
        )
        let mockEngine = MockSimilarityEngine()
        await mockEngine.setMockSimilarityResults([
            SimilarityResult(track: track, similarity: 1.0)
        ])
        
        // When: Finding similar tracks
        let results = try await mockEngine.findSimilar(to: track, in: [track], limit: 10)
        
        // Then: Should return the track with similarity 1.0
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].similarity, 1.0, accuracy: 0.01, "Track should have similarity 1.0 with itself")
    }
}
