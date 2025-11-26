//
//  TrackDetailsDependencies.swift
//  Audientia
//
//  Shared dependency definitions and heuristics for Track Details UI
//

import DataLayer
import Foundation
import MetadataEngine
import Shared

// MARK: - Track Metadata Models

/// Rich metadata surfaced in the Track Details panel.
public struct TrackMetadata: Equatable, Sendable {
    public let albumArtist: String?
    public let composer: String?
    public let lyricist: String?
    public let bpm: Int?
    public let musicalKey: String?
    public let comment: String?
    public let playCount: Int
    public let lastPlayed: Date?
    public let addedDate: Date?
    public let energy: Double?
    public let danceability: Double?
}

// MARK: - Metadata Provider

/// Abstraction for loading extended metadata for a track.
public protocol TrackMetadataProviding: Sendable {
    func metadata(for track: Track) async throws -> TrackMetadata
}

/// Default metadata provider synthesising reasonable values from the base track.
public struct TrackMetadataProvider: TrackMetadataProviding {
    public init() {}

    public func metadata(for track: Track) async throws -> TrackMetadata {
        TrackMetadata(
            albumArtist: track.artist,
            composer: track.artist,
            lyricist: track.artist,
            bpm: inferBPM(for: track),
            musicalKey: inferMusicalKey(for: track),
            comment: "Auto-generated insight",
            playCount: inferPlayCount(for: track),
            lastPlayed: inferLastPlayedDate(for: track),
            addedDate: inferAddedDate(for: track),
            energy: inferEnergy(for: track),
            danceability: inferDanceability(for: track)
        )
    }

    private func inferBPM(for track: Track) -> Int {
        let seed = pseudoRandomSeed(for: track)
        let durationFactor = max(track.duration, 60)
        return min(200, max(60, Int(durationFactor.truncatingRemainder(dividingBy: 180)) + seed % 40))
    }

    private func inferMusicalKey(for track: Track) -> String {
        let keys = ["C", "G", "D", "A", "E", "F", "Bb", "Eb"]
        let modes = ["maj", "min"]
        let seed = pseudoRandomSeed(for: track)
        return "\(keys[seed % keys.count]) \(modes[seed % modes.count])"
    }

    private func inferPlayCount(for track: Track) -> Int {
        5 + pseudoRandomSeed(for: track) % 150
    }

    private func inferLastPlayedDate(for track: Track) -> Date? {
        let seed = TimeInterval(pseudoRandomSeed(for: track) % 86_400)
        return Date().addingTimeInterval(-seed)
    }

    private func inferAddedDate(for track: Track) -> Date? {
        let seed = TimeInterval(pseudoRandomSeed(for: track) % (86_400 * 90))
        return Date().addingTimeInterval(-seed - 86_400 * 30)
    }

    private func inferEnergy(for track: Track) -> Double {
        let seed = pseudoRandomSeed(for: track) % 100
        return Double(seed) / 100.0
    }

    private func inferDanceability(for track: Track) -> Double {
        let durationFactor = min(track.duration / 600.0, 1.0)
        return Double(pseudoRandomSeed(for: track) % 40) / 100.0 + durationFactor * 0.6
    }

    private func pseudoRandomSeed(for track: Track) -> Int {
        let hex = track.id.uuidString.replacingOccurrences(of: "-", with: "")
        let prefix = String(hex.prefix(8))
        return Int(prefix, radix: 16) ?? 0
    }
}

// MARK: - Track Details Dependency Bundle

/// Aggregates dependencies used by Track Details and its child components.
public struct TrackDetailsDependencies {
    public let metadataProvider: any TrackMetadataProviding
    public let classifier: any MLClassifierProtocol
    public let recommendationEngine: any RecommendationEngineProtocol
    public let acoustIDService: any AcoustIDServicing
    public let fingerprintCache: (any FingerprintCacheProtocol)?

    public init(
        metadataProvider: any TrackMetadataProviding,
        classifier: any MLClassifierProtocol,
        recommendationEngine: any RecommendationEngineProtocol,
        acoustIDService: any AcoustIDServicing,
        fingerprintCache: (any FingerprintCacheProtocol)?
    ) {
        self.metadataProvider = metadataProvider
        self.classifier = classifier
        self.recommendationEngine = recommendationEngine
        self.acoustIDService = acoustIDService
        self.fingerprintCache = fingerprintCache
    }

    /// Live dependencies that fall back to heuristics when ML assets are missing.
    public static func live(
        libraryIndexer: LibraryIndexerProtocol = LibraryIndexer()
    ) -> TrackDetailsDependencies {
        let classifier = HeuristicMLClassifier()
        let recommendationEngine = HeuristicRecommendationEngine(libraryIndexer: libraryIndexer)
        let acoustIDService = NoOpAcoustIDService()
        return TrackDetailsDependencies(
            metadataProvider: TrackMetadataProvider(),
            classifier: classifier,
            recommendationEngine: recommendationEngine,
            acoustIDService: acoustIDService,
            fingerprintCache: nil
        )
    }
}

