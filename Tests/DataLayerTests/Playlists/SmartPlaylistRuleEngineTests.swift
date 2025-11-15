//
//  SmartPlaylistRuleEngineTests.swift
//  DataLayerTests
//
//  TDD tests for SmartPlaylistRuleEngine following Right-BICEP principles
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@testable import DataLayer
@testable import Shared
import XCTest

/// TDD tests for SmartPlaylistRuleEngine
/// Following Right-BICEP principles:
/// - [Right]: Verify rule evaluation produces correct results
/// - [B]oundary: Empty rules, complex nested rules, edge values
/// - [I]nverse: Match rule → Non-match rule → Verify opposite results
/// - [C]ross-check: Compare rule results with manual filtering
/// - [E]rror: Invalid rules, missing fields, null values
/// - [P]erformance: Rule evaluation < 50ms for large track sets
final class SmartPlaylistRuleEngineTests: XCTestCase {
    
    var ruleEngine: SmartPlaylistRuleEngine!
    
    override func setUp() {
        super.setUp()
        ruleEngine = SmartPlaylistRuleEngine()
    }
    
    override func tearDown() {
        ruleEngine = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// Helper to create a track for testing
    private func createTrack(
        title: String = "Test Track",
        artist: String = "Test Artist",
        album: String = "Test Album",
        duration: TimeInterval = 180.0,
        filePath: String = "/path/to/track.mp3",
        fileSize: Int64 = 5_000_000,
        bitrate: Int = 320,
        sampleRate: Int = 44100,
        year: Int? = nil,
        genre: String? = nil,
        rating: Int? = nil
    ) -> Track {
        Track(
            id: UUID(),
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            filePath: filePath,
            fileSize: fileSize,
            bitrate: bitrate,
            sampleRate: sampleRate,
            year: year,
            trackNumber: nil,
            discNumber: nil,
            genre: genre,
            rating: rating
        )
    }
    
    // MARK: - [Right] Tests - Verify Correct Results
    
    /// Test evaluating equals operator for title
    func testEvaluateEqualsTitle() {
        // Given
        let track = createTrack(title: "Test Song", artist: "Test Artist")
        let rules = SmartPlaylistRules(rules: [
            SmartPlaylistRule(field: .title, operator: .equals, value: "Test Song")
        ])
        
        // When
        let result = ruleEngine.evaluate(rules: rules, against: track)
        
        // Then
        XCTAssertTrue(result, "Track should match title equals rule")
    }
    
    /// Test evaluating contains operator for artist
    func testEvaluateContainsArtist() {
        // Given
        let track = createTrack(title: "Song", artist: "The Beatles")
        let rules = SmartPlaylistRules(rules: [
            SmartPlaylistRule(field: .artist, operator: .contains, value: "Beatles")
        ])
        
        // When
        let result = ruleEngine.evaluate(rules: rules, against: track)
        
        // Then
        XCTAssertTrue(result, "Track should match artist contains rule")
    }
    
    /// Test evaluating contains operator for title with "Loving You" and "Love"
    func testEvaluateContainsTitleLovingYou() {
        // Given - "Loving You" should contain "Love" (as "loving" contains "love")
        let track = createTrack(title: "Loving You")
        let rules = SmartPlaylistRules(rules: [
            SmartPlaylistRule(field: .title, operator: .contains, value: "Love")
        ])
        
        // When
        let result = ruleEngine.evaluate(rules: rules, against: track)
        
        // Then
        XCTAssertTrue(result, "'Loving You' should match 'Love' because 'loving' contains 'love'")
    }
    
    /// Test evaluating startsWith operator
    func testEvaluateStartsWith() {
        // Given
        let track = createTrack(title: "Amazing Song", artist: "Artist")
        let rules = SmartPlaylistRules(rules: [
            SmartPlaylistRule(field: .title, operator: .startsWith, value: "Amazing")
        ])
        
        // When
        let result = ruleEngine.evaluate(rules: rules, against: track)
        
        // Then
        XCTAssertTrue(result, "Track should match startsWith rule")
    }
    
    /// Test evaluating endsWith operator
    func testEvaluateEndsWith() {
        // Given
        let track = createTrack(title: "Great Song", artist: "Artist")
        let rules = SmartPlaylistRules(rules: [
            SmartPlaylistRule(field: .title, operator: .endsWith, value: "Song")
        ])
        
        // When
        let result = ruleEngine.evaluate(rules: rules, against: track)
        
        // Then
        XCTAssertTrue(result, "Track should match endsWith rule")
    }
    
    /// Test evaluating greaterThan operator for year
    func testEvaluateGreaterThanYear() {
        // Given
        let track = createTrack(title: "Song", year: 2020)
        let rules = SmartPlaylistRules(rules: [
            SmartPlaylistRule(field: .year, operator: .greaterThan, value: "2019")
        ])
        
        // When
        let result = ruleEngine.evaluate(rules: rules, against: track)
        
        // Then
        XCTAssertTrue(result, "Track should match year greaterThan rule")
    }
    
    /// Test evaluating AND logical operator
    func testEvaluateAndOperator() {
        // Given
        let track = createTrack(title: "Test Song", artist: "Test Artist", year: 2020)
        let rules = SmartPlaylistRules(rules: [
            SmartPlaylistRule(field: .title, operator: .contains, value: "Song", logicalOperator: .and),
            SmartPlaylistRule(field: .year, operator: .greaterThan, value: "2019")
        ])
        
        // When
        let result = ruleEngine.evaluate(rules: rules, against: track)
        
        // Then
        XCTAssertTrue(result, "Track should match AND rule combination")
    }
    
    /// Test evaluating OR logical operator
    func testEvaluateOrOperator() {
        // Given
        let track = createTrack(title: "Song A", artist: "Artist B")
        let rules = SmartPlaylistRules(rules: [
            SmartPlaylistRule(field: .title, operator: .equals, value: "Song B", logicalOperator: .or),
            SmartPlaylistRule(field: .artist, operator: .equals, value: "Artist B")
        ])
        
        // When
        let result = ruleEngine.evaluate(rules: rules, against: track)
        
        // Then
        XCTAssertTrue(result, "Track should match OR rule combination")
    }
    
    /// Test filtering tracks with rules
    func testFilterTracks() {
        // Given
        let tracks = [
            createTrack(title: "Song 1", artist: "Artist A"),
            createTrack(title: "Song 2", artist: "Artist B"),
            createTrack(title: "Song 3", artist: "Artist A")
        ]
        let rules = SmartPlaylistRules(rules: [
            SmartPlaylistRule(field: .artist, operator: .equals, value: "Artist A")
        ])
        
        // When
        let filtered = ruleEngine.filter(tracks: tracks, matching: rules)
        
        // Then
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { $0.artist == "Artist A" })
    }
    
