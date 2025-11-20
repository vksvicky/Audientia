//
//  MetadataMerger+Helpers.swift
//  MetadataEngine
//
//  Helper methods for MetadataMerger
//

import Foundation
@preconcurrency import Shared

extension MetadataMerger {
    // MARK: - Helper Methods
    
    func createOriginalFields(from track: Track) -> MetadataFields {
        MetadataFields(
            title: track.title.isEmpty ? nil : track.title,
            artist: track.artist.isEmpty ? nil : track.artist,
            album: track.album.isEmpty ? nil : track.album,
            year: track.year,
            trackNumber: track.trackNumber,
            discNumber: track.discNumber,
            genre: track.genre
        )
    }
    
    func updateFieldIfMissing(
        current: MetadataFields,
        source: MetadataFields,
        field: String,
        getValue: (MetadataFields) -> String?,
        isEmpty: (String?) -> Bool
    ) -> MetadataFields {
        let currentValue = getValue(current)
        guard isEmpty(currentValue) else { return current }
        
        guard let newValue = getValue(source), !newValue.isEmpty else { return current }
        
        return updateStringField(current: current, field: field, value: newValue)
    }
    
    func updateFieldIfMoreComplete(
        current: MetadataFields,
        source: MetadataFields,
        field: String,
        getValue: (MetadataFields) -> String?
    ) -> MetadataFields {
        let currentValue = getValue(current)
        guard let newValue = getValue(source), !newValue.isEmpty else { return current }
        
        if let currentStr = currentValue, !currentStr.isEmpty {
            return current
        }
        
        return updateStringField(current: current, field: field, value: newValue)
    }
    
    func updateStringField(
        current: MetadataFields,
        field: String,
        value: String
    ) -> MetadataFields {
        switch field {
        case "title":
            return MetadataFields(
                title: value,
                artist: current.artist,
                album: current.album,
                year: current.year,
                trackNumber: current.trackNumber,
                discNumber: current.discNumber,
                genre: current.genre
            )
        case "artist":
            return MetadataFields(
                title: current.title,
                artist: value,
                album: current.album,
                year: current.year,
                trackNumber: current.trackNumber,
                discNumber: current.discNumber,
                genre: current.genre
            )
        case "album":
            return MetadataFields(
                title: current.title,
                artist: current.artist,
                album: value,
                year: current.year,
                trackNumber: current.trackNumber,
                discNumber: current.discNumber,
                genre: current.genre
            )
        case "genre":
            return MetadataFields(
                title: current.title,
                artist: current.artist,
                album: current.album,
                year: current.year,
                trackNumber: current.trackNumber,
                discNumber: current.discNumber,
                genre: value
            )
        default:
            return current
        }
    }
    
    func updateNumericFieldIfMissing(
        current: MetadataFields,
        source: MetadataFields,
        field: String,
        getValue: (MetadataFields) -> Int?
    ) -> MetadataFields {
        let currentValue = getValue(current)
        guard currentValue == nil else { return current }
        
        guard let newValue = getValue(source) else { return current }
        
        return updateNumericField(current: current, field: field, value: newValue)
    }
    
    func updateNumericField(
        current: MetadataFields,
        field: String,
        value: Int
    ) -> MetadataFields {
        switch field {
        case "year":
            return MetadataFields(
                title: current.title,
                artist: current.artist,
                album: current.album,
                year: value,
                trackNumber: current.trackNumber,
                discNumber: current.discNumber,
                genre: current.genre
            )
        case "trackNumber":
            return MetadataFields(
                title: current.title,
                artist: current.artist,
                album: current.album,
                year: current.year,
                trackNumber: value,
                discNumber: current.discNumber,
                genre: current.genre
            )
        case "discNumber":
            return MetadataFields(
                title: current.title,
                artist: current.artist,
                album: current.album,
                year: current.year,
                trackNumber: current.trackNumber,
                discNumber: value,
                genre: current.genre
            )
        default:
            return current
        }
    }
    
