//
//  MLClassificationViewModel.swift
//  UI
//
//  ViewModel for ML classification display (Feature 5.2)
//

import Foundation
@preconcurrency import MetadataEngine
import os.log
@preconcurrency import Shared
import SwiftUI

/// ViewModel for ML classification features
@MainActor
public final class MLClassificationViewModel: ObservableObject {
    @Published public var genreClassification: GenreClassification?
    @Published public var moodClassification: MoodClassification?
    @Published public var isClassifying = false
    @Published public var classificationError: String?
    
    private let classifier: any MLClassifierProtocol
    
    public init(classifier: any MLClassifierProtocol) {
        self.classifier = classifier
    }
    
    /// Classify genre for a track
    public func classifyGenre(for track: Track) async {
        guard !isClassifying else { return }
        
        isClassifying = true
        classificationError = nil
        
        do {
            let result = try await classifier.classifyGenre(for: track)
            genreClassification = result
            Logger.userInterface.info("Genre classified: \(result.genre) with confidence \(result.confidence)")
        } catch {
            classificationError = error.localizedDescription
            Logger.userInterface.error("Genre classification failed: \(error.localizedDescription)")
        }
        
        isClassifying = false
    }
    
    /// Classify mood for a track
    public func classifyMood(for track: Track) async {
        guard !isClassifying else { return }
        
        isClassifying = true
        classificationError = nil
        
        do {
            let result = try await classifier.classifyMood(for: track)
            moodClassification = result
            Logger.userInterface.info("Mood classified: \(result.mood) with confidence \(result.confidence)")
        } catch {
            classificationError = error.localizedDescription
            Logger.userInterface.error("Mood classification failed: \(error.localizedDescription)")
        }
        
        isClassifying = false
    }
    
    /// Classify both genre and mood for a track
    public func classifyAll(for track: Track) async {
        await classifyGenre(for: track)
        await classifyMood(for: track)
    }
    
    /// Clear classification results
    public func clear() {
        genreClassification = nil
        moodClassification = nil
        classificationError = nil
    }
}
