//
//  TrackDetailsViewModel.swift
//  Audientia
//
//  ViewModel powering the Track Details panel
//

import Foundation
import Shared
import SwiftUI

/// Represents a row rendered in the Track Details info grid.
public struct TrackDetailRow: Identifiable, Equatable {
    public let id: UUID
    public let title: String
    public let value: String
    public let icon: String

    public init(id: UUID = UUID(), title: String, value: String, icon: String) {
        self.id = id
        self.title = title
        self.value = value
        self.icon = icon
    }
}

/// ViewModel responsible for formatting and loading track details.
@MainActor
public final class TrackDetailsViewModel: ObservableObject {
    @Published public private(set) var selectedTrack: Track?
    @Published public private(set) var summaryRows: [TrackDetailRow] = []
    @Published public private(set) var audioRows: [TrackDetailRow] = []
    @Published public private(set) var fileRows: [TrackDetailRow] = []
    @Published public private(set) var tagRows: [TrackDetailRow] = []
    @Published public private(set) var metadata: TrackMetadata?
    @Published public private(set) var isLoadingMetadata = false
    @Published public private(set) var lastError: Error?

    private let metadataProvider: any TrackMetadataProviding
    private var metadataTask: Task<Void, Never>?

    public init(metadataProvider: any TrackMetadataProviding) {
        self.metadataProvider = metadataProvider
    }

    deinit {
        metadataTask?.cancel()
    }

    /// Update the current selection and refresh metadata.
    public func updateSelection(_ track: Track?) async {
        metadataTask?.cancel()
        selectedTrack = track
        metadata = nil
        lastError = nil
        isLoadingMetadata = false

        guard let track else {
            summaryRows = []
            audioRows = []
            fileRows = []
            tagRows = []
            return
        }

        summaryRows = buildSummaryRows(for: track)
        audioRows = buildAudioRows(for: track)
        fileRows = buildFileRows(for: track)
        tagRows = []

        metadataTask = Task { [weak self] in
            await self?.loadMetadata(for: track)
        }
        
        // Await the metadata loading so errors are set synchronously
        await metadataTask?.value
    }

    /// Clear the last error so the UI can dismiss alerts.
    public func clearError() {
        lastError = nil
    }

    private func loadMetadata(for track: Track) async {
        isLoadingMetadata = true
        do {
            let metadata = try await metadataProvider.metadata(for: track)
            guard !Task.isCancelled else { return }
            self.metadata = metadata
            self.tagRows = buildTagRows(for: metadata)
            lastError = nil
        } catch {
            guard !Task.isCancelled else { return }
            self.metadata = nil
            self.tagRows = []
            lastError = error
        }
        isLoadingMetadata = false
    }

    private func buildSummaryRows(for track: Track) -> [TrackDetailRow] {
        var rows: [TrackDetailRow] = [
            TrackDetailRow(title: "Title", value: track.title, icon: "textformat"),
            TrackDetailRow(title: "Artist", value: track.artist, icon: "person.fill"),
            TrackDetailRow(title: "Album", value: track.album, icon: "square.stack.fill")
        ]

        if let year = track.year {
            rows.append(TrackDetailRow(title: "Year", value: String(year), icon: "calendar"))
        }

        if let trackNumber = track.trackNumber {
            let discSuffix = track.discNumber.map { " (Disc \($0))" } ?? ""
            rows.append(
                TrackDetailRow(
                    title: "Track #",
                    value: "\(trackNumber)\(discSuffix)",
                    icon: "number"
                )
            )
        }

        if let genre = track.genre {
            rows.append(TrackDetailRow(title: "Genre", value: genre, icon: "music.note"))
        }

        if let rating = track.rating {
            rows.append(
                TrackDetailRow(
                    title: "Rating",
                    value: String(repeating: "★", count: rating),
                    icon: "star.fill"
                )
            )
        }

        return rows
    }

    private func buildAudioRows(for track: Track) -> [TrackDetailRow] {
        [
            TrackDetailRow(
                title: "Duration",
                value: formatDuration(track.duration),
                icon: "clock"
            ),
            TrackDetailRow(
                title: "Sample Rate",
                value: "\(track.sampleRate) Hz",
                icon: "waveform"
            ),
            TrackDetailRow(
                title: "Bitrate",
                value: "\(track.bitrate) kbps",
                icon: "speedometer"
            )
        ]
    }

    private func buildFileRows(for track: Track) -> [TrackDetailRow] {
        [
            TrackDetailRow(title: "File", value: track.filePath, icon: "doc"),
            TrackDetailRow(title: "Size", value: formatFileSize(track.fileSize), icon: "externaldrive")
        ]
    }

    private func buildTagRows(for metadata: TrackMetadata) -> [TrackDetailRow] {
        var rows: [TrackDetailRow] = [
            TrackDetailRow(title: "Play Count", value: "\(metadata.playCount)", icon: "repeat")
        ]

        rows.append(contentsOf: [
            optionalRow(title: "BPM", value: metadata.bpm.map { "\($0)" }, icon: "metronome.fill"),
            optionalRow(title: "Key", value: metadata.musicalKey, icon: "pianokeys.inverse"),
            optionalRow(title: "Comment", value: metadata.comment, icon: "note.text")
        ].compactMap { $0 })

        rows.append(contentsOf: temporalRows(for: metadata))
        rows.append(contentsOf: [
            optionalRow(
                title: "Energy",
                value: metadata.energy.map { "\(Int($0 * 100))%" },
                icon: "bolt.fill"
            ),
            optionalRow(
                title: "Danceability",
                value: metadata.danceability.map { "\(Int($0 * 100))%" },
                icon: "figure.dance"
            )
        ].compactMap { $0 })

        return rows
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = duration >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: duration) ?? "--:--"
    }

    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func optionalRow(title: String, value: String?, icon: String) -> TrackDetailRow? {
        guard let value else { return nil }
        return TrackDetailRow(title: title, value: value, icon: icon)
    }

    private func temporalRows(for metadata: TrackMetadata) -> [TrackDetailRow] {
        [
            metadata.lastPlayed.map {
                TrackDetailRow(
                    title: "Last Played",
                    value: relativeDate($0),
                    icon: "clock.arrow.circlepath"
                )
            },
            metadata.addedDate.map {
                TrackDetailRow(
                    title: "Added",
                    value: relativeDate($0),
                    icon: "calendar.badge.plus"
                )
            }
        ].compactMap { $0 }
    }
}