    func updateBestField<T>(
        bestFields: inout [String: (value: Any, confidence: Double)],
        key: String,
        value: T?,
        confidence: Double,
        isEmpty: (T?) -> Bool
    ) {
        guard let value = value, !isEmpty(value) else { return }
        let current = bestFields[key]?.confidence ?? 0.0
        if confidence > current {
            bestFields[key] = (value, confidence)
        }
    }
    
    func fillMissingFields(current: MetadataFields, source: MetadataFields) -> MetadataFields {
        var merged = current
        merged = updateFieldIfMissing(
            current: merged,
            source: source,
            field: "title",
            getValue: { $0.title },
            isEmpty: { $0 == nil }
        )
        merged = updateFieldIfMissing(
            current: merged,
            source: source,
            field: "artist",
            getValue: { $0.artist },
            isEmpty: { $0 == nil || $0?.isEmpty ?? true }
        )
        merged = updateFieldIfMissing(
            current: merged,
            source: source,
            field: "album",
            getValue: { $0.album },
            isEmpty: { $0 == nil || $0?.isEmpty ?? true }
        )
        merged = updateNumericFieldIfMissing(
            current: merged,
            source: source,
            field: "year",
            getValue: { $0.year }
        )
        merged = updateNumericFieldIfMissing(
            current: merged,
            source: source,
            field: "trackNumber",
            getValue: { $0.trackNumber }
        )
        merged = updateNumericFieldIfMissing(
            current: merged,
            source: source,
            field: "discNumber",
            getValue: { $0.discNumber }
        )
        merged = updateFieldIfMissing(
            current: merged,
            source: source,
            field: "genre",
            getValue: { $0.genre },
            isEmpty: { $0 == nil || $0?.isEmpty ?? true }
        )
        return merged
    }
    
    func updateBestFields(
        bestFields: inout [String: (value: Any, confidence: Double)],
        source: MetadataSource
    ) {
        updateBestField(
            bestFields: &bestFields,
            key: "title",
            value: source.metadata.title,
            confidence: source.confidence,
            isEmpty: { $0?.isEmpty ?? true }
        )
        updateBestField(
            bestFields: &bestFields,
            key: "artist",
            value: source.metadata.artist,
            confidence: source.confidence,
            isEmpty: { $0?.isEmpty ?? true }
        )
        updateBestField(
            bestFields: &bestFields,
            key: "album",
            value: source.metadata.album,
            confidence: source.confidence,
            isEmpty: { $0?.isEmpty ?? true }
        )
        updateBestField(
            bestFields: &bestFields,
            key: "year",
            value: source.metadata.year,
            confidence: source.confidence,
            isEmpty: { _ in false }
        )
        updateBestField(
            bestFields: &bestFields,
            key: "trackNumber",
            value: source.metadata.trackNumber,
            confidence: source.confidence,
            isEmpty: { _ in false }
        )
        updateBestField(
            bestFields: &bestFields,
            key: "discNumber",
            value: source.metadata.discNumber,
            confidence: source.confidence,
            isEmpty: { _ in false }
        )
        updateBestField(
            bestFields: &bestFields,
            key: "genre",
            value: source.metadata.genre,
            confidence: source.confidence,
            isEmpty: { $0?.isEmpty ?? true }
        )
    }
    
    func createFieldsFromBestFields(_ bestFields: [String: (value: Any, confidence: Double)]) -> MetadataFields {
        MetadataFields(
            title: bestFields["title"]?.value as? String,
            artist: bestFields["artist"]?.value as? String,
            album: bestFields["album"]?.value as? String,
            year: bestFields["year"]?.value as? Int,
            trackNumber: bestFields["trackNumber"]?.value as? Int,
            discNumber: bestFields["discNumber"]?.value as? Int,
            genre: bestFields["genre"]?.value as? String
        )
    }
    
    func completenessScore(_ fields: MetadataFields) -> Int {
        var score = 0
        if let title = fields.title, !title.isEmpty { score += 1 }
        if let artist = fields.artist, !artist.isEmpty { score += 1 }
        if let album = fields.album, !album.isEmpty { score += 1 }
        if fields.year != nil { score += 1 }
        if fields.trackNumber != nil { score += 1 }
        if fields.discNumber != nil { score += 1 }
        if let genre = fields.genre, !genre.isEmpty { score += 1 }
        return score
    }
}
