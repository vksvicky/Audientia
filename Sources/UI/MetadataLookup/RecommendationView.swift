//
//  RecommendationView.swift
//  UI
//
//  View for displaying recommendations (Feature 5.2)
//

@preconcurrency import MetadataEngine
@preconcurrency import Shared
import SwiftUI

/// View for displaying recommendations
public struct RecommendationView: View {
    @ObservedObject var viewModel: RecommendationViewModel
    let sourceTrack: Track?
    
    public init(viewModel: RecommendationViewModel, sourceTrack: Track? = nil) {
        self.viewModel = viewModel
        self.sourceTrack = sourceTrack
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Recommendations")
                    .font(.headline)
                Spacer()
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // Recommendations List
            if viewModel.recommendations.isEmpty && !viewModel.isLoading {
                Text("No recommendations available")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.recommendations, id: \.track.id) { recommendation in
                            RecommendationRow(recommendation: recommendation)
                        }
                    }
                }
            }
            
            // Error Display
            if let error = viewModel.lastError {
                Text("Error: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
            }
            
            // Action Buttons
            HStack {
                if let track = sourceTrack {
                    Button("More Like This") {
                        Task {
                            await viewModel.getRecommendations(for: track)
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
                
                Button("Based on History") {
                    Task {
                        await viewModel.getHistoryBasedRecommendations()
                    }
                }
                .disabled(viewModel.isLoading)
                
                Button("Context-Aware") {
                    Task {
                        await viewModel.getContextAwareRecommendations()
                    }
                }
                .disabled(viewModel.isLoading)
            }
        }
        .padding()
    }
}

/// Row displaying a single recommendation
private struct RecommendationRow: View {
    let recommendation: Recommendation
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Track Info
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.track.title)
                    .font(.body)
                    .fontWeight(.semibold)
                
                Text(recommendation.track.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if !recommendation.track.album.isEmpty {
                    Text(recommendation.track.album)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Score and Reason
            VStack(alignment: .trailing, spacing: 4) {
                // Score Badge
                Text("\(Int(recommendation.score * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(scoreColor)
                    .cornerRadius(8)
                
                // Reason
                Text(recommendation.reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 150, alignment: .trailing)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var scoreColor: Color {
        if recommendation.score > 0.8 {
            return .green
        } else if recommendation.score > 0.6 {
            return .yellow
        } else {
            return Color("AccentColor")
        }
    }
}
