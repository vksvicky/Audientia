//
//  TrackDetailsView.swift
//  Audientia
//
//  SwiftUI surface for the Track Details panel
//

import Shared
import SwiftUI

@MainActor
public struct TrackDetailsView: View {
    @EnvironmentObject private var trackSelection: TrackSelectionStore
    @StateObject private var viewModel: TrackDetailsViewModel
    @StateObject private var classificationViewModel: MLClassificationViewModel
    @StateObject private var recommendationViewModel: RecommendationViewModel
    @StateObject private var fingerprintViewModel: FingerprintStatusViewModel

    private let dependencies: TrackDetailsDependencies

    public init(
        viewModel: TrackDetailsViewModel? = nil,
        dependencies: TrackDetailsDependencies = .live()
    ) {
        self.dependencies = dependencies
        if let viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            _viewModel = StateObject(
                wrappedValue: TrackDetailsViewModel(
                    metadataProvider: dependencies.metadataProvider
                )
            )
        }
        _classificationViewModel = StateObject(
            wrappedValue: MLClassificationViewModel(classifier: dependencies.classifier)
        )
        _recommendationViewModel = StateObject(
            wrappedValue: RecommendationViewModel(recommendationEngine: dependencies.recommendationEngine)
        )
        _fingerprintViewModel = StateObject(
            wrappedValue: FingerprintStatusViewModel(
                acoustIDService: dependencies.acoustIDService,
                fingerprintCache: dependencies.fingerprintCache
            )
        )
    }

    public var body: some View {
        Group {
            if let track = trackSelection.selectedTrack {
                content(for: track)
            } else {
                placeholder
            }
        }
        .task(id: trackSelection.selectedTrack?.id) {
            await viewModel.updateSelection(trackSelection.selectedTrack)
        }
    }

    private func content(for track: Track) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header(for: track)
                TrackDetailSection(
                    title: LocalisationManager.shared[LocalisationManager.summary],
                    rows: viewModel.summaryRows
                )
                TrackDetailSection(
                    title: LocalisationManager.shared[LocalisationManager.trackDetailsAudio],
                    rows: viewModel.audioRows
                )
                TrackDetailSection(
                    title: LocalisationManager.shared[LocalisationManager.file],
                    rows: viewModel.fileRows
                )

                if viewModel.isLoadingMetadata {
                    ProgressView(LocalisationManager.shared[LocalisationManager.loadingMetadata])
                        .controlSize(.small)
                }

                if !viewModel.tagRows.isEmpty {
                    TrackDetailSection(
                        title: LocalisationManager.shared[LocalisationManager.insights],
                        rows: viewModel.tagRows
                    )
                }

                MLClassificationView(viewModel: classificationViewModel, track: track)
                    .background(sectionBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                RecommendationView(viewModel: recommendationViewModel, sourceTrack: track)
                    .background(sectionBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                FingerprintStatusView(viewModel: fingerprintViewModel, track: track)
                    .background(sectionBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                if let error = viewModel.lastError {
                    Label(error.localizedDescription, systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .padding()
                        .background(sectionBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .onTapGesture {
                            viewModel.clearError()
                        }
                }
            }
            .padding()
        }
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func header(for track: Track) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(track.title)
                .font(.title)
                .fontWeight(.semibold)
            Text("\(track.artist) • \(track.album)")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }

    private var placeholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "info.circle")
                .font(.system(size: 42))
                .foregroundColor(.secondary)
            Text(LocalisationManager.shared[LocalisationManager.selectTrack])
                .font(.title3)
            Text(LocalisationManager.shared[LocalisationManager.chooseTrack])
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 260)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sectionBackground: some View {
        Color(NSColor.controlBackgroundColor)
    }
}

// MARK: - Section View

private struct TrackDetailSection: View {
    let title: String
    let rows: [TrackDetailRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(rows) { row in
                    HStack {
                        Image(systemName: row.icon)
                            .foregroundColor(.accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.title)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(row.value)
                                .font(.body)
                                .lineLimit(2)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12, alignment: .top),
            GridItem(.flexible(), spacing: 12, alignment: .top)
        ]
    }
}
