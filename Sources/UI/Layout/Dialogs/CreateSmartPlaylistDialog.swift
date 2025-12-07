//
//  CreateSmartPlaylistDialog.swift
//  Audientia
//
//  Dialog for creating a new smart playlist
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import DataLayer
import Shared
import SwiftUI

/// Dialog for creating a new smart playlist
struct CreateSmartPlaylistDialog: View {
    @Binding var isPresented: Bool
    @Binding var playlistName: String
    @Binding var error: Error?
    @ObservedObject var ruleBuilderViewModel: SmartPlaylistRuleBuilderViewModel
    var onCreate: () -> Void
    
    var body: some View {
        let localisation = LocalisationManager.shared
        return VStack(spacing: 20) {
            Text(localisation[LocalisationManager.newSmartPlaylist])
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                Text(localisation[LocalisationManager.playlistName])
                    .font(.headline)
                
                TextField(localisation[LocalisationManager.enterSmartPlaylistName], text: $playlistName)
                    .textFieldStyle(.roundedBorder)
            }
            
            Divider()
            
            // Rule builder
            VStack(alignment: .leading, spacing: 12) {
                Text(localisation[LocalisationManager.rules])
                    .font(.headline)
                
                SmartPlaylistRuleBuilderView(viewModel: ruleBuilderViewModel)
                    .frame(height: 400)
            }
            
            if let error = error {
                Text(errorMessage(for: error))
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            HStack {
                Button(localisation[LocalisationManager.cancel]) {
                    isPresented = false
                    playlistName = ""
                    error = nil
                    ruleBuilderViewModel.clearRules()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button(localisation[LocalisationManager.create]) {
                    onCreate()
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    playlistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    !ruleBuilderViewModel.isValid
                )
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 700, height: 600)
    }
    
    private func errorMessage(for error: Error) -> String {
        let localisation = LocalisationManager.shared
        if let playlistError = error as? PlaylistManagerError {
            switch playlistError {
            case .invalidPlaylistName:
                return localisation[LocalisationManager.invalidPlaylistName]
            case .duplicatePlaylist:
                return localisation[LocalisationManager.duplicatePlaylist]
            case .playlistNotFound:
                return localisation[LocalisationManager.playlistNotFound]
            case .trackNotFound:
                return localisation[LocalisationManager.trackNotFound]
            case .duplicateTrack:
                return localisation[LocalisationManager.duplicateTrack]
            case .invalidRules:
                return localisation[LocalisationManager.invalidRules]
            case .operationFailed:
                return localisation[LocalisationManager.operationFailed]
            }
        }
        return error.localizedDescription
    }
}
