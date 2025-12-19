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
                                frameWidth: 120
                            )
                            ScrollingTextView(
                                text: track.artist,
                                font: .system(size: 9),
                                foregroundColor: .secondary,
                                scrollSpeed: AppSettings.shared.trackInfoScrollSpeed,
                                frameWidth: 120
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
                    .frame(width: 120, alignment: .leading)
                    
                    Spacer(minLength: 4)
                    
                    // Playback controls
                    HStack(spacing: 6) {
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
                        
                        // Playback Speed Control
                        PlaybackSpeedControl(playbackSpeed: $nowPlayingViewModel.playbackSpeed)
                        
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
