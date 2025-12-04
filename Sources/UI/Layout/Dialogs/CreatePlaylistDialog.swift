//
//  CreatePlaylistDialog.swift
//  Audientia
//
//  Dialog for creating a new playlist
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import DataLayer
import SwiftUI

/// Dialog for creating a new playlist
struct CreatePlaylistDialog: View {
    @Binding var isPresented: Bool
    @Binding var playlistName: String
    @Binding var error: Error?
    var onCreate: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("New Playlist")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Playlist Name")
                    .font(.headline)
                
                TextField("Enter playlist name", text: $playlistName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        onCreate()
                    }
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
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Create") {
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
