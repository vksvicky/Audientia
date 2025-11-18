//
//  MergeConflictResolutionView.swift
//  Audientia - Metadata Lookup UI
//
//  SwiftUI view that visualizes metadata conflicts between original and preview tracks
//

import AppKit
import Shared
import SwiftUI

public struct MergeConflictResolutionView: View {
    public let originalTrack: Shared.Track
    public let previewTrack: Shared.Track?
    
    public init(originalTrack: Shared.Track, previewTrack: Shared.Track?) {
        self.originalTrack = originalTrack
        self.previewTrack = previewTrack
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Merge Preview")
                .font(.headline)
            
            if let previewTrack {
                ForEach(fieldComparisons(preview: previewTrack), id: \.label) { comparison in
                    HStack {
                        Text(comparison.label)
                            .font(.subheadline)
                            .frame(width: 120, alignment: .leading)
                        Text(comparison.original)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Image(systemName: "arrow.right")
                            .foregroundStyle(.secondary)
                        Text(comparison.updated)
                            .font(.body)
                            .fontWeight(comparison.hasChanged ? .semibold : .regular)
                            .foregroundStyle(comparison.hasChanged ? .primary : .secondary)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    Divider()
                }
            } else {
                Text("Select a match to preview merged metadata.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
    
    private func fieldComparisons(preview: Shared.Track) -> [FieldComparison] {
        [
            FieldComparison(label: "Title", original: originalTrack.title, updated: preview.title),
            FieldComparison(label: "Artist", original: originalTrack.artist, updated: preview.artist),
            FieldComparison(label: "Album", original: originalTrack.album, updated: preview.album),
            FieldComparison(label: "Year", original: yearString(originalTrack.year), updated: yearString(preview.year)),
            FieldComparison(
                label: "Track #",
                original: numberString(originalTrack.trackNumber),
                updated: numberString(preview.trackNumber)
            ),
            FieldComparison(
                label: "Disc #",
                original: numberString(originalTrack.discNumber),
                updated: numberString(preview.discNumber)
            ),
            FieldComparison(label: "Genre", original: originalTrack.genre ?? "—", updated: preview.genre ?? "—")
        ]
    }
    
    private func yearString(_ value: Int?) -> String {
        guard let value else { return "—" }
        return String(value)
    }
    
    private func numberString(_ value: Int?) -> String {
        guard let value else { return "—" }
        return String(value)
    }
    
    private struct FieldComparison {
        let label: String
        let original: String
        let updated: String
        
        var hasChanged: Bool {
            original != updated
        }
    }
}
