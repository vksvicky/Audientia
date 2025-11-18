//
//  MetadataMergeBDDTests.swift
//  MetadataEngineTests
//
//  BDD tests for metadata merge strategies
//

import Foundation
import XCTest

@testable import MetadataEngine
@testable import Shared

/// BDD tests for metadata merge strategies following user-centric scenarios
final class MetadataMergeBDDTests: XCTestCase {
    
    // MARK: - BDD Scenarios
    
    func testUserWantsToFillMissingMetadataFromMultipleSources() async throws {
        // Scenario: As a user, I want to fill missing metadata from multiple sources
        
        // Given: I have a track with incomplete metadata
        let originalTrack = Track(
            title: "Unknown",
            artist: "Unknown Artist",
            album: "Unknown Album",
            duration: 180.0,
            filePath: "/test.mp3",
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100,
            year: nil,
            trackNumber: nil,
            genre: nil
        )
        
        // And: I have metadata from AcoustID and MusicBrainz
        let acoustIDSource = MetadataSource(
            type: .acoustID,
            confidence: 0.98,
            metadata: MetadataFields(
                title: "Bohemian Rhapsody",
                artist: "Queen",
                album: "A Night at the Opera"
            )
        )
        
        let musicBrainzSource = MetadataSource(
            type: .musicBrainz,
            confidence: 0.95,
            metadata: MetadataFields(
                year: 1975,
                trackNumber: 11,
                genre: "Rock"
            )
        )
        
        let merger = MetadataMerger(strategy: .fillMissing)
        
        // When: I merge the metadata
        let merged = try merger.merge(originalTrack: originalTrack, sources: [acoustIDSource, musicBrainzSource])
        
        // Then: Missing fields are filled from the sources
        XCTAssertEqual(merged.title, "Unknown") // Existing preserved
        XCTAssertEqual(merged.artist, "Unknown Artist") // Existing preserved
        XCTAssertEqual(merged.album, "Unknown Album") // Existing preserved
        XCTAssertEqual(merged.year, 1975) // Filled from MusicBrainz
        XCTAssertEqual(merged.trackNumber, 11) // Filled from MusicBrainz
        XCTAssertEqual(merged.genre, "Rock") // Filled from MusicBrainz
    }
    
    func testUserWantsToResolveConflictsUsingHighestConfidence() async throws {
        // Scenario: As a user, I want conflicts resolved using the highest confidence source
        
        // Given: I have a track and multiple sources with conflicting data
        let originalTrack = Track(
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180.0,
            filePath: "/test.mp3",
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100,
            year: 2020,
            genre: "Pop"
        )
        
        // And: MusicBrainz says the year is 1975 with high confidence
        let musicBrainzSource = MetadataSource(
            type: .musicBrainz,
            confidence: 0.95,
            metadata: MetadataFields(
                title: "Bohemian Rhapsody",
                artist: "Queen",
                year: 1975,
                genre: "Rock"
            )
        )
        
        // And: Discogs says the year is 1976 with lower confidence
        let discogsSource = MetadataSource(
            type: .discogs,
            confidence: 0.85,
            metadata: MetadataFields(
                title: "Bohemian Rhapsody",
                artist: "Queen",
                year: 1976,
                genre: "Progressive Rock"
            )
        )
        
        let merger = MetadataMerger(strategy: .highestConfidence)
        
        // When: I merge the metadata
        let merged = try merger.merge(originalTrack: originalTrack, sources: [musicBrainzSource, discogsSource])
        
        // Then: The highest confidence source wins for each field
        XCTAssertEqual(merged.title, "Bohemian Rhapsody")
        XCTAssertEqual(merged.artist, "Queen")
        XCTAssertEqual(merged.year, 1975) // From MusicBrainz (0.95 > 0.85)
        XCTAssertEqual(merged.genre, "Rock") // From MusicBrainz (0.95 > 0.85)
    }
    
    func testUserWantsToPreferMusicBrainzOverOtherSources() async throws {
        // Scenario: As a user, I want to prefer MusicBrainz over other sources
        
        // Given: I have a track and metadata from multiple sources
        let originalTrack = Track(
            title: "Test",
            artist: "Test",
            album: "Test",
            duration: 180.0,
            filePath: "/test.mp3",
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100
        )
        
        // And: MusicBrainz says the year is 1975
        let musicBrainzSource = MetadataSource(
            type: .musicBrainz,
            confidence: 0.95,
            metadata: MetadataFields(
                title: "Bohemian Rhapsody",
                artist: "Queen",
                year: 1975
            )
        )
        
        // And: Discogs says the year is 1976 (even with higher confidence)
        let discogsSource = MetadataSource(
            type: .discogs,
            confidence: 0.98,
            metadata: MetadataFields(
                title: "Bohemian Rhapsody",
                artist: "Queen",
                year: 1976
            )
        )
        
        let merger = MetadataMerger(strategy: .preferSource(.musicBrainz))
        
        // When: I merge preferring MusicBrainz
        let merged = try merger.merge(originalTrack: originalTrack, sources: [musicBrainzSource, discogsSource])
        
        // Then: MusicBrainz data is used even though Discogs has higher confidence
        XCTAssertEqual(merged.title, "Bohemian Rhapsody")
        XCTAssertEqual(merged.artist, "Queen")
        XCTAssertEqual(merged.year, 1975) // From MusicBrainz, not Discogs (1976)
    }
    
