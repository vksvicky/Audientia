// NowPlayingView.swift
// Audientia - Now Playing View
//
// Copyright © 2025 CycleRunCode Club. All rights reserved.

import AppKitBridge
import AudioCore
import DataLayer
import os.log
import Shared
import SwiftUI

/// Main Now Playing view with playback controls
/// BDD: As a user, I want to see the currently playing track and control playback
@MainActor
public struct NowPlayingView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel: NowPlayingViewModel
    @State private var isSeeking = false
    @State private var seekPosition: TimeInterval = 0.0
    @State private var showingFilePicker = false
    @State private var importError: Error?
    private let audioEngine: (any AudioEngineProtocol)?

    // MARK: - Initialization

    /// Initialize with AudioEngine
    /// - Parameter audioEngine: The audio engine to control (optional, creates default if not provided)
    public init(audioEngine: (any AudioEngineProtocol)? = nil) {
        self.audioEngine = audioEngine
        if let audioEngine = audioEngine {
            _viewModel = StateObject(wrappedValue: NowPlayingViewModel(audioEngine: audioEngine))
        } else {
            _viewModel = StateObject(wrappedValue: NowPlayingViewModel())
        }
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 20) {
            // Import Button
            importButtonView

            // Track Information
            trackInformationView

            // Progress Slider
            progressSliderView

            // Playback Controls
            playbackControlsView

            // Advanced Controls (Replay, Skip, Loop)
            advancedControlsView

            // Volume Control
            volumeControlView

            // Playback State Indicator
            playbackStateIndicatorView
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
        .onAppear {
            Logger.userInterface.info("NowPlayingView appeared")
        }
        .onDisappear {
            Logger.userInterface.debug("NowPlayingView disappeared")
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

private extension NowPlayingView {
    // MARK: - Import Button View
    
    var importButtonView: some View {
        Button {
            let urls = AudioFileDialog.showOpenPanel(allowsMultipleSelection: true)
            if !urls.isEmpty {
                Task {
                    do {
                        let engine = audioEngine ?? AudioEngine()
                        let indexer = LibraryIndexer()
                        let coordinator = TrackImportCoordinator(
                            audioEngine: engine,
                            indexer: indexer
                        )
                        try await coordinator.importFiles(urls: urls)
                        // Auto-play first track if queue was empty
                        if viewModel.currentTrack == nil, let firstTrack = engine.queue.first {
                            try await viewModel.loadTrack(firstTrack)
                            try await viewModel.play()
                        }
                    } catch {
                        importError = error
                    }
                }
            }
        } label: {
            Label("Import Files", systemImage: "folder.badge.plus")
        }
        .buttonStyle(.bordered)
    }

    // MARK: - Track Information View

    var trackInformationView: some View {
        VStack(spacing: 8) {
            if let track = viewModel.currentTrack {
                Text(track.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text(track.artist)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(track.album)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            } else {
                Text("No track loaded")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Progress Slider View
    
    var progressSliderView: some View {
        VStack(spacing: 4) {
            Slider(
                value: isSeeking ? $seekPosition : Binding(
                    get: { viewModel.currentPosition },
                    set: { _ in }
                ),
                in: 0...max(viewModel.duration, 1.0),
                onEditingChanged: { editing in
                    isSeeking = editing
                    if editing {
                        seekPosition = viewModel.currentPosition
                        Logger.userInterface.debug(
                            "Seek started at \(viewModel.currentPosition, privacy: .public) seconds"
                        )
                    } else {
                        Task {
                            await viewModel.seek(to: seekPosition)
                            Logger.userInterface.info("Seek completed to \(seekPosition, privacy: .public) seconds")
                        }
                    }
                }
            )
            .disabled(viewModel.duration <= 0)
            
            HStack {
                Text(formatTime(viewModel.currentPosition))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatTime(viewModel.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Playback Controls View
    
    var playbackControlsView: some View {
        HStack(spacing: 20) {
            // Previous button
            Button {
                Task {
                    do {
                        try await viewModel.playPrevious()
                    } catch {
                        Logger.userInterface.error(
                            "Play previous failed: \(error.localizedDescription, privacy: .public)"
                        )
                    }
                }
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title2)
            }
            .disabled(viewModel.currentTrack == nil)
            
            // Play/Pause button
            Button {
                Task {
                    if viewModel.isPlaying {
                        await viewModel.pause()
                    } else {
                        do {
                            try await viewModel.play()
                        } catch {
                            Logger.userInterface.error("Play failed: \(error.localizedDescription, privacy: .public)")
                        }
                    }
                }
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title)
                    .frame(width: 50, height: 50)
            }
            .disabled(viewModel.currentTrack == nil)
            
            // Next button
            Button {
                Task {
                    do {
                        try await viewModel.playNext()
                    } catch {
                        Logger.userInterface.error("Play next failed: \(error.localizedDescription, privacy: .public)")
                    }
                }
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title2)
            }
            .disabled(viewModel.currentTrack == nil)
        }
    }
    
    // MARK: - Volume Control View
    
    var volumeControlView: some View {
        HStack(spacing: 12) {
            // Mute button
            Button {
                viewModel.toggleMute()
            } label: {
                Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.fill")
                    .foregroundColor(viewModel.isMuted ? .red : .secondary)
            }
            .buttonStyle(.plain)
            
            Slider(
                value: $viewModel.volume,
                in: 0.0...1.0
            )
            .disabled(viewModel.isMuted)
            .onChange(of: viewModel.volume) { _, newValue in
                Logger.userInterface.debug("Volume changed to \(newValue, privacy: .public)")
            }
            
            Image(systemName: "speaker.wave.3.fill")
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Advanced Controls View
    
    var advancedControlsView: some View {
        HStack(spacing: 20) {
            // Replay button
            Button {
                Task {
                    do {
                        try await viewModel.replay()
                    } catch {
                        Logger.userInterface.error("Replay failed: \(error.localizedDescription, privacy: .public)")
                    }
                }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title3)
            }
            .disabled(viewModel.currentTrack == nil)
            .help("Replay current track")
            
            // Skip backward button
            Button {
                Task {
                    do {
                        try await viewModel.skipBackward()
                    } catch {
                        Logger.userInterface.error(
                            "Skip backward failed: \(error.localizedDescription, privacy: .public)"
                        )
                    }
                }
            } label: {
                Image(systemName: "gobackward.10")
                    .font(.title3)
            }
            .disabled(viewModel.currentTrack == nil)
            .help("Skip backward 10 seconds")
            
            // Skip forward button
            Button {
                Task {
                    do {
                        try await viewModel.skipForward()
                    } catch {
                        Logger.userInterface.error(
                            "Skip forward failed: \(error.localizedDescription, privacy: .public)"
                        )
                    }
                }
            } label: {
                Image(systemName: "goforward.10")
                    .font(.title3)
            }
            .disabled(viewModel.currentTrack == nil)
            .help("Skip forward 10 seconds")
            
            // Loop mode button
            Button {
                viewModel.toggleLoopMode()
            } label: {
                Group {
                    switch viewModel.loopMode {
                    case .none:
                        Image(systemName: "repeat")
                            .foregroundColor(.secondary)
                    case .track:
                        Image(systemName: "repeat.1")
                            .foregroundColor(.blue)
                    case .queue:
                        Image(systemName: "repeat")
                            .foregroundColor(.blue)
                    }
                }
                .font(.title3)
            }
            .help(loopModeHelpText)
        }
    }
    
    var loopModeHelpText: String {
        switch viewModel.loopMode {
        case .none:
            return "Loop: Off"
        case .track:
            return "Loop: Track"
        case .queue:
            return "Loop: Queue"
        }
    }
    
    // MARK: - Playback State Indicator View
    
    var playbackStateIndicatorView: some View {
        HStack(spacing: 8) {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Loading...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if viewModel.isPlaying {
                Image(systemName: "waveform")
                    .foregroundColor(.green)
                Text("Playing")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if viewModel.isPaused {
                Image(systemName: "pause.circle")
                    .foregroundColor(.orange)
                Text("Paused")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "stop.circle")
                    .foregroundColor(.gray)
                Text("Stopped")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let error = viewModel.lastError {
                Spacer()
                Text("Error: \(error.localizedDescription)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

#Preview {
    NowPlayingView()
}
