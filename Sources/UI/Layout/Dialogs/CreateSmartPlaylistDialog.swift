//
//  CreateSmartPlaylistDialog.swift
//  Audientia
//
//  Dialog for creating a new smart playlist
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import DataLayer
import SwiftUI

/// Dialog for creating a new smart playlist
struct CreateSmartPlaylistDialog: View {
    @Binding var isPresented: Bool
    @Binding var playlistName: String
    @Binding var error: Error?
    @ObservedObject var ruleBuilderViewModel: SmartPlaylistRuleBuilderViewModel
    var onCreate: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("New Smart Playlist")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Playlist Name")
                    .font(.headline)
                
                TextField("Enter smart playlist name", text: $playlistName)
                    .textFieldStyle(.roundedBorder)
            }
            
            Divider()
            
            // Rule builder
            VStack(alignment: .leading, spacing: 12) {
                Text("Rules")
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
                Button("Cancel") {
                    isPresented = false
                    playlistName = ""
                    error = nil
                    ruleBuilderViewModel.clearRules()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Create") {
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
        if let playlistError = error as? PlaylistManagerError {
            switch playlistError {
            case .invalidPlaylistName:
                return "Please enter a valid playlist name."
            case .duplicatePlaylist:
                return "A playlist with this name already exists."
            case .playlistNotFound:
                return "Playlist not found."
            case .trackNotFound:
                return "Track not found."
            case .duplicateTrack:
                return "Track is already in the playlist."
            case .invalidRules:
                return "Invalid playlist rules."
            case .operationFailed:
                return "Operation failed. Please try again."
            }
        }
        return error.localizedDescription
    }
}
