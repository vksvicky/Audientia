//
//  RecommendationViewModel.swift
//  UI
//
//  ViewModel for recommendations (Feature 5.2)
//

import Foundation
@preconcurrency import MetadataEngine
import os.log
@preconcurrency import Shared
import SwiftUI

/// ViewModel for recommendations
@MainActor
public final class RecommendationViewModel: ObservableObject {
    @Published public var recommendations: [Recommendation] = []
    @Published public var isLoading = false
    @Published public var lastError: String?
    
    private let recommendationEngine: any RecommendationEngineProtocol
    
    public init(recommendationEngine: any RecommendationEngineProtocol) {
        self.recommendationEngine = recommendationEngine
    }
    
    /// Get recommendations similar to a track
    public func getRecommendations(for track: Track, limit: Int = 10) async {
        guard !isLoading else { return }
        
        isLoading = true
        lastError = nil
        
        do {
            let results = try await recommendationEngine.recommendSimilar(to: track, limit: limit)
            recommendations = results
            Logger.userInterface.info("Retrieved \(results.count) recommendations for track: \(track.title)")
        } catch {
            lastError = error.localizedDescription
            Logger.userInterface.error("Failed to get recommendations: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Get recommendations based on listening history
    public func getHistoryBasedRecommendations(limit: Int = 10) async {
        guard !isLoading else { return }
        
        isLoading = true
        lastError = nil
        
        do {
            let results = try await recommendationEngine.recommendBasedOnHistory(limit: limit)
            recommendations = results
            Logger.userInterface.info("Retrieved \(results.count) history-based recommendations")
        } catch {
            lastError = error.localizedDescription
            Logger.userInterface.error("Failed to get history-based recommendations: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Get context-aware recommendations
    public func getContextAwareRecommendations(limit: Int = 10) async {
        guard !isLoading else { return }
        
        isLoading = true
        lastError = nil
        
        do {
            let results = try await recommendationEngine.recommendContextAware(limit: limit)
            recommendations = results
            Logger.userInterface.info("Retrieved \(results.count) context-aware recommendations")
        } catch {
            lastError = error.localizedDescription
            Logger.userInterface.error("Failed to get context-aware recommendations: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Clear recommendations
    public func clear() {
        recommendations = []
        lastError = nil
    }
}
