//
//  ExpandedPlayerAdditionalControls.swift
//  Audientia
//
//  Additional controls (shuffle, loop, volume) for expanded player bar
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Shared
import SwiftUI

/// Additional controls section for expanded player bar
struct ExpandedPlayerAdditionalControls: View {
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    var onMinimize: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 8) {
            // Minimize button removed - using title bar minimize button instead
            shuffleButton
            loopButton
            volumeControl
        }
    }
    
    private var shuffleButton: some View {
        Button("Shuffle", systemImage: "shuffle") {
            nowPlayingViewModel.toggleShuffle()
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 14))
        .foregroundColor(nowPlayingViewModel.isShuffleEnabled ? Color.accentColor : .primary)
        .buttonStyle(.plain)
        .accessibilityLabel("Shuffle")
        .accessibilityHint(
            nowPlayingViewModel.isShuffleEnabled
                ? "Shuffle is enabled. Press to disable."
                : "Shuffle is disabled. Press to enable."
        )
        .accessibilityAddTraits(nowPlayingViewModel.isShuffleEnabled ? [.isSelected, .isButton] : .isButton)
        .accessibilityValue(nowPlayingViewModel.isShuffleEnabled ? "Enabled" : "Disabled")
    }
    
    private var loopButton: some View {
        Button("Loop", systemImage: loopIconName) {
            nowPlayingViewModel.toggleLoopMode()
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 14))
        .foregroundColor(nowPlayingViewModel.loopMode != .none ? Color.accentColor : .primary)
        .buttonStyle(.plain)
        .accessibilityLabel("Loop mode")
        .accessibilityHint(loopAccessibilityHint)
        .accessibilityAddTraits(nowPlayingViewModel.loopMode != .none ? [.isSelected, .isButton] : .isButton)
        .accessibilityValue(loopAccessibilityValue)
    }
    
    private var loopIconName: String {
        switch nowPlayingViewModel.loopMode {
        case .none, .queue: return "repeat"
        case .track: return "repeat.1"
        }
    }
    
    private var loopAccessibilityHint: String {
        switch nowPlayingViewModel.loopMode {
        case .none:
            return "Loop is disabled. Press to enable loop mode."
        case .track:
            return "Loop track is enabled. Press to change loop mode."
        case .queue:
            return "Loop queue is enabled. Press to disable loop mode."
        }
    }
    
    private var loopAccessibilityValue: String {
        switch nowPlayingViewModel.loopMode {
        case .none: return "Disabled"
        case .track: return "Loop track"
        case .queue: return "Loop queue"
        }
    }
    
    private var volumeControl: some View {
        HStack(spacing: 4) {
            Button("Mute", systemImage: nowPlayingViewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill") {
                nowPlayingViewModel.toggleMute()
            }
            .labelStyle(.iconOnly)
            .font(.system(size: 12))
            .buttonStyle(.plain)
            .accessibilityLabel("Mute")
            .accessibilityHint(nowPlayingViewModel.isMuted ? "Audio is muted. Press to unmute." : "Press to mute audio")
            .accessibilityAddTraits(nowPlayingViewModel.isMuted ? [.isSelected, .isButton] : .isButton)
            .accessibilityValue(nowPlayingViewModel.isMuted ? "Muted" : "Unmuted")
            
            Slider(
                value: Binding(
                    get: { Double(nowPlayingViewModel.volume) },
                    set: { nowPlayingViewModel.volume = Float($0) }
                ),
                in: 0...1
            )
            .frame(width: 100)
            .accessibilityLabel("Volume")
            .accessibilityHint("Adjust playback volume")
            .accessibilityValue("\(Int(nowPlayingViewModel.volume * 100)) percent")
        }
    }
}
