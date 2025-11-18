//
//  MetadataLookupView.swift
//  Audientia - Metadata Lookup UI
//
//  SwiftUI interface for metadata lookup, merge conflict resolution, and auto-tagging progress
//

import MetadataEngine
import Shared
import SwiftUI

public struct MetadataLookupView: View {
    @StateObject private var viewModel: MetadataLookupViewModel
    
    public init(viewModel: MetadataLookupViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public init(
        acoustIDService: any AcoustIDServicing,
        musicBrainzClient: any MusicBrainzClientProtocol,
        discogsClient: any DiscogsClientProtocol,
        metadataMerger: any MetadataMergeStrategyProtocol = MetadataMerger()
    ) {
        _viewModel = StateObject(
            wrappedValue: MetadataLookupViewModel(
                acoustIDService: acoustIDService,
                musicBrainzClient: musicBrainzClient,
                discogsClient: discogsClient,
                metadataMerger: metadataMerger
            )
        )
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            strategySection
            matchesSection
            if let track = viewModel.currentTrack {
                MergeConflictResolutionView(originalTrack: track, previewTrack: viewModel.mergePreview)
            }
            AutoTaggingProgressView(viewModel: viewModel.autoTaggingProgressViewModel)
        }
        .padding()
        .task(id: viewModel.lastError?.localizedDescription) {
            // No-op task used to react to error changes if needed
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Metadata Lookup")
                    .font(.largeTitle).bold()
                Spacer()
                if viewModel.isLookingUp {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
            
            Text(viewModel.statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                Button("Lookup Metadata") {
                    Task {
                        await viewModel.performLookup()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.currentTrack == nil || viewModel.isLookingUp)
                
                Button("Apply Selection") {
                    _ = viewModel.applySelectedMatch()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.mergePreview == nil)
            }
        }
    }
    
    private var strategySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Merge Strategy")
                .font(.headline)
            Picker("Merge Strategy", selection: $viewModel.mergeStrategy) {
                Text("Fill Missing").tag(MergeStrategy.fillMissing)
                Text("Highest Confidence").tag(MergeStrategy.highestConfidence)
                Text("Most Complete").tag(MergeStrategy.mostComplete)
                Text("Conservative").tag(MergeStrategy.conservative)
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var matchesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Matches")
                .font(.headline)
            if viewModel.matches.isEmpty {
                Text("No matches yet. Tap \"Lookup Metadata\" to begin.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                List(viewModel.matches) { match in
                    Button {
                        viewModel.selectMatch(match.id)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(match.summary)
                                    .font(.body)
                                    .fontWeight(viewModel.selectedMatchID == match.id ? .semibold : .regular)
                                Text(
                                    "\(match.source.rawValue.capitalized) • "
                                    + "Confidence \(Int(match.confidence * 100))%"
                                )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if viewModel.selectedMatchID == match.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
                .frame(height: 200)
            }
        }
    }
}
