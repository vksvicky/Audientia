//
//  MetadataLookupSheetView.swift
//  Audientia - Tag Editor Integration
//
//  Wrapper view for MetadataLookupView in a sheet presentation
//

import MetadataEngine
import Shared
import SwiftUI

/// Wrapper view that presents MetadataLookupView in a sheet with proper callbacks
@MainActor
public struct MetadataLookupSheetView: View {
    let track: Shared.Track
    let acoustIDService: any AcoustIDServicing
    let musicBrainzClient: any MusicBrainzClientProtocol
    let discogsClient: any DiscogsClientProtocol
    let onApply: (Shared.Track) -> Void
    let onCancel: () -> Void
    
    @StateObject private var lookupViewModel: MetadataLookupViewModel
    
    public init(
        track: Shared.Track,
        acoustIDService: any AcoustIDServicing,
        musicBrainzClient: any MusicBrainzClientProtocol,
        discogsClient: any DiscogsClientProtocol,
        onApply: @escaping (Shared.Track) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.track = track
        self.acoustIDService = acoustIDService
        self.musicBrainzClient = musicBrainzClient
        self.discogsClient = discogsClient
        self.onApply = onApply
        self.onCancel = onCancel
        
        _lookupViewModel = StateObject(
            wrappedValue: MetadataLookupViewModel(
                acoustIDService: acoustIDService,
                musicBrainzClient: musicBrainzClient,
                discogsClient: discogsClient
            )
        )
    }
    
    public var body: some View {
        NavigationStack {
            MetadataLookupView(viewModel: lookupViewModel)
                .navigationTitle("Metadata Lookup")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", action: onCancel)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Apply") {
                            if let mergedTrack = lookupViewModel.applySelectedMatch() {
                                onApply(mergedTrack)
                            }
                        }
                        .disabled(lookupViewModel.mergePreview == nil)
                    }
                }
                .onAppear {
                    lookupViewModel.loadTrack(track)
                }
        }
    }
}
