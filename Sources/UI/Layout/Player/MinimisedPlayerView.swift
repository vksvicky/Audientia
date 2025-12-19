//
//  MinimisedPlayerView.swift
//  Audientia
//
//  Minimised floating player window
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import AVFoundation
import Shared
import SwiftUI

public struct MinimisedPlayerView: View {
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    let onRestore: () -> Void
    
    @State private var artworkImage: NSImage?
    @State private var isLoadingArtwork = false
    
    public var body: some View {
        VStack(spacing: 0) {
            // Compact player content (maximize button is in title bar)
            VStack(spacing: 4) {
                // Top row: Track info and controls
                HStack(spacing: 8) {
                    // Album art or placeholder
                    Group {
                        if let artworkImage = artworkImage {
                            Image(nsImage: artworkImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Image(systemName: "music.note")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                )
                        }
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    // Track info or app name
                    VStack(alignment: .leading, spacing: 2) {
                        if let track = nowPlayingViewModel.currentTrack {
                            ScrollingTextView(
                                text: track.title,
                                font: .system(size: 11, weight: .medium),
                                foregroundColor: .primary,
                                scrollSpeed: AppSettings.shared.trackInfoScrollSpeed,
                                frameWidth: 140
                            )
                            ScrollingTextView(
                                text: track.artist,
                                font: .system(size: 9),
                                foregroundColor: .secondary,
                                scrollSpeed: AppSettings.shared.trackInfoScrollSpeed,
                                frameWidth: 140
                            )
                        } else {
                            Text("Audientia")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("No track selected")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(width: 140, alignment: .leading)
                    
                    Spacer(minLength: 2)
                    
                    // Playback controls
                    HStack(spacing: 4) {
                        Button(action: { Task { try? await nowPlayingViewModel.playPrevious() } }, label: {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.primary)
                        })
                        .buttonStyle(.plain)
                        .disabled(nowPlayingViewModel.queue.count <= 1)
                        
                        Button(action: {
                            Task {
                                if nowPlayingViewModel.isPlaying {
                                    await nowPlayingViewModel.pause()
                                } else {
                                    try? await nowPlayingViewModel.play()
                                }
                            }
                        }, label: {
                            Image(systemName: nowPlayingViewModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color("AccentColor"))
                        })
                        .buttonStyle(.plain)
                        
                        Button(action: { Task { await nowPlayingViewModel.stop() } }, label: {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.primary)
                        })
                        .buttonStyle(.plain)
                        
                        Button(action: { Task { try? await nowPlayingViewModel.playNext() } }, label: {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.primary)
                        })
                        .buttonStyle(.plain)
                        .disabled(nowPlayingViewModel.queue.count <= 1)
                        
                        // Playback Speed Control (compact for minimized view)
                        Menu {
                            ForEach(PlaybackSpeed.allCases, id: \.self) { speed in
                                Button {
                                    nowPlayingViewModel.playbackSpeed = speed
                                } label: {
                                    HStack {
                                        Text(speed.displayName)
                                        Spacer()
                                        if speed == nowPlayingViewModel.playbackSpeed {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 11, weight: .semibold))
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "speedometer")
                                    .font(.system(size: 10))
                                Text(nowPlayingViewModel.playbackSpeed.displayName)
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.accentColor.opacity(0.1))
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Playback speed: \(nowPlayingViewModel.playbackSpeed.displayName)")
                        
                        // Gain Control Button
                        Button(action: {
                            nowPlayingViewModel.toggleGainControl()
                        }, label: {
                            Image(systemName: "waveform")
                                .font(.system(size: 11))
                                .foregroundColor(
                                    nowPlayingViewModel.isGainControlEnabled
                                        ? Color.accentColor
                                        : .primary
                                )
                        })
                        .buttonStyle(.plain)
                        .frame(width: 16, height: 16) // Fixed frame to prevent alignment shifts
                        .accessibilityLabel("Gain Control")
                        .accessibilityHint(
                            nowPlayingViewModel.isGainControlEnabled
                                ? "Gain control is enabled. Press to disable."
                                : "Gain control is disabled. Press to enable."
                        )
                        .accessibilityAddTraits(
                            nowPlayingViewModel.isGainControlEnabled
                                ? [.isSelected, .isButton]
                                : .isButton
                        )
                        .accessibilityValue(
                            nowPlayingViewModel.isGainControlEnabled ? "Enabled" : "Disabled"
                        )
                        
                        // Volume Control Button
                        volumeControlButton
                    }
                }
                
                // Bottom row: Seek bar
                HStack(spacing: 8) {
                    Spacer()
                        .frame(width: 50 + 8) // Match artwork width + spacing
                    
                    VStack(spacing: 2) {
                        Slider(
                            value: Binding(
                                get: { nowPlayingViewModel.currentPosition },
                                set: { newValue in
                                    Task {
                                        await nowPlayingViewModel.seek(to: newValue)
                                    }
                                }
                            ),
                            in: 0...max(nowPlayingViewModel.duration, 1.0)
                        )
                        .controlSize(.mini)
                        .disabled(nowPlayingViewModel.duration <= 0)
                        
                        HStack {
                            Text(formatTime(nowPlayingViewModel.currentPosition))
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                            
                            Spacer()
                            
                            Text(formatTime(nowPlayingViewModel.duration))
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 400, height: 80)
        .background(
            Group {
                if nowPlayingViewModel.currentTrack != nil {
                    Color(NSColor.controlBackgroundColor)
                } else {
                    // More vibrant background when no track is playing
                    LinearGradient(
                        colors: [
                            Color(NSColor.controlBackgroundColor),
                            Color("AccentColor").opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
        )
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    nowPlayingViewModel.currentTrack != nil
                        ? Color.white.opacity(0.1)
                        : Color("AccentColor").opacity(0.3),
                    lineWidth: 1
                )
        )
        .onChange(of: nowPlayingViewModel.currentTrack?.id) {
            loadArtwork()
        }
        .onAppear {
            loadArtwork()
        }
    }
    
    // MARK: - Volume Control
    
    @State private var isVolumePopoverPresented = false
    
    private var volumeControlButton: some View {
        Button(action: {
            isVolumePopoverPresented.toggle()
        }, label: {
            Image(systemName: nowPlayingViewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .font(.system(size: 11))
                .foregroundColor(nowPlayingViewModel.isMuted ? .red : .primary)
        })
        .buttonStyle(.plain)
        .frame(width: 16, height: 16) // Fixed frame to prevent alignment shifts
        .popover(isPresented: $isVolumePopoverPresented, attachmentAnchor: .point(.bottom), arrowEdge: .bottom) {
            MinimisedVolumePopoverView(nowPlayingViewModel: nowPlayingViewModel)
        }
        .accessibilityLabel("Volume")
        .accessibilityHint("Click to adjust volume")
        .accessibilityValue("\(Int(nowPlayingViewModel.volume * 100)) percent")
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite && !time.isNaN else { return "0:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func loadArtwork() {
        guard let track = nowPlayingViewModel.currentTrack else {
            artworkImage = nil
            return
        }
        
        guard !isLoadingArtwork else { return }
        isLoadingArtwork = true
        
        Task {
            let image = await MinimisedPlayerArtworkHelper.extractArtworkImage(for: track)
            await MainActor.run {
                artworkImage = image
                isLoadingArtwork = false
            }
        }
    }
}
