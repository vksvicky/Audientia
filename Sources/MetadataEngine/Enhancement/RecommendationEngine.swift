//
//  RecommendationEngine.swift
//  MetadataEngine
//
//  Recommendation engine implementation (Feature 5.2)
//

import Foundation
import os.log
@preconcurrency import Shared

/// Recommendation engine implementation
public actor RecommendationEngine: RecommendationEngineProtocol {
    private let logger = Logger.metadata
    private let similarityEngine: any SimilarityEngineProtocol
    private let listeningHistory: ListeningHistoryProtocol?
    private var allTracks: [Track] = []
    
    public init(
        similarityEngine: any SimilarityEngineProtocol,
        listeningHistory: ListeningHistoryProtocol? = nil
    ) {
        self.similarityEngine = similarityEngine
        self.listeningHistory = listeningHistory
    }
    
    // MARK: - RecommendationEngineProtocol
    
    public func recommendSimilar(to track: Track, limit: Int) async throws -> [Recommendation] {
        guard !allTracks.isEmpty else {
            throw RecommendationError.noTracksAvailable
        }
        
        // Find similar tracks using similarity engine
        let similarResults = try await similarityEngine.findSimilar(to: track, in: allTracks, limit: limit)
        
        // Convert to recommendations with reasons
        return similarResults.map { result in
            let reason = generateReason(for: result, basedOn: track)
            return Recommendation(track: result.track, score: result.similarity, reason: reason)
        }
    }
    
    public func recommendBasedOnHistory(limit: Int) async throws -> [Recommendation] {
        guard !allTracks.isEmpty else {
            throw RecommendationError.noTracksAvailable
        }
        
        guard let history = listeningHistory else {
            // If no history available, return empty list
            logger.debug("No listening history available for recommendations")
            return []
        }
        
        // Get recently played tracks (last 50 plays)
        let recentEvents = await history.getRecentEvents(limit: 50)
        guard !recentEvents.isEmpty else {
            logger.debug("No recent listening history available")
            return []
        }
        
        // Get unique recently played tracks (most recent first)
        var recentTrackIds: [UUID] = []
        var seenIds = Set<UUID>()
        for event in recentEvents.reversed() {
            if !seenIds.contains(event.trackId) && !event.wasSkipped {
                recentTrackIds.append(event.trackId)
                seenIds.insert(event.trackId)
            }
        }
        
        // Find tracks similar to recently played tracks
        var allRecommendations: [Recommendation] = []
        var seenRecommendations = Set<UUID>()
        
        for trackId in recentTrackIds.prefix(10) { // Limit to top 10 recently played
            guard let sourceTrack = allTracks.first(where: { $0.id == trackId }) else {
                continue
            }
            
            // Find similar tracks
            let similarResults = try await similarityEngine.findSimilar(
                to: sourceTrack,
                in: allTracks.filter { $0.id != trackId && !seenRecommendations.contains($0.id) },
                limit: limit
            )
            
            // Convert to recommendations
            for result in similarResults where !seenRecommendations.contains(result.track.id) {
                let playCount = await history.getPlayCount(for: sourceTrack.id)
                let reason = "Similar to recently played track (played \(playCount) times)"
                allRecommendations.append(
                    Recommendation(
                        track: result.track,
                        score: result.similarity * 0.8, // Slightly lower weight for history-based
                        reason: reason
                    )
                )
                seenRecommendations.insert(result.track.id)
            }
            
            if allRecommendations.count >= limit {
                break
            }
        }
        
        // Sort by score and return top results
        return Array(allRecommendations.sorted { $0.score > $1.score }.prefix(limit))
    }
    
    public func recommendContextAware(limit: Int) async throws -> [Recommendation] {
        guard !allTracks.isEmpty else {
            throw RecommendationError.noTracksAvailable
        }
        
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)
        
        // Get recent listening history for context
        guard let history = listeningHistory else {
            // Fall back to similarity-based if no history
        logger.debug("No listening history, using similarity-based recommendations")
        guard let randomTrack = allTracks.randomElement() else {
            throw RecommendationError.noTracksAvailable
        }
        return try await recommendSimilar(to: randomTrack, limit: limit)
        }
        
        // Get tracks played at similar times (same hour, same day of week)
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let similarTimeTracks = await history.getTracksPlayed(from: oneWeekAgo, to: now)
        
        guard !similarTimeTracks.isEmpty else {
            // Fall back to history-based recommendations
            return try await recommendBasedOnHistory(limit: limit)
        }
        
        // Find tracks similar to contextually relevant tracks
        var allRecommendations = try await findContextualRecommendations(
            similarTimeTracks: similarTimeTracks,
            hour: hour,
            weekday: weekday,
            limit: limit
        )
        
        // If we don't have enough, supplement with history-based
        if allRecommendations.count < limit {
            let historyRecommendations = try await recommendBasedOnHistory(limit: limit - allRecommendations.count)
            let seenIds = Set(allRecommendations.map { $0.track.id })
            for rec in historyRecommendations where !seenIds.contains(rec.track.id) {
                allRecommendations.append(rec)
            }
        }
        
        return Array(allRecommendations.sorted { $0.score > $1.score }.prefix(limit))
    }
    
    private func findContextualRecommendations(
        similarTimeTracks: [UUID],
        hour: Int,
        weekday: Int,
        limit: Int
    ) async throws -> [Recommendation] {
        var allRecommendations: [Recommendation] = []
        var seenRecommendations = Set<UUID>()
        let contextReason = generateContextReason(hour: hour, weekday: weekday)
        
        for trackId in similarTimeTracks.prefix(5) {
            guard let sourceTrack = allTracks.first(where: { $0.id == trackId }) else {
                continue
            }
            
            let similarResults = try await similarityEngine.findSimilar(
                to: sourceTrack,
                in: allTracks.filter { $0.id != trackId && !seenRecommendations.contains($0.id) },
                limit: limit
            )
            
            for result in similarResults where !seenRecommendations.contains(result.track.id) {
                allRecommendations.append(
                    Recommendation(
                        track: result.track,
                        score: result.similarity * 0.9, // High weight for context-aware
                        reason: "\(contextReason) - similar to tracks you've played at this time"
                    )
                )
                seenRecommendations.insert(result.track.id)
            }
            
            if allRecommendations.count >= limit {
                break
            }
        }
        
        return allRecommendations
    }
    
    private func generateContextReason(hour: Int, weekday: Int) -> String {
        var reasons: [String] = []
        
        // Time of day context
        switch hour {
        case 6..<12:
            reasons.append("morning")
        case 12..<17:
            reasons.append("afternoon")
        case 17..<22:
            reasons.append("evening")
        default:
            reasons.append("night")
        }
        
        // Day of week context
        switch weekday {
        case 1, 7: // Sunday, Saturday
            reasons.append("weekend")
        default:
            reasons.append("weekday")
        }
        
        return reasons.joined(separator: " ")
    }
    
    // MARK: - Public Helpers
    
    /// Update the track library for recommendations
    public func updateTrackLibrary(_ tracks: [Track]) {
        self.allTracks = tracks
        logger.info("Updated recommendation engine with \(tracks.count) tracks")
    }
    
    // MARK: - Private Helpers
    
    private func generateReason(for result: SimilarityResult, basedOn track: Track) -> String {
        var reasons: [String] = []
        
        // Add similarity-based reason
        if result.similarity > 0.9 {
            reasons.append("Very similar audio features")
        } else if result.similarity > 0.7 {
            reasons.append("Similar audio features")
        } else {
            reasons.append("Somewhat similar audio features")
        }
        
        // Add metadata-based reasons
        if result.track.artist == track.artist {
            reasons.append("same artist")
        }
        
        if result.track.album == track.album {
            reasons.append("same album")
        }
        
        if let genre1 = track.genre, let genre2 = result.track.genre, genre1 == genre2 {
            reasons.append("same genre")
        }
        
        return reasons.joined(separator: ", ")
    }
}
