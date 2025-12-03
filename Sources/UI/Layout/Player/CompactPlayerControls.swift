//
//  CompactPlayerControls.swift
//  Audientia
//
//  Single-line compact player controls for collapsed player bar
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Shared
import SwiftUI

/// Compact single-line player controls for collapsed state (32px height)
/// Contains: Scrolling track info | Seek bar | Transport controls
struct CompactPlayerControls: View {
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    var onExpand: () -> Void
    
    @State private var seekPosition: TimeInterval = 0.0
    @State private var isSeeking: Bool = false
    
    /// Height of the compact player bar
    static let height: CGFloat = 32
    
    var body: some View {
        HStack(spacing: 12) {
            // Scrolling track info
            trackInfoView
                .frame(minWidth: 150, maxWidth: 250)
            
            // Compact seek bar
            compactSeekBar
                .frame(minWidth: 100, maxWidth: .infinity)
            
            // Compact transport controls
            transportControls
            
            // Expand button
            expandButton
        }
        .padding(.horizontal, 12)
        .frame(height: Self.height)
        .background(Color(NSColor.controlBackgroundColor))
        .onChange(of: nowPlayingViewModel.currentPosition) { _, newValue in
            if !isSeeking {
                seekPosition = newValue
            }
        }
    }
    
    // MARK: - Track Info (Scrolling)
    
    private var trackInfoView: some View {
        Group {
            if let track = nowPlayingViewModel.currentTrack {
                ScrollingTextView(
                    text: "\(track.title) - \(track.artist)",
                    font: .system(size: 12),
                    foregroundColor: .primary,
                    scrollSpeed: 30.0,
                    frameWidth: 200
                )
            } else {
                Text("No track playing")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Compact Seek Bar
    
    private var compactSeekBar: some View {
        HStack(spacing: 6) {
            Slider(
                value: $seekPosition,
                in: 0...max(nowPlayingViewModel.duration, 1.0),
                onEditingChanged: { editing in
                    isSeeking = editing
                    if !editing {
                        Task {
                            await nowPlayingViewModel.seek(to: seekPosition)
                        }
                    }
                }
            )
            .controlSize(.mini)
            .disabled(nowPlayingViewModel.duration <= 0)
            
            Text(formatCompactTime())
                .font(.system(size: 10).monospacedDigit())
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .trailing)
        }
    }
    
    private func formatCompactTime() -> String {
        let current = isSeeking ? seekPosition : nowPlayingViewModel.currentPosition
        let total = nowPlayingViewModel.duration
        return "\(formatTime(current))/\(formatTime(total))"
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Transport Controls (Icons Only)
    
    private var transportControls: some View {
        HStack(spacing: 4) {
            previousButton
            playPauseButton
            nextButton
            
            Divider()
                .frame(height: 16)
                .padding(.horizontal, 4)
            
            shuffleButton
            loopButton
            
            Divider()
                .frame(height: 16)
                .padding(.horizontal, 4)
            
            muteButton
        }
    }
    
    private var previousButton: some View {
        Button("Previous", systemImage: "backward.fill") {
            Task { try? await nowPlayingViewModel.playPrevious() }
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 10))
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
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(Color.accentColor)
        .buttonStyle(.plain)
    }
    
    private var nextButton: some View {
        Button("Next", systemImage: "forward.fill") {
            Task { try? await nowPlayingViewModel.playNext() }
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 10))
        .buttonStyle(.plain)
        .disabled(nowPlayingViewModel.queue.count <= 1)
    }
    
    private var shuffleButton: some View {
        Button("Shuffle", systemImage: "shuffle") {
            nowPlayingViewModel.toggleShuffle()
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 10))
        .foregroundColor(nowPlayingViewModel.isShuffleEnabled ? Color.accentColor : .secondary)
        .buttonStyle(.plain)
    }
    
    private var loopButton: some View {
        Button("Loop", systemImage: loopIconName) {
            nowPlayingViewModel.toggleLoopMode()
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 10))
        .foregroundColor(nowPlayingViewModel.loopMode != .none ? Color.accentColor : .secondary)
        .buttonStyle(.plain)
    }
    
    private var muteButton: some View {
        Button("Mute", systemImage: nowPlayingViewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill") {
            nowPlayingViewModel.toggleMute()
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 10))
        .foregroundColor(nowPlayingViewModel.isMuted ? .red : .secondary)
        .buttonStyle(.plain)
    }
    
    private var loopIconName: String {
        switch nowPlayingViewModel.loopMode {
        case .none, .queue: return "repeat"
        case .track: return "repeat.1"
        }
    }
    
    // MARK: - Expand Button
    
    private var expandButton: some View {
        Button(action: onExpand) {
            Image(systemName: "chevron.up")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 20, height: 20)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut("p", modifiers: .command)
        .help("Expand player (⌘P)")
    }
}

#if DEBUG
import AudioCore

struct CompactPlayerControls_Previews: PreviewProvider {
    static var previews: some View {
        CompactPlayerControls(
            nowPlayingViewModel: NowPlayingViewModel(audioEngine: MockAudioEngine()),
            onExpand: {}
        )
        .frame(width: 800)
    }
}

private class MockAudioEngine: AudioEngineProtocol {
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
