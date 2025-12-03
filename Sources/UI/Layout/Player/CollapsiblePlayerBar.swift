//
//  CollapsiblePlayerBar.swift
//  Audientia
//
//  Collapsible player controls bar with expanded and collapsed states
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import AVFoundation
import Shared
import SwiftUI

/// Collapsible player bar with two states:
/// - Expanded (70px): Full player with album art, track info, seek bar, and controls
/// - Collapsed (32px): Single line with scrolling track info, compact seek bar, and icon controls
struct CollapsiblePlayerBar: View {
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    @Binding var isExpanded: Bool
    var onMinimize: (() -> Void)?
    
    @ObservedObject private var appSettings = AppSettings.shared
    
    @State private var seekPosition: TimeInterval = 0.0
    @State private var isSeeking: Bool = false
    @State private var artworkImage: NSImage?
    @State private var isLoadingArtwork = false
    
    /// Height when expanded
    static let expandedHeight: CGFloat = 70
    
    /// Height when collapsed
    static let collapsedHeight: CGFloat = 32
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            if isExpanded {
                expandedContent
                    .frame(height: Self.expandedHeight)
            } else {
                CompactPlayerControls(
                    nowPlayingViewModel: nowPlayingViewModel,
                    onExpand: { isExpanded = true }
                )
                .frame(height: Self.collapsedHeight)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
        .onChange(of: nowPlayingViewModel.currentPosition) { _, newValue in
            if !isSeeking {
                seekPosition = newValue
            }
        }
        .onChange(of: nowPlayingViewModel.currentTrack?.id) { _, _ in
            seekPosition = nowPlayingViewModel.currentPosition
            loadArtwork()
        }
        .onAppear {
            seekPosition = nowPlayingViewModel.currentPosition
            loadArtwork()
        }
    }
    
    // MARK: - Expanded Content
    
    private var expandedContent: some View {
        HStack(spacing: 16) {
            // Track Info with Album Art
            trackInfoSection
                .frame(width: 280, alignment: .leading)
            
            Spacer()
            
            // Seek bar and playback controls
            VStack(spacing: 4) {
                seekBarView
                    .frame(width: 320)
                
                playbackControlsView
            }
            
            Spacer()
            
            // Additional controls
            additionalControlsSection
                .frame(width: 200, alignment: .trailing)
            
            // Collapse button
            collapseButton
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Track Info Section
    
    private var trackInfoSection: some View {
        Group {
            if let track = nowPlayingViewModel.currentTrack {
                HStack(spacing: 12) {
                    // Album art
                    albumArtView
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    // Track info
                    VStack(alignment: .leading, spacing: 4) {
                        ScrollingTextView(
                            text: track.title,
                            font: .system(size: 13, weight: .medium),
                            foregroundColor: .primary,
                            scrollSpeed: appSettings.trackInfoScrollSpeed,
                            frameWidth: 200
                        )
                        ScrollingTextView(
                            text: "\(track.artist) - \(track.album)",
                            font: .system(size: 11),
                            foregroundColor: .secondary,
                            scrollSpeed: appSettings.trackInfoScrollSpeed,
                            frameWidth: 200
                        )
                    }
                    .frame(maxWidth: 200)
                }
            } else {
                Text("No track selected")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var albumArtView: some View {
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
    }
    
    // MARK: - Seek Bar
    
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
    
    // MARK: - Playback Controls
    
    private var playbackControlsView: some View {
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
    }
    
    private var stopButton: some View {
        Button("Stop", systemImage: "stop.fill") {
            Task { await nowPlayingViewModel.stop() }
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 14))
        .buttonStyle(.plain)
    }
    
    private var nextButton: some View {
        Button("Next", systemImage: "forward.fill") {
            Task { try? await nowPlayingViewModel.playNext() }
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 14))
        .buttonStyle(.plain)
        .disabled(nowPlayingViewModel.queue.count <= 1)
    }
    
    // MARK: - Additional Controls
    
    private var additionalControlsSection: some View {
        HStack(spacing: 8) {
            if onMinimize != nil {
                minimizeButton
            }
            shuffleButton
            loopButton
            volumeControl
        }
    }
    
    private var minimizeButton: some View {
        Button("Minimize", systemImage: "minus.circle.fill") {
            onMinimize?()
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 14))
        .foregroundColor(.secondary)
        .buttonStyle(.plain)
        .help("Minimize to Player")
    }
    
    private var shuffleButton: some View {
        Button("Shuffle", systemImage: "shuffle") {
            nowPlayingViewModel.toggleShuffle()
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 14))
        .foregroundColor(nowPlayingViewModel.isShuffleEnabled ? Color.accentColor : .primary)
        .buttonStyle(.plain)
    }
    
    private var loopButton: some View {
        Button("Loop", systemImage: loopIconName) {
            nowPlayingViewModel.toggleLoopMode()
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 14))
        .foregroundColor(nowPlayingViewModel.loopMode != .none ? Color.accentColor : .primary)
        .buttonStyle(.plain)
    }
    
