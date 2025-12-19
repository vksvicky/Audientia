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

@MainActor
struct ContentView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var sharedAudioEngine: AudioEngine
    @StateObject private var importCoordinator: TrackImportCoordinator
    @State private var importError: Error?
    @State private var showImportError = false

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
        MainWindowLayoutView(audioEngine: sharedAudioEngine)
            .onAudioFilesDropped { urls in
                Task {
                    do {
                        try await importCoordinator.importFiles(urls: urls)
                    } catch {
                        importError = error
                        showImportError = true
                    }
                }
            }
            .alert(LocalisationManager.shared[LocalisationManager.error], isPresented: $showImportError) {
                Button(LocalisationManager.shared[LocalisationManager.apply]) {
                    importError = nil
                    showImportError = false
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
