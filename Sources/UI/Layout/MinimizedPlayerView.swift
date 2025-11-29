//
//  MinimizedPlayerView.swift
//  Audientia
//
//  Minimized floating player window
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import DataLayer
import Shared
import SwiftUI

public struct MinimizedPlayerView: View {
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    let onRestore: () -> Void
    
    @State private var artworkImage: NSImage?
    @State private var isLoadingArtwork = false
    
    private let artworkExtractor: ArtworkExtractorProtocol = HeuristicArtworkExtractor()
    
    public var body: some View {
        VStack(spacing: 0) {
            // Window controls and restore button
            HStack {
                Spacer()
                Button(action: onRestore, label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                })
                .buttonStyle(.plain)
                .help("Restore")
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
            
            // Compact player content
            HStack(spacing: 12) {
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
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                            )
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                
                // Track info or app name
                VStack(alignment: .leading, spacing: 2) {
                    if let track = nowPlayingViewModel.currentTrack {
                        Text(track.title)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Text(track.artist)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
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
                
                Spacer()
                
                // Playback controls - centered
                HStack(spacing: 8) {
                    Button(action: { Task { try? await nowPlayingViewModel.playPrevious() } }, label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 12))
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
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                    })
                    .buttonStyle(.plain)
                    
                    Button(action: { Task { await nowPlayingViewModel.stop() } }, label: {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.primary)
                    })
                    .buttonStyle(.plain)
                    
                    Button(action: { Task { try? await nowPlayingViewModel.playNext() } }, label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.primary)
                    })
                    .buttonStyle(.plain)
                    .disabled(nowPlayingViewModel.queue.count <= 1)
                }
                
                Spacer()
                
                // Menu/playlist icon
                Button(action: {}, label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                })
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(height: 60)
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
                            Color.orange.opacity(0.1)
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
                        : Color.orange.opacity(0.3),
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
    
    private func loadArtwork() {
        guard let track = nowPlayingViewModel.currentTrack else {
            artworkImage = nil
            return
        }
        
        guard !isLoadingArtwork else { return }
        isLoadingArtwork = true
        
        Task {
            if let artwork = await artworkExtractor.extractArtwork(for: track) {
                await MainActor.run {
                    artworkImage = NSImage(data: artwork.data)
                    isLoadingArtwork = false
                }
            } else {
                await MainActor.run {
                    artworkImage = nil
                    isLoadingArtwork = false
                }
            }
        }
    }
}
