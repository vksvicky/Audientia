//
//  CreatePlaylistDialog.swift
//  Audientia
//
//  Dialog for creating a new playlist
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import DataLayer
import Shared
import SwiftUI

/// Dialog for creating a new playlist
struct CreatePlaylistDialog: View {
    @Binding var isPresented: Bool
    @Binding var playlistName: String
    @Binding var error: Error?
    var onCreate: () -> Void
    
    var body: some View {
        let localisation = LocalisationManager.shared
        return VStack(spacing: 20) {
            Text(localisation[LocalisationManager.newPlaylist])
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(localisation[LocalisationManager.playlistName])
                    .font(.headline)
                
                TextField(localisation[LocalisationManager.enterPlaylistNamePlaceholder], text: $playlistName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        onCreate()
                    }
            }
            
            if let error = error {
                Text(errorMessage(for: error, localisation: localisation))
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            HStack {
                Button(localisation[LocalisationManager.cancel]) {
                    isPresented = false
                    playlistName = ""
                    error = nil
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button(localisation[LocalisationManager.create]) {
                    onCreate()
                }
                .buttonStyle(.borderedProminent)
                .disabled(playlistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400)
    }
    
    private func errorMessage(for error: Error, localisation: LocalisationManager) -> String {
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
