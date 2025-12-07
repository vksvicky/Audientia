//
//  PlaybackSpeedControl.swift
//  Audientia
//
//  Playback speed control component
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import Shared
import SwiftUI

/// Playback speed control component
/// BDD: As a user, I want to control playback speed from 0.5x to 4x
@MainActor
public struct PlaybackSpeedControl: View {
    @Binding var playbackSpeed: PlaybackSpeed
    
    public init(playbackSpeed: Binding<PlaybackSpeed>) {
        self._playbackSpeed = playbackSpeed
    }
    
    public var body: some View {
        Menu {
            ForEach(PlaybackSpeed.allCases, id: \.self) { speed in
                Button {
                    playbackSpeed = speed
                } label: {
                    HStack {
                        Text(speed.displayName)
                        Spacer()
                        if speed == playbackSpeed {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .semibold))
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "speedometer")
                    .font(.system(size: 12))
                Text(playbackSpeed.displayName)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.accentColor.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Playback speed: \(playbackSpeed.displayName)")
        .accessibilityHint("Tap to change playback speed")
    }
}

#Preview {
    PlaybackSpeedControl(playbackSpeed: .constant(.normal))
        .padding()
}
