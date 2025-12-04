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
    
    private var previousButton: some View {
        Button("Previous", systemImage: "backward.fill") {
            Task { try? await nowPlayingViewModel.playPrevious() }
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 14))
        .buttonStyle(.plain)
        .disabled(nowPlayingViewModel.queue.count <= 1)
        .accessibilityLabel("Previous track")
        .accessibilityHint("Plays the previous track in the queue")
        .accessibilityAddTraits(.isButton)
    }
    
    private var playPauseButton: some View {
        Button(nowPlayingViewModel.isPlaying ? "Pause" : "Play",
               systemImage: nowPlayingViewModel.isPlaying ? "pause.fill" : "play.fill") {
            Task {
                if nowPlayingViewModel.isPlaying {
                    await nowPlayingViewModel.pause()
                } else {
                    try? await nowPlayingViewModel.play()
                }
            }
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 18, weight: .semibold))
        .foregroundColor(Color.accentColor)
        .buttonStyle(.plain)
        .accessibilityLabel(nowPlayingViewModel.isPlaying ? "Pause" : "Play")
        .accessibilityHint(nowPlayingViewModel.isPlaying ? "Pauses playback" : "Starts playback")
        .accessibilityAddTraits(.isButton)
    }
    
    private var stopButton: some View {
        Button("Stop", systemImage: "stop.fill") {
            Task { await nowPlayingViewModel.stop() }
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 14))
        .buttonStyle(.plain)
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
        .disabled(nowPlayingViewModel.queue.count <= 1)
        .accessibilityLabel("Next track")
        .accessibilityHint("Plays the next track in the queue")
        .accessibilityAddTraits(.isButton)
    }
}
