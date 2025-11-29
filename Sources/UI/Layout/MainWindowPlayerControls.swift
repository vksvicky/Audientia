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
                Button(action: {}, label: {
                    Image(systemName: "shuffle")
                        .font(.system(size: 14))
                })
                .buttonStyle(.plain)
                
                Button(action: {}, label: {
                    Image(systemName: "repeat")
                        .font(.system(size: 14))
                })
                .buttonStyle(.plain)
                
                Button(action: {}, label: {
                    Image(systemName: "waveform")
                        .font(.system(size: 14))
                })
                .buttonStyle(.plain)
                
                // Volume control
                HStack(spacing: 4) {
                    Button(action: {}, label: {
                        Image(systemName: "speaker.wave.2.fill")
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
