//
//  MLClassificationView.swift
//  UI
//
//  View for displaying ML classification results (Feature 5.2)
//

@preconcurrency import MetadataEngine
@preconcurrency import Shared
import SwiftUI

/// View for displaying ML classification results
public struct MLClassificationView: View {
    @ObservedObject var viewModel: MLClassificationViewModel
    let track: Track
    
    public init(viewModel: MLClassificationViewModel, track: Track) {
        self.viewModel = viewModel
        self.track = track
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Genre Classification
            if let genre = viewModel.genreClassification {
                ClassificationSection(
                    title: "Genre",
                    value: genre.genre,
                    confidence: genre.confidence,
                    allProbabilities: genre.allProbabilities
                )
            }
            
            // Mood Classification
            if let mood = viewModel.moodClassification {
                ClassificationSection(
                    title: "Mood",
                    value: mood.mood,
                    confidence: mood.confidence,
                    allProbabilities: mood.allProbabilities
                )
            }
            
            // Classification Status
            if viewModel.isClassifying {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Classifying...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Error Display
            if let error = viewModel.classificationError {
                Text("Error: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            // Action Buttons
            HStack {
                Button("Classify Genre") {
                    Task {
                        await viewModel.classifyGenre(for: track)
                    }
                }
                .disabled(viewModel.isClassifying)
                
                Button("Classify Mood") {
                    Task {
                        await viewModel.classifyMood(for: track)
                    }
                }
                .disabled(viewModel.isClassifying)
                
                Button("Classify All") {
                    Task {
                        await viewModel.classifyAll(for: track)
                    }
                }
                .disabled(viewModel.isClassifying)
            }
        }
        .padding()
    }
}

/// Section displaying a classification result
private struct ClassificationSection: View {
    let title: String
    let value: String
    let confidence: Double
    let allProbabilities: [String: Double]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(value)
                    .font(.body)
                    .fontWeight(.semibold)
            }
            
            // Confidence Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(confidenceColor)
                        .frame(width: geometry.size.width * CGFloat(confidence), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            Text("Confidence: \(Int(confidence * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Top probabilities
            if allProbabilities.count > 1 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("All Probabilities:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ForEach(
                        Array(allProbabilities.sorted { $0.value > $1.value }.prefix(3)),
                        id: \.key
                    ) { genre, prob in
                        HStack {
                            Text(genre)
                                .font(.caption)
                            Spacer()
                            Text("\(Int(prob * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var confidenceColor: Color {
        if confidence > 0.8 {
            return .green
        } else if confidence > 0.6 {
            return .yellow
        } else {
            return .orange
        }
    }
}
