//
//  ExpandedPlayerTransportControls.swift
//  Audientia
//
//  Transport controls for expanded player bar
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Shared
import SwiftUI

/// Transport controls for expanded player bar
struct ExpandedPlayerTransportControls: View {
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    
    var body: some View {
        HStack(spacing: 8) {
            previousButton
            playPauseButton
            stopButton
            nextButton
        }
    }
    
    @FocusState private var previousFocused: Bool
    @FocusState private var playPauseFocused: Bool
    @FocusState private var stopFocused: Bool
    @FocusState private var nextFocused: Bool
    
    private var previousButton: some View {
        Button("Previous", systemImage: "backward.fill") {
            Task { try? await nowPlayingViewModel.playPrevious() }
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 14))
        .buttonStyle(.plain)
        .focused($previousFocused)
        .keyboardActivation(
            isFocused: $previousFocused,
            onEnter: {
                Task { try? await nowPlayingViewModel.playPrevious() }
            }
        )
        .overlay(
            Circle()
                .stroke(
                    previousFocused ? Color.accentColor : Color.clear,
                    lineWidth: previousFocused ? 2 : 0
                )
                .padding(-4)
        )
        .disabled(nowPlayingViewModel.queue.count <= 1)
        .accessibilityLabel("Previous track")
        .accessibilityHint("Plays the previous track in the queue")
        .accessibilityAddTraits(.isButton)
    }
    
    private var playPauseButton: some View {
        Button(nowPlayingViewModel.isPlaying ? "Pause" : "Play",
               systemImage: nowPlayingViewModel.isPlaying ? "pause.fill" : "play.fill") {
            playPauseAction()
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 18, weight: .semibold))
        .foregroundColor(Color.accentColor)
        .buttonStyle(.plain)
        .focused($playPauseFocused)
        .keyboardActivation(
            isFocused: $playPauseFocused,
            onEnter: playPauseAction,
            onSpace: playPauseAction
        )
        .overlay(
            Circle()
                .stroke(
                    playPauseFocused ? Color.accentColor : Color.clear,
                    lineWidth: playPauseFocused ? 2 : 0
                )
                .padding(-4)
        )
        .accessibilityLabel(nowPlayingViewModel.isPlaying ? "Pause" : "Play")
        .accessibilityHint(nowPlayingViewModel.isPlaying ? "Pauses playback" : "Starts playback")
        .accessibilityAddTraits(.isButton)
    }
    
    private func playPauseAction() {
        Task {
            if nowPlayingViewModel.isPlaying {
                await nowPlayingViewModel.pause()
            } else {
                try? await nowPlayingViewModel.play()
            }
        }
    }
    
    private var stopButton: some View {
        Button("Stop", systemImage: "stop.fill") {
            Task { await nowPlayingViewModel.stop() }
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 14))
        .buttonStyle(.plain)
        .focused($stopFocused)
        .keyboardActivation(
            isFocused: $stopFocused,
            onEnter: {
                Task { await nowPlayingViewModel.stop() }
            }
        )
        .overlay(
            Circle()
                .stroke(
                    stopFocused ? Color.accentColor : Color.clear,
                    lineWidth: stopFocused ? 2 : 0
                )
                .padding(-4)
        )
        .accessibilityLabel("Stop")
        .accessibilityHint("Stops playback and resets to beginning")
        .accessibilityAddTraits(.isButton)
    }
    
    private var nextButton: some View {
        Button("Next", systemImage: "forward.fill") {
            Task { try? await nowPlayingViewModel.playNext() }
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 14))
        .buttonStyle(.plain)
        .focused($nextFocused)
        .keyboardActivation(
            isFocused: $nextFocused,
            onEnter: {
                Task { try? await nowPlayingViewModel.playNext() }
            }
        )
        .overlay(
            Circle()
                .stroke(
                    nextFocused ? Color.accentColor : Color.clear,
                    lineWidth: nextFocused ? 2 : 0
                )
                .padding(-4)
        )
        .disabled(nowPlayingViewModel.queue.count <= 1)
        .accessibilityLabel("Next track")
        .accessibilityHint("Plays the next track in the queue")
        .accessibilityAddTraits(.isButton)
    }
}
