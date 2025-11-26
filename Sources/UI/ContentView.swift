//
//  ContentView.swift
//  Audientia
//
//  Main content view
//

import AppKitBridge
import AudioCore
import DataLayer
import Shared
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var sharedAudioEngine = AudioEngine()
    @StateObject private var importCoordinator: TrackImportCoordinator
    @State private var importError: Error?

    init() {
        let engine = AudioEngine()
        _sharedAudioEngine = State(initialValue: engine)
        _importCoordinator = StateObject(
            wrappedValue: TrackImportCoordinator(
                audioEngine: engine,
                indexer: LibraryIndexer()
            )
        )
    }

    var body: some View {
        TabView {
            NowPlayingView(audioEngine: sharedAudioEngine)
                .tabItem {
                    Label("Now Playing", systemImage: "music.note.house")
                }

            DeviceSyncView()
                .tabItem {
                    Label("Device Sync", systemImage: "externaldrive.connected.to.line.below")
                }

            MultiPaneLayoutView(audioEngine: sharedAudioEngine)
                .tabItem {
                    Label("Workspace", systemImage: "rectangle.3.offgrid")
                }
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAudioFilesDropped { urls in
            Task {
                do {
                    try await importCoordinator.importFiles(urls: urls)
                } catch {
                    importError = error
                }
            }
        }
        .alert("Import Error", isPresented: .constant(importError != nil)) {
            Button("OK") {
                importError = nil
            }
        } message: {
            if let error = importError {
                Text(error.localizedDescription)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings.shared)
}
