//
//  MetadataMerger.swift
//  MetadataEngine
//
//  Metadata merge implementation
//

import Foundation
@preconcurrency import Shared

/// Metadata merger that applies merge strategies
public final class MetadataMerger: @unchecked Sendable {
    private let strategy: MergeStrategy
    
    /// Initialise with a merge strategy
    /// - Parameter strategy: The merge strategy to use
    public init(strategy: MergeStrategy = .fillMissing) {
        self.strategy = strategy
    }
    
    /// Merge metadata from multiple sources into a Track
    /// - Parameters:
    ///   - originalTrack: The original track with existing metadata
    ///   - sources: Array of metadata sources to merge
    /// - Returns: Merged Track with combined metadata
    /// - Throws: Error if merge fails
    public func merge(originalTrack: Track, sources: [MetadataSource]) throws -> Track {
        guard !sources.isEmpty else {
            throw MetadataMergeError.noSources
        }
        
        // Validate confidence scores
        for source in sources {
            if source.confidence < 0.0 || source.confidence > 1.0 {
                throw MetadataMergeError.invalidConfidence(source.confidence)
            }
        }
        
        let mergedFields: MetadataFields
        
        switch strategy {
        case .fillMissing:
            mergedFields = fillMissingStrategy(originalTrack: originalTrack, sources: sources)
        case .highestConfidence:
            mergedFields = highestConfidenceStrategy(originalTrack: originalTrack, sources: sources)
        case let .preferSource(preferredType):
            mergedFields = preferSourceStrategy(
                originalTrack: originalTrack,
                sources: sources,
                preferredType: preferredType
            )
        case .mostComplete:
            mergedFields = mostCompleteStrategy(originalTrack: originalTrack, sources: sources)
        case .conservative:
            mergedFields = conservativeStrategy(originalTrack: originalTrack, sources: sources)
        }
        
        // Create merged track
        return Track(
            id: originalTrack.id,
            title: mergedFields.title ?? originalTrack.title,
            artist: mergedFields.artist ?? originalTrack.artist,
            album: mergedFields.album ?? originalTrack.album,
            duration: originalTrack.duration,
            filePath: originalTrack.filePath,
            fileSize: originalTrack.fileSize,
            bitrate: originalTrack.bitrate,
            sampleRate: originalTrack.sampleRate,
            year: mergedFields.year ?? originalTrack.year,
            trackNumber: mergedFields.trackNumber ?? originalTrack.trackNumber,
            discNumber: mergedFields.discNumber ?? originalTrack.discNumber,
            genre: mergedFields.genre ?? originalTrack.genre,
            rating: originalTrack.rating
        )
    }
    
    // MARK: - Merge Strategies
    
    private func fillMissingStrategy(originalTrack: Track, sources: [MetadataSource]) -> MetadataFields {
        let originalFields = createOriginalFields(from: originalTrack)
        var merged = originalFields
        
        // Fill missing fields from sources (in order, first non-nil wins)
        for source in sources {
            merged = fillMissingFields(current: merged, source: source.metadata)
        }
        
        return merged
    }
    
    private func highestConfidenceStrategy(originalTrack: Track, sources: [MetadataSource]) -> MetadataFields {
        var bestFields: [String: (value: Any, confidence: Double)] = [:]
        
        // For each field, find the source with highest confidence
        for source in sources {
            updateBestFields(bestFields: &bestFields, source: source)
        }
        
        return createFieldsFromBestFields(bestFields)
    }
    
    private func preferSourceStrategy(
        originalTrack: Track,
        sources: [MetadataSource],
        preferredType: MetadataSourceType
    ) -> MetadataFields {
        // Find preferred source
        guard let preferredSource = sources.first(where: { $0.type == preferredType }) else {
            // Fall back to fillMissing if preferred source not found
            return fillMissingStrategy(originalTrack: originalTrack, sources: sources)
        }
        
        // Use preferred source, but fall back to original for missing fields
        let originalFields = createOriginalFields(from: originalTrack)
        
        return MetadataFields(
            title: preferredSource.metadata.title ?? originalFields.title,
            artist: preferredSource.metadata.artist ?? originalFields.artist,
            album: preferredSource.metadata.album ?? originalFields.album,
            year: preferredSource.metadata.year ?? originalFields.year,
            trackNumber: preferredSource.metadata.trackNumber ?? originalFields.trackNumber,
            discNumber: preferredSource.metadata.discNumber ?? originalFields.discNumber,
            genre: preferredSource.metadata.genre ?? originalFields.genre
        )
    }
    
    private func mostCompleteStrategy(originalTrack: Track, sources: [MetadataSource]) -> MetadataFields {
        let originalFields = createOriginalFields(from: originalTrack)
        let allSources = [MetadataSource(type: .existing, confidence: 1.0, metadata: originalFields)] + sources
        
        // Find source with highest completeness
        let mostComplete = allSources.max { source1, source2 in
            completenessScore(source1.metadata) < completenessScore(source2.metadata)
        }
        
        return mostComplete?.metadata ?? originalFields
    }
    
    private func conservativeStrategy(originalTrack: Track, sources: [MetadataSource]) -> MetadataFields {
        let originalFields = createOriginalFields(from: originalTrack)
        var merged = originalFields
        
        // Only update if new value is more complete (non-empty string vs empty, or non-nil vs nil)
        for source in sources {
            merged = updateFieldIfMoreComplete(
                current: merged,
                source: source.metadata,
                field: "title",
                getValue: { $0.title }
            )
            merged = updateFieldIfMoreComplete(
                current: merged,
                source: source.metadata,
                field: "artist",
                getValue: { $0.artist }
            )
            merged = updateFieldIfMoreComplete(
                current: merged,
                source: source.metadata,
                field: "album",
                getValue: { $0.album }
            )
            if merged.year == nil, let year = source.metadata.year {
                merged = updateNumericField(current: merged, field: "year", value: year)
            }
            if merged.trackNumber == nil, let trackNumber = source.metadata.trackNumber {
                merged = updateNumericField(current: merged, field: "trackNumber", value: trackNumber)
            }
            if merged.discNumber == nil, let discNumber = source.metadata.discNumber {
                merged = updateNumericField(current: merged, field: "discNumber", value: discNumber)
            }
            merged = updateFieldIfMoreComplete(
                current: merged,
                source: source.metadata,
                field: "genre",
                getValue: { $0.genre }
            )
        }
        
        return merged
    }
    
}

extension MetadataMerger: MetadataMergeStrategyProtocol {}
