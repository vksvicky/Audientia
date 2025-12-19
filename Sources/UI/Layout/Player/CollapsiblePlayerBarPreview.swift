//
//  CollapsiblePlayerBarPreview.swift
//  Audientia
//
//  Preview support for CollapsiblePlayerBar
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

#if DEBUG
import AudioCore
@preconcurrency import Shared
import SwiftUI

struct CollapsiblePlayerBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CollapsiblePlayerBar(
                nowPlayingViewModel: NowPlayingViewModel(audioEngine: CollapsiblePlayerBarPreviewAudioEngine()),
                isExpanded: .constant(true),
                onMinimize: nil
            )
            .frame(width: 800)
            
            CollapsiblePlayerBar(
                nowPlayingViewModel: NowPlayingViewModel(audioEngine: CollapsiblePlayerBarPreviewAudioEngine()),
                isExpanded: .constant(false),
                onMinimize: nil
            )
            .frame(width: 800)
        }
        .padding()
    }
}

@MainActor
final class CollapsiblePlayerBarPreviewAudioEngine: AudioEngineProtocol {
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
    
    func increaseVolume(by step: Float) {
        let newVolume = min(1.0, volume + step)
        self.volume = newVolume
    }
    
    func decreaseVolume(by step: Float) {
        let newVolume = max(0.0, volume - step)
        self.volume = newVolume
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
