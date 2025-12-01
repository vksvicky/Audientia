//
//  MetadataNormaliser.swift
//  DataLayer
//
//  Applies simple, deterministic normalization rules to track metadata
//  (casing, whitespace, punctuation) before indexing/search.
//

import Foundation
import Shared

public protocol MetadataNormaliserProtocol: Sendable {
    func normalize(track: Track) -> Track
}

public struct MetadataNormaliser: MetadataNormaliserProtocol, Sendable {
    public init() {}

    public func normalize(track: Track) -> Track {
        Track(
            id: track.id,
            title: normalizeTitle(track.title),
            artist: normalizePersonOrGroupName(track.artist),
            album: normalizeTitle(track.album),
            duration: track.duration,
            filePath: track.filePath,
            fileSize: track.fileSize,
            bitrate: track.bitrate,
            sampleRate: track.sampleRate,
            year: track.year,
            trackNumber: track.trackNumber,
            discNumber: track.discNumber,
            genre: normalizeGenre(track.genre),
            rating: track.rating
        )
    }

    // MARK: - Field-specific rules

    private func normalizeTitle(_ value: String) -> String {
        normalizeWhitespace(value)
    }

    private func normalizePersonOrGroupName(_ value: String) -> String {
        let trimmed = normalizeWhitespace(value)
        // Collapse obvious casing like "radiohead" -> "Radiohead"
        if trimmed == trimmed.lowercased() {
            return capitalizingFirstLetters(trimmed)
        }
        return trimmed
    }

    private func normalizeGenre(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = normalizeWhitespace(value)
        return trimmed.isEmpty ? nil : trimmed.capitalized
    }

    // MARK: - Helpers

    private func normalizeWhitespace(_ value: String) -> String {
        // Replace all runs of whitespace with a single space and trim ends
        let components = value.components(separatedBy: .whitespacesAndNewlines)
        let joined = components.filter { !$0.isEmpty }.joined(separator: " ")
        return joined.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func capitalizingFirstLetters(_ value: String) -> String {
        value
            .split(separator: " ")
            .map { part in
                guard let first = part.first else { return "" }
                let head = String(first).uppercased()
                let tail = part.dropFirst().lowercased()
                return head + tail
            }
            .joined(separator: " ")
    }
}