    func testUserWantsToUseMostCompleteSource() async throws {
        // Scenario: As a user, I want to use the most complete source
        
        // Given: I have a track and sources with different amounts of metadata
        let originalTrack = Track(
            title: "Test",
            artist: "Test",
            album: "Test",
            duration: 180.0,
            filePath: "/test.mp3",
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100
        )
        
        // And: AcoustID has only title and artist (2 fields)
        let acoustIDSource = MetadataSource(
            type: .acoustID,
            confidence: 0.98,
            metadata: MetadataFields(
                title: "Bohemian Rhapsody",
                artist: "Queen"
            )
        )
        
        // And: MusicBrainz has title, artist, album, year, trackNumber, genre (6 fields)
        let musicBrainzSource = MetadataSource(
            type: .musicBrainz,
            confidence: 0.95,
            metadata: MetadataFields(
                title: "Bohemian Rhapsody",
                artist: "Queen",
                album: "A Night at the Opera",
                year: 1975,
                trackNumber: 11,
                genre: "Rock"
            )
        )
        
        let merger = MetadataMerger(strategy: .mostComplete)
        
        // When: I merge using most complete strategy
        let merged = try merger.merge(originalTrack: originalTrack, sources: [acoustIDSource, musicBrainzSource])
        
        // Then: The most complete source (MusicBrainz) is used
        XCTAssertEqual(merged.title, "Bohemian Rhapsody")
        XCTAssertEqual(merged.artist, "Queen")
        XCTAssertEqual(merged.album, "A Night at the Opera")
        XCTAssertEqual(merged.year, 1975)
        XCTAssertEqual(merged.trackNumber, 11)
        XCTAssertEqual(merged.genre, "Rock")
    }
    
    func testUserWantsToPreserveExistingMetadata() async throws {
        // Scenario: As a user, I want to preserve my existing metadata when merging
        
        // Given: I have a track with existing metadata
        let originalTrack = Track(
            title: "My Custom Title",
            artist: "My Custom Artist",
            album: "My Custom Album",
            duration: 180.0,
            filePath: "/test.mp3",
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100,
            year: 2020,
            genre: "My Genre"
        )
        
        // And: I have metadata from MusicBrainz that conflicts
        let musicBrainzSource = MetadataSource(
            type: .musicBrainz,
            confidence: 0.95,
            metadata: MetadataFields(
                title: "Bohemian Rhapsody",
                artist: "Queen",
                album: "A Night at the Opera",
                year: 1975,
                genre: "Rock"
            )
        )
        
        let merger = MetadataMerger(strategy: .conservative)
        
        // When: I merge using conservative strategy
        let merged = try merger.merge(originalTrack: originalTrack, sources: [musicBrainzSource])
        
        // Then: My existing metadata is preserved
        XCTAssertEqual(merged.title, "My Custom Title")
        XCTAssertEqual(merged.artist, "My Custom Artist")
        XCTAssertEqual(merged.album, "My Custom Album")
        XCTAssertEqual(merged.year, 2020)
        XCTAssertEqual(merged.genre, "My Genre")
    }
    
    func testUserWantsToRevertMergedMetadata() async throws {
        // Scenario: As a user, I want to revert merged metadata back to original
        
        // Given: I have an original track
        let originalTrack = Track(
            title: "Original Title",
            artist: "Original Artist",
            album: "Original Album",
            duration: 180.0,
            filePath: "/test.mp3",
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100,
            year: 2020
        )
        
        // And: I merge metadata from a source
        let source = MetadataSource(
            type: .musicBrainz,
            confidence: 0.95,
            metadata: MetadataFields(
                title: "New Title",
                artist: "New Artist",
                year: 1975
            )
        )
        
        let merger = MetadataMerger(strategy: .fillMissing)
        let merged = try merger.merge(originalTrack: originalTrack, sources: [source])
        
        // When: I revert by merging with original track as source
        let originalSource = MetadataSource(
            type: .existing,
            confidence: 1.0,
            metadata: MetadataFields(
                title: originalTrack.title,
                artist: originalTrack.artist,
                album: originalTrack.album,
                year: originalTrack.year
            )
        )
        
        let reverted = try merger.merge(originalTrack: merged, sources: [originalSource])
        
        // Then: The metadata is reverted to original (inverse: reversible operation)
        XCTAssertEqual(reverted.title, originalTrack.title)
        XCTAssertEqual(reverted.artist, originalTrack.artist)
        XCTAssertEqual(reverted.album, originalTrack.album)
        XCTAssertEqual(reverted.year, originalTrack.year)
    }
    
    func testUserWantsToHandleEmptySources() async {
        // Scenario: As a user, I want to handle cases where no sources are available
        
        // Given: I have a track but no metadata sources
        let originalTrack = Track(
            title: "Test",
            artist: "Test",
            album: "Test",
            duration: 180.0,
            filePath: "/test.mp3",
            fileSize: 1024,
            bitrate: 320,
            sampleRate: 44100
        )
        
        let merger = MetadataMerger()
        
        // When: I try to merge with no sources
        // Then: I see a clear error message
        do {
            _ = try merger.merge(originalTrack: originalTrack, sources: [])
            XCTFail("Should have thrown an error")
        } catch let error as MetadataMergeError {
            XCTAssertEqual(error, .noSources)
            XCTAssertNotNil(error.errorDescription)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