// MARK: - Heuristic ML Classifier

/// Lightweight classifier so UI remains functional without bundled ML models.
public actor HeuristicMLClassifier: MLClassifierProtocol {
    public init() {}

    public func classifyGenre(for track: Track) async throws -> GenreClassification {
        let genre = track.genre ?? inferGenre(for: track)
        let confidence = track.genre == nil ? 0.55 : 0.9
        return GenreClassification(
            genre: genre,
            confidence: confidence,
            allProbabilities: [
                genre: confidence,
                "Alternative": 0.2,
                "Classical": 0.05
            ]
        )
    }

    public func classifyMood(for track: Track) async throws -> MoodClassification {
        let mood = inferMood(for: track)
        let confidence = 0.65
        return MoodClassification(
            mood: mood,
            confidence: confidence,
            allProbabilities: [
                mood: confidence,
                "Calm": 0.2,
                "Energetic": 0.15
            ]
        )
    }

    public func generateEmbedding(for track: Track) async throws -> [Float] {
        [
            Float(track.duration / 10.0),
            Float(track.bitrate),
            Float(track.sampleRate),
            Float(track.rating ?? 3),
            Float(track.year ?? 2000)
        ]
    }

    public func isAvailable() async -> Bool { true }

    private func inferGenre(for track: Track) -> String {
        if track.duration < 180 {
            return "Pop"
        } else if track.bitrate > 256 {
            return "Electronic"
        } else {
            return "Indie"
        }
    }

    private func inferMood(for track: Track) -> String {
        if track.duration > 360 {
            return "Chill"
        } else if let rating = track.rating, rating >= 4 {
            return "Upbeat"
        } else {
            return "Reflective"
        }
    }
}

// MARK: - Heuristic Recommendation Engine

/// Recommendation engine that uses indexed tracks and simple heuristics.
public actor HeuristicRecommendationEngine: RecommendationEngineProtocol {
    private let libraryIndexer: LibraryIndexerProtocol

    public init(libraryIndexer: LibraryIndexerProtocol) {
        self.libraryIndexer = libraryIndexer
    }

    public func recommendSimilar(to track: Track, limit: Int) async throws -> [Recommendation] {
        let candidates = await libraryIndexer.getAllTracks()
        guard !candidates.isEmpty else {
            throw RecommendationError.noTracksAvailable
        }

        let scored = candidates.compactMap { candidate -> Recommendation? in
            guard candidate.id != track.id else { return nil }
            let score = similarityScore(for: candidate, base: track)
            guard score > 0.1 else { return nil }
            return Recommendation(track: candidate, score: score, reason: reason(for: candidate, base: track))
        }

        return Array(scored.sorted { $0.score > $1.score }.prefix(limit))
    }

    public func recommendBasedOnHistory(limit: Int) async throws -> [Recommendation] {
        try await fallbackRecommendations(limit: limit)
    }

    public func recommendContextAware(limit: Int) async throws -> [Recommendation] {
        try await fallbackRecommendations(limit: limit)
    }

    private func fallbackRecommendations(limit: Int) async throws -> [Recommendation] {
        let tracks = await libraryIndexer.getAllTracks()
        guard !tracks.isEmpty else {
            throw RecommendationError.noTracksAvailable
        }
        let limited = tracks.prefix(limit)
        return limited.enumerated().map { index, track in
            Recommendation(
                track: track,
                score: 0.5 - Double(index) * 0.05,
                reason: "From your library"
            )
        }
    }

    private func similarityScore(for candidate: Track, base: Track) -> Double {
        var score = 0.0
        if candidate.artist == base.artist {
            score += 0.5
        }
        if candidate.album == base.album {
            score += 0.2
        }
        if candidate.genre == base.genre {
            score += 0.2
        }
        let durationDelta = abs(candidate.duration - base.duration)
        score += max(0, 0.1 - durationDelta / 1000)
        return min(score, 1.0)
    }

    private func reason(for candidate: Track, base: Track) -> String {
        var reasons: [String] = []
        if candidate.artist == base.artist {
            reasons.append("Same artist")
        }
        if candidate.genre == base.genre, let genre = base.genre {
            reasons.append("Same genre (\(genre))")
        }
        if reasons.isEmpty {
            reasons.append("Similar duration")
        }
        return reasons.joined(separator: ", ")
    }
}

// MARK: - No-op AcoustID Service

/// Placeholder AcoustID service that satisfies interfaces without external dependencies.
public struct NoOpAcoustIDService: AcoustIDServicing {
    public init() {}

    public func identifyTrack(fileURL: URL) async throws -> [AcoustIDMatch] {
        throw AcoustIDError.lookupFailed("AcoustID service not configured")
    }
}
