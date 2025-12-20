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
    
    @StateObject private var focusManager = DialogFocusManager()
    @FocusState private var textFieldFocused: Bool
    @FocusState private var cancelButtonFocused: Bool
    @FocusState private var createButtonFocused: Bool
    
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
                    .focused($textFieldFocused)
                    .keyboardActivation(
                        isFocused: $textFieldFocused,
                        onEnter: {
                            if !playlistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                onCreate()
                            }
                        }
                    )
                    .onSubmit {
                        onCreate()
                    }
                    .onAppear {
                        focusManager.registerFocusableElement("text-field")
                    }
                    .onDisappear {
                        focusManager.unregisterFocusableElement("text-field")
                    }
            }
            
            if let error = error {
                Text(errorMessage(for: error, localisation: localisation))
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            HStack {
                Button(localisation[LocalisationManager.cancel]) {
                    cancelAction()
                }
                .focused($cancelButtonFocused)
                .keyboardActivation(
                    isFocused: $cancelButtonFocused,
                    onEnter: cancelAction,
                    onEscape: cancelAction
                )
                .keyboardShortcut(.cancelAction)
                .onAppear {
                    focusManager.registerFocusableElement("cancel-button")
                }
                .onDisappear {
                    focusManager.unregisterFocusableElement("cancel-button")
                }
                
                Spacer()
                
                Button(localisation[LocalisationManager.create]) {
                    onCreate()
                }
                .buttonStyle(.borderedProminent)
                .focused($createButtonFocused)
                .keyboardActivation(
                    isFocused: $createButtonFocused,
                    onEnter: {
                        if !playlistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onCreate()
                        }
                    }
                )
                .disabled(playlistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
                .onAppear {
                    focusManager.registerFocusableElement("create-button")
                }
                .onDisappear {
                    focusManager.unregisterFocusableElement("create-button")
                }
            }
        }
        .padding()
        .frame(width: 400)
        .onAppear {
            // Open dialog and trap focus
            focusManager.openDialog(previousFocus: nil)
            // Focus text field initially
            textFieldFocused = true
            focusManager.setFocus(to: "text-field")
        }
        .onDisappear {
            // Close dialog and clear focus trap
            focusManager.closeDialog()
        }
        .onKeyPress(.tab) {
            // Handle Tab key navigation within dialog
            if focusManager.isFocusTrapped {
                _ = focusManager.moveFocusForward()
                updateFocusFromManager()
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.escape) {
            // Handle Escape key
            if focusManager.isFocusTrapped {
                cancelAction()
                return .handled
            }
            return .ignored
        }
        .onChange(of: focusManager.dialogFocusIdentifier) { _, _ in
            // Update focus state when manager changes
            updateFocusFromManager()
        }
    }
    
    // MARK: - Helper Methods
    
    private func cancelAction() {
        isPresented = false
        playlistName = ""
        error = nil
    }
    
    private func updateFocusFromManager() {
        guard let focusedId = focusManager.dialogFocusIdentifier else {
            return
        }
        
        switch focusedId {
        case "text-field":
            textFieldFocused = true
            cancelButtonFocused = false
            createButtonFocused = false
        case "cancel-button":
            textFieldFocused = false
            cancelButtonFocused = true
            createButtonFocused = false
        case "create-button":
            textFieldFocused = false
            cancelButtonFocused = false
            createButtonFocused = true
        default:
            break
        }
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
