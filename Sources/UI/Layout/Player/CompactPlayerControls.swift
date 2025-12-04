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
                    scrollSpeed: 25.0, // Tuned for smoother, more readable scrolling
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
        CompactControlButton(
            label: "Previous",
            systemImage: "backward.fill",
            isEnabled: nowPlayingViewModel.queue.count > 1,
            action: {
                Task { try? await nowPlayingViewModel.playPrevious() }
            }
        )
    }
    
    private var playPauseButton: some View {
        CompactControlButton(
            label: nowPlayingViewModel.isPlaying ? "Pause" : "Play",
            systemImage: nowPlayingViewModel.isPlaying ? "pause.fill" : "play.fill",
            isEnabled: true,
            isPrimary: true,
            action: {
                Task {
                    if nowPlayingViewModel.isPlaying {
                        await nowPlayingViewModel.pause()
                    } else {
                        try? await nowPlayingViewModel.play()
                    }
                }
            }
        )
    }
    
    private var nextButton: some View {
        CompactControlButton(
            label: "Next",
            systemImage: "forward.fill",
            isEnabled: nowPlayingViewModel.queue.count > 1,
            action: {
                Task { try? await nowPlayingViewModel.playNext() }
            }
        )
    }
    
    private var shuffleButton: some View {
        CompactControlButton(
            label: "Shuffle",
            systemImage: "shuffle",
            isEnabled: true,
            isActive: nowPlayingViewModel.isShuffleEnabled,
            action: {
                nowPlayingViewModel.toggleShuffle()
            }
        )
    }
    
    private var loopButton: some View {
        CompactControlButton(
            label: "Loop",
            systemImage: loopIconName,
            isEnabled: true,
            isActive: nowPlayingViewModel.loopMode != .none,
            action: {
                nowPlayingViewModel.toggleLoopMode()
            }
        )
    }
    
    private var muteButton: some View {
        CompactControlButton(
            label: "Mute",
            systemImage: nowPlayingViewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
            isEnabled: true,
            isActive: nowPlayingViewModel.isMuted,
            activeColor: .red,
            action: {
                nowPlayingViewModel.toggleMute()
            }
        )
    }
    
    private var loopIconName: String {
        switch nowPlayingViewModel.loopMode {
        case .none, .queue: return "repeat"
        case .track: return "repeat.1"
        }
    }
    
    // MARK: - Expand Button
    
    private var expandButton: some View {
        CompactControlButton(
            label: "Expand",
            systemImage: "chevron.up",
            isEnabled: true,
            action: onExpand
        )
        .keyboardShortcut("p", modifiers: .command)
        .help("Expand player (⌘P)")
        .accessibilityHint("Expands the player to show full controls. Press ⌘P to toggle.")
    }
}

// MARK: - Compact Control Button with Hover States

private struct CompactControlButton: View {
    let label: String
    let systemImage: String
    let isEnabled: Bool
    var isPrimary: Bool = false
    var isActive: Bool = false
    var activeColor: Color = .accentColor
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: isPrimary ? 12 : 10, weight: isPrimary ? .semibold : .regular))
                .foregroundColor(foregroundColor)
                .frame(width: 20, height: 20)
                .contentShape(Rectangle())
                .background(
                    Circle()
                        .fill(backgroundFill)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.5)
        .onHover { hovering in
            isHovered = hovering
        }
        .pressEvents(onPress: {
            isPressed = true
        }, onRelease: {
            isPressed = false
        })
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isActive ? [.isSelected, .isButton] : .isButton)
        .accessibilityValue(accessibilityValue)
    }
    
    private var accessibilityLabel: String {
        label
    }
    
    private var accessibilityHint: String {
        if !isEnabled {
            return "Button is disabled"
        } else if isActive {
            return "\(label) is active. Press to toggle."
        } else {
            return "Press to \(label.lowercased())"
        }
    }
    
    private var accessibilityValue: String {
        if isActive {
            return "Active"
        } else {
            return ""
        }
    }
    
    private var foregroundColor: Color {
        if isActive {
            return activeColor
        } else if isPrimary {
            return Color.accentColor
        } else {
            return .secondary
        }
    }
    
    private var backgroundFill: Color {
        if isPressed {
            return Color(NSColor.controlAccentColor).opacity(0.2)
        } else if isHovered && isEnabled {
            return Color(NSColor.controlAccentColor).opacity(0.1)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Press Events Modifier

private extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    onPress()
                }
                .onEnded { _ in
                    onRelease()
                }
        )
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
