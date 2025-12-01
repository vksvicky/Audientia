//
//  MainWindowPlayerControls.swift
//  Audientia
//
//  Player controls component for the main window
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import AVFoundation
import Shared
import SwiftUI

struct MainWindowPlayerControls: View {
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    @Binding var showVisualiser: Bool
    var onMinimize: (() -> Void)?
    @ObservedObject private var appSettings = AppSettings.shared
    
    @State private var seekPosition: TimeInterval = 0.0
    @State private var isSeeking: Bool = false
    @State private var artworkImage: NSImage?
    @State private var isLoadingArtwork = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Track Info - Fixed width to prevent layout shifts
            Group {
                if let track = nowPlayingViewModel.currentTrack {
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
                                            .font(.system(size: 20))
                                            .foregroundColor(.secondary)
                                    )
                            }
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            ScrollingTextView(
                                text: track.title,
                                font: .system(size: 13, weight: .medium),
                                foregroundColor: .primary,
                                scrollSpeed: appSettings.trackInfoScrollSpeed,
                                frameWidth: 200
                            )
                            ScrollingTextView(
                                text: track.artist,
                                font: .system(size: 11),
                                foregroundColor: .secondary,
                                scrollSpeed: appSettings.trackInfoScrollSpeed,
                                frameWidth: 200
                            )
                        }
                        .frame(maxWidth: 200) // Constrain text width
                    }
                } else {
                    Text("No track selected")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 280, alignment: .leading) // Fixed width for track info section
            
            Spacer()
            
            // Middle Section: Compact seek bar + playback controls
            VStack(spacing: 4) {
                // Seek bar with time labels (compact width, centered)
                seekBarView
                    .frame(width: 320)
                
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
            }
            
            Spacer()
            
            // Additional Controls - Fixed width to prevent layout shifts
            HStack(spacing: 8) {
                // Minimize button
                if let onMinimize = onMinimize {
                    Button(action: {
                        onMinimize()
                    }, label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    })
                    .buttonStyle(.plain)
                    .help("Minimize to Player")
                }
                
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
                    showVisualiser.toggle()
                }, label: {
                    Image(systemName: "waveform")
                        .font(.system(size: 14))
                        .foregroundColor(showVisualiser ? Color("AccentColor") : .primary)
                })
                .buttonStyle(.plain)
                
                // Volume control
                HStack(spacing: 4) {
                    Button(action: {
                        Task {
                            nowPlayingViewModel.toggleMute()
                        }
                    }, label: {
                        Image(
                            systemName: nowPlayingViewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"
                        )
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
            .frame(width: 200, alignment: .trailing) // Fixed width for additional controls
        }
        .padding(.horizontal, 16)
        .onChange(of: nowPlayingViewModel.currentPosition) { _, newValue in
            if !isSeeking {
                seekPosition = newValue
            }
        }
        .onChange(of: nowPlayingViewModel.currentTrack?.id) {
            seekPosition = nowPlayingViewModel.currentPosition
            loadArtwork()
        }
        .onAppear {
            seekPosition = nowPlayingViewModel.currentPosition
            loadArtwork()
        }
    }
    
    // MARK: - Seek Bar View
    
    private var seekBarView: some View {
        VStack(spacing: 2) {
            Slider(
                value: $seekPosition,
                in: 0...max(nowPlayingViewModel.duration, 1.0),
                onEditingChanged: { editing in
                    isSeeking = editing
                    if editing {
                        seekPosition = nowPlayingViewModel.currentPosition
                    } else {
                        Task {
                            await nowPlayingViewModel.seek(to: seekPosition)
                        }
                    }
                }
            )
            .controlSize(.small)
            .disabled(nowPlayingViewModel.duration <= 0)
            
            HStack {
                Text(formatTime(isSeeking ? seekPosition : nowPlayingViewModel.currentPosition))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                
                Spacer()
                
                Text(formatTime(nowPlayingViewModel.duration))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
        }
        .frame(height: 24)
    }
    
    // MARK: - Helper Functions
    
    private func formatTime(_ time: TimeInterval) -> String {
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
            let image = await extractArtworkImage(for: track)
            await MainActor.run {
                artworkImage = image
                isLoadingArtwork = false
            }
        }
    }

    /// Extracts artwork for the given track, preferring embedded artwork and falling back to sidecar images.
    private func extractArtworkImage(for track: Track) async -> NSImage? {
        let fileURL = URL(fileURLWithPath: track.filePath)

        // 1) Try embedded artwork via AVFoundation
        if let embeddedData = await extractEmbeddedArtworkData(from: fileURL),
           let image = NSImage(data: embeddedData) {
            return image
        }

        // 2) Fallback to sidecar files next to the track
        if let sidecarData = try? loadSidecarArtworkData(for: fileURL),
           let image = NSImage(data: sidecarData) {
            return image
        }

        return nil
    }

    private func extractEmbeddedArtworkData(from fileURL: URL) async -> Data? {
        let asset = AVURLAsset(url: fileURL)
        do {
            let metadata = try await asset.load(.metadata)

            for item in metadata {
                let commonKey = item.commonKey
                let identifier = item.identifier
                
                // Check for artwork by commonKey (works across all key spaces)
                if commonKey == .commonKeyArtwork,
                   let data = try? await item.load(.dataValue) {
                    return data
                }
                
                // Check for artwork by identifier (for files without commonKey mapping)
                if let idRaw = identifier?.rawValue {
                    // iTunes/M4A: identifier contains "covr"
                    if idRaw.contains("covr"),
                       let data = try? await item.load(.dataValue) {
                        return data
                    }
                    
                    // ID3/MP3: identifier is "APIC" or contains "PICTURE"
                    if idRaw == "APIC" || idRaw.contains("PICTURE"),
                       let data = try? await item.load(.dataValue) {
                        return data
                    }
                }
            }
        } catch {
            // Silently ignore errors and fall back to sidecar files
        }
        return nil
    }

    private func loadSidecarArtworkData(for fileURL: URL) throws -> Data? {
        let directoryURL = fileURL.deletingLastPathComponent()
        let baseName = fileURL.deletingPathExtension().lastPathComponent
        let candidateNames = [baseName, "cover", "folder", "front", "album"]
        let supportedExtensions = ["png", "jpg", "jpeg", "gif"]

        for name in candidateNames {
            for ext in supportedExtensions {
                let candidate = directoryURL.appendingPathComponent("\(name).\(ext)")
                if FileManager.default.fileExists(atPath: candidate.path),
                   let data = try? Data(contentsOf: candidate),
                   !data.isEmpty {
                    return data
                }
            }
        }
        return nil
    }
}
