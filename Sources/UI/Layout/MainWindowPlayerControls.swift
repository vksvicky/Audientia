//
//  MainWindowPlayerControls.swift
//  Audientia
//
//  Player controls component for the main window
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Shared
import SwiftUI

struct MainWindowPlayerControls: View {
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    @Binding var showVisualizer: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Track Info
            if let track = nowPlayingViewModel.currentTrack {
                HStack(spacing: 12) {
                    // Album art placeholder
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(track.title)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)
                        Text(track.artist)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            } else {
                Text("No track selected")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Playback Controls
            HStack(spacing: 8) {
                Button(action: { Task { try? await nowPlayingViewModel.playPrevious() } }, label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 14))
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
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color("AccentColor"))
                })
                .buttonStyle(.plain)
                
                Button(action: { Task { await nowPlayingViewModel.stop() } }, label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 14))
                })
                .buttonStyle(.plain)
                
                Button(action: { Task { try? await nowPlayingViewModel.playNext() } }, label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 14))
                })
                .buttonStyle(.plain)
                .disabled(nowPlayingViewModel.queue.count <= 1)
            }
            
            Spacer()
            
            // Additional Controls
            HStack(spacing: 8) {
                Button(action: {
                    Task {
                        nowPlayingViewModel.toggleShuffle()
                    }
                }, label: {
                    Image(systemName: "shuffle")
                        .font(.system(size: 14))
                        .foregroundColor(nowPlayingViewModel.isShuffleEnabled ? Color("AccentColor") : .primary)
                })
                .buttonStyle(.plain)
                
                Button(action: {
                    Task {
                        nowPlayingViewModel.toggleLoopMode()
                    }
                }, label: {
                    Group {
                        switch nowPlayingViewModel.loopMode {
                        case .none:
                            Image(systemName: "repeat")
                        case .track:
                            Image(systemName: "repeat.1")
                        case .queue:
                            Image(systemName: "repeat")
                        }
                    }
                    .font(.system(size: 14))
                    .foregroundColor(nowPlayingViewModel.loopMode != .none ? Color("AccentColor") : .primary)
                })
                .buttonStyle(.plain)
                
                Button(action: {
                    showVisualizer.toggle()
                }, label: {
                    Image(systemName: "waveform")
                        .font(.system(size: 14))
                        .foregroundColor(showVisualizer ? Color("AccentColor") : .primary)
                })
                .buttonStyle(.plain)
                
                // Volume control
                HStack(spacing: 4) {
                    Button(action: {
                        Task {
                            nowPlayingViewModel.toggleMute()
                        }
                    }, label: {
                        Image(systemName: nowPlayingViewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 12))
                    })
                    .buttonStyle(.plain)
                    
                    Slider(value: Binding(
                        get: { Double(nowPlayingViewModel.volume) },
                        set: { nowPlayingViewModel.volume = Float($0) }
                    ), in: 0...1)
                    .frame(width: 100)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}