    // MARK: - [B]oundary Tests
    
    /// Test evaluating with empty rules
    func testEvaluateEmptyRules() {
        // Given
        let track = createTrack(title: "Song")
        let rules = SmartPlaylistRules(rules: [])
        
        // When
        let result = ruleEngine.evaluate(rules: rules, against: track)
        
        // Then
        XCTAssertFalse(result, "Empty rules should not match any track")
    }
    
    /// Test evaluating with very long field value
    func testEvaluateVeryLongFieldValue() {
        // Given
        let longTitle = String(repeating: "A", count: 10000)
        let track = createTrack(title: longTitle)
        let rules = SmartPlaylistRules(rules: [
            SmartPlaylistRule(field: .title, operator: .contains, value: "A")
        ])
        
        // When
        let result = ruleEngine.evaluate(rules: rules, against: track)
        
        // Then
        XCTAssertTrue(result, "Should handle very long field values")
    }
    
    /// Test evaluating with empty field value
    func testEvaluateEmptyFieldValue() {
        // Given
        let track = createTrack(title: "", artist: "Artist")
        let rules = SmartPlaylistRules(rules: [
            SmartPlaylistRule(field: .title, operator: .equals, value: "")
        ])
        
        // When
        let result = ruleEngine.evaluate(rules: rules, against: track)
        
        // Then
        XCTAssertTrue(result, "Empty field value should match empty rule value")
    }
    
    /// Test evaluating with nil optional field (genre)
    func testEvaluateNilOptionalField() {
        // Given
        let track = createTrack(title: "Song", genre: nil)
        let rules = SmartPlaylistRules(rules: [
            SmartPlaylistRule(field: .genre, operator: .equals, value: "")
        ])
        
        // When
        let result = ruleEngine.evaluate(rules: rules, against: track)
        
        // Then
        XCTAssertTrue(result, "Nil optional field should be treated as empty string")
    }
    
    /// Test evaluating complex nested rules
    func testEvaluateComplexNestedRules() {
        // Given
        let track = createTrack(
            title: "Great Song",
            artist: "Amazing Artist",
            year: 2020,
            genre: "Rock"
        )
        let rules = SmartPlaylistRules(rules: [
            SmartPlaylistRule(field: .year, operator: .greaterThanOrEqual, value: "2020", logicalOperator: .and),
            SmartPlaylistRule(field: .genre, operator: .equals, value: "Rock", logicalOperator: .and),
            SmartPlaylistRule(field: .title, operator: .contains, value: "Song")
        ])
        
        // When
        let result = ruleEngine.evaluate(rules: rules, against: track)
        
        // Then
        XCTAssertTrue(result, "Track should match complex nested AND rules")
    }
    
    // MARK: - [I]nverse Tests
    
