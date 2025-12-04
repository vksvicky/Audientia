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
            nowPlayingViewModel: NowPlayingViewModel(audioEngine: CompactPlayerControlsPreviewAudioEngine()),
            onExpand: {}
        )
        .frame(width: 800)
    }
}

@MainActor
private final class CompactPlayerControlsPreviewAudioEngine: AudioEngineProtocol {
    // MARK: - Playback State
    var state: PlaybackState = .stopped
    var currentTrack: Track?
    var currentPosition: TimeInterval = 0
    var duration: TimeInterval = 0
    var queue: [Track] = []
    
    // MARK: - Volume / Mute
    var volume: Float = 1.0
    var isMuted: Bool = false
    
    // MARK: - Loop / Shuffle
    var loopMode: LoopMode = .none
    var isShuffleEnabled: Bool = false
    
    // MARK: - Visualiser
    let visualiser: AudioVisualiserProtocol = PreviewMockAudioVisualiser()
    
    // MARK: - Loading / Playback
    func loadTrack(_ track: Track) async throws {
        currentTrack = track
        duration = track.duration
        state = .stopped
    }
    
    func play() async throws {
        state = .playing
    }
    
    func pause() async {
        state = .paused
    }
    
    func stop() async {
        state = .stopped
        currentPosition = 0
    }
    
    func seek(to position: TimeInterval) async throws {
        currentPosition = max(0, min(position, duration))
    }
    
    // MARK: - Queue Navigation
    func addToQueue(_ track: Track) {
        queue.append(track)
    }
    
    func removeFromQueue(_ track: Track) {
        queue.removeAll { $0.id == track.id }
    }
    
    func playNext() async throws {
        guard !queue.isEmpty else { return }
        let next = queue.removeFirst()
        try await loadTrack(next)
        try await play()
    }
    
    func playPrevious() async throws {
        // For preview purposes, previous is a no-op
    }
    
    // MARK: - Volume / Mute
    func setVolume(_ volume: Float) {
        self.volume = max(0, min(volume, 1))
    }
    
    func setMuted(_ muted: Bool) {
        isMuted = muted
    }
    
    func toggleMute() {
        isMuted.toggle()
    }
    
    // MARK: - Advanced Playback
    func replay() async throws {
        currentPosition = 0
    }
    
    func skipForward(seconds: TimeInterval) async throws {
        currentPosition = max(0, min(currentPosition + seconds, duration))
    }
    
    func skipBackward(seconds: TimeInterval) async throws {
        currentPosition = max(0, currentPosition - seconds)
    }
    
    // MARK: - Loop Control
    func setLoopMode(_ mode: LoopMode) {
        loopMode = mode
    }
    
    func toggleLoopMode() {
        switch loopMode {
        case .none:
            loopMode = .track
        case .track:
            loopMode = .queue
        case .queue:
            loopMode = .none
        }
    }
    
    // MARK: - Shuffle Control
    func toggleShuffle() {
        isShuffleEnabled.toggle()
    }
    
    func setShuffle(_ enabled: Bool) {
        isShuffleEnabled = enabled
    }
}

private struct PreviewMockAudioVisualiser: AudioVisualiserProtocol {
    func process(audioData: [Float], sampleRate: Int, channels: Int) async throws -> AudioVisualiserFrame {
        let magnitudes = Array(repeating: Float(0.2), count: 64)
        return AudioVisualiserFrame(
            magnitudes: magnitudes,
            timestamp: Date(),
            sampleRate: sampleRate,
            fftSize: 128
        )
    }
    
    func latestFrame() async -> AudioVisualiserFrame? {
        nil
    }
    
    func recentFrames(limit: Int) async -> [AudioVisualiserFrame] {
        []
    }
}
#endif