    private var volumeControl: some View {
        HStack(spacing: 4) {
            Button("Mute", systemImage: nowPlayingViewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill") {
                nowPlayingViewModel.toggleMute()
            }
            .labelStyle(.iconOnly)
            .font(.system(size: 12))
            .buttonStyle(.plain)
            
            Slider(
                value: Binding(
                    get: { Double(nowPlayingViewModel.volume) },
                    set: { nowPlayingViewModel.volume = Float($0) }
                ),
                in: 0...1
            )
            .frame(width: 100)
        }
    }
    
    private var loopIconName: String {
        switch nowPlayingViewModel.loopMode {
        case .none, .queue: return "repeat"
        case .track: return "repeat.1"
        }
    }
    
    // MARK: - Collapse Button
    
    private var collapseButton: some View {
        Button("Collapse", systemImage: "chevron.down") {
            isExpanded = false
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 10, weight: .semibold))
        .foregroundColor(.secondary)
        .frame(width: 20, height: 20)
        .contentShape(Rectangle())
        .buttonStyle(.plain)
        .keyboardShortcut("p", modifiers: .command)
        .help("Collapse player (⌘P)")
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
    
    /// Extracts artwork for the given track
    private func extractArtworkImage(for track: Track) async -> NSImage? {
        let fileURL = URL(fileURLWithPath: track.filePath)

        // Try embedded artwork via AVFoundation
        if let embeddedData = await extractEmbeddedArtworkData(from: fileURL),
           let image = NSImage(data: embeddedData) {
            return image
        }

        // Fallback to sidecar files
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
                
                if commonKey == .commonKeyArtwork,
                   let data = try? await item.load(.dataValue) {
                    return data
                }
                
                if let idRaw = identifier?.rawValue {
                    if idRaw.contains("covr"),
                       let data = try? await item.load(.dataValue) {
                        return data
                    }
                    
                    if idRaw == "APIC" || idRaw.contains("PICTURE"),
                       let data = try? await item.load(.dataValue) {
                        return data
                    }
                }
            }
        } catch {
            // Fall back to sidecar files
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

#if DEBUG
import AudioCore

struct CollapsiblePlayerBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CollapsiblePlayerBar(
                nowPlayingViewModel: NowPlayingViewModel(audioEngine: PreviewMockAudioEngine()),
                isExpanded: .constant(true),
                onMinimize: nil
            )
            .frame(width: 800)
            
            CollapsiblePlayerBar(
                nowPlayingViewModel: NowPlayingViewModel(audioEngine: PreviewMockAudioEngine()),
                isExpanded: .constant(false),
                onMinimize: nil
            )
            .frame(width: 800)
        }
        .padding()
    }
}

private class PreviewMockAudioEngine: AudioEngineProtocol {
    var currentTrack: Track?
    var currentPosition: TimeInterval = 0
    var duration: TimeInterval = 0
    var isPlaying: Bool = false
    var volume: Float = 1.0
    var isMuted: Bool = false
    
    func loadFile(url: URL) async throws {}
    func play() async throws {}
    func pause() async {}
    func stop() async {}
    func seek(to position: TimeInterval) async {}
    func setVolume(_ volume: Float) {}
}
#endif