    /// Test inverse: Match rule vs non-match rule
    func testInverseMatchVsNonMatch() {
        // Given
        let track = createTrack(title: "Song A", artist: "Artist A")
        let matchRules = SmartPlaylistRules(rules: [
            SmartPlaylistRule(field: .title, operator: .equals, value: "Song A")
        ])
        let nonMatchRules = SmartPlaylistRules(rules: [
            SmartPlaylistRule(field: .title, operator: .equals, value: "Song B")
        ])
        
        // When
        let matchResult = ruleEngine.evaluate(rules: matchRules, against: track)
        let nonMatchResult = ruleEngine.evaluate(rules: nonMatchRules, against: track)
        
        // Then
        XCTAssertTrue(matchResult, "Track should match correct rule")
        XCTAssertFalse(nonMatchResult, "Track should not match incorrect rule")
        XCTAssertNotEqual(matchResult, nonMatchResult, "Results should be inverse")
    }
    
    // MARK: - [C]ross-Check Tests
    
    /// Test cross-check: Manual filtering vs rule engine filtering
    func testCrossCheckManualFiltering() {
        // Given
        let tracks = [
            createTrack(title: "Song 1", year: 2020),
            createTrack(title: "Song 2", year: 2019),
            createTrack(title: "Song 3", year: 2021)
        ]
        let rules = SmartPlaylistRules(rules: [
            SmartPlaylistRule(field: .year, operator: .greaterThan, value: "2019")
        ])
        
        // When - Rule engine filtering
        let ruleEngineFiltered = ruleEngine.filter(tracks: tracks, matching: rules)
        
        // Then - Manual filtering
        let manualFiltered = tracks.filter { track in
            guard let year = track.year else { return false }
            return year > 2019
        }
        
        XCTAssertEqual(ruleEngineFiltered.count, manualFiltered.count)
        XCTAssertEqual(Set(ruleEngineFiltered.map { $0.id }), Set(manualFiltered.map { $0.id }))
    }
    
    // MARK: - [E]rror Tests
    
    /// Test evaluating with invalid rules (empty rules)
    func testEvaluateInvalidRules() {
        // Given
        let track = createTrack(title: "Song")
        let invalidRules = SmartPlaylistRules(rules: [])
        
        // When
        let result = ruleEngine.evaluate(rules: invalidRules, against: track)
        
        // Then
        XCTAssertFalse(result, "Invalid rules should not match")
    }
    
    /// Test evaluating with missing field (nil year)
    func testEvaluateMissingField() {
        // Given
        let track = createTrack(title: "Song", year: nil)
        let rules = SmartPlaylistRules(rules: [
            SmartPlaylistRule(field: .year, operator: .greaterThan, value: "2020")
        ])
        
        // When
        let result = ruleEngine.evaluate(rules: rules, against: track)
        
        // Then
        XCTAssertFalse(result, "Missing field should not match numeric comparison")
    }
    
    // MARK: - [P]erformance Tests
    
    /// Test performance: Rule evaluation for many tracks
    func testPerformanceRuleEvaluation() {
        // Given
        let trackCount = 10000
        var tracks: [Track] = []
        for i in 0..<trackCount {
            tracks.append(createTrack(title: "Song \(i)", artist: "Artist \(i % 100)"))
        }
        let rules = SmartPlaylistRules(rules: [
            SmartPlaylistRule(field: .artist, operator: .contains, value: "Artist 50")
        ])
        
        // When
        let startTime = Date()
        let filtered = ruleEngine.filter(tracks: tracks, matching: rules)
        let duration = Date().timeIntervalSince(startTime)
        
        // Then
        XCTAssertLessThan(duration, 0.05, "Filtering 10000 tracks should take less than 50ms")
        XCTAssertGreaterThan(filtered.count, 0, "Should find matching tracks")
    }
    
    /// Test performance: Complex rule evaluation
    func testPerformanceComplexRuleEvaluation() {
        // Given
        let track = createTrack(
            title: "Test Song",
            artist: "Test Artist",
            year: 2020,
            genre: "Rock"
        )
        // Create complex rules with many conditions
        var rulesArray: [SmartPlaylistRule] = []
        for i in 0..<100 {
            rulesArray.append(
                SmartPlaylistRule(
                    field: .title,
                    operator: .contains,
                    value: "Song",
                    logicalOperator: i < 99 ? .and : nil
                )
            )
        }
        let rules = SmartPlaylistRules(rules: rulesArray)
        
        // When
        let startTime = Date()
        let result = ruleEngine.evaluate(rules: rules, against: track)
        let duration = Date().timeIntervalSince(startTime)
        
        // Then
        XCTAssertTrue(result, "Complex rules should still match")
        XCTAssertLessThan(duration, 0.05, "Complex rule evaluation should take less than 50ms")
    }
}
