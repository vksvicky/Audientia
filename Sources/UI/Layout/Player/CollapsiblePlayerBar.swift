//
//  CollapsiblePlayerBar.swift
//  Audientia
//
//  Collapsible player controls bar with expanded and collapsed states
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
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
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                CompactPlayerControls(
                    nowPlayingViewModel: nowPlayingViewModel,
                    onExpand: { isExpanded = true }
                )
                .frame(height: Self.collapsedHeight)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
        .clipped()
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
        HStack(spacing: 12) {
            // Track Info with Album Art
            trackInfoSection
                .frame(minWidth: 200, idealWidth: 280, maxWidth: 300, alignment: .leading)
                .layoutPriority(1)
            
            Spacer(minLength: 8)
            
            // Seek bar and playback controls
            VStack(spacing: 4) {
                seekBarView
                    .frame(minWidth: 200, idealWidth: 320, maxWidth: 400)
                
                ExpandedPlayerTransportControls(nowPlayingViewModel: nowPlayingViewModel)
            }
            .layoutPriority(2)
            
            Spacer(minLength: 8)
            
            // Additional controls
            ExpandedPlayerAdditionalControls(
                nowPlayingViewModel: nowPlayingViewModel,
                onMinimize: nil // Minimize button removed - using title bar minimize button instead
            )
            .frame(minWidth: 150, idealWidth: 200, maxWidth: 250, alignment: .trailing)
            .layoutPriority(1)
            
            // Collapse button
            collapseButton
                .layoutPriority(0)
        }
        .padding(.horizontal, 12)
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                HStack(spacing: 12) {
                    // Placeholder for album art to maintain layout
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                        )
                    
                    Text("No track selected")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
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
        .accessibilityLabel("Collapse player")
        .accessibilityHint("Collapses the player to a compact view. Press ⌘P to toggle.")
        .onChange(of: isExpanded) { _, newValue in
            if !newValue {
                // Announce when player is collapsed
                NSAccessibility.post(element: NSApplication.shared, notification: .announcementRequested, userInfo: [
                    .announcement: "Player collapsed"
                ])
            }
        }
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
        await ArtworkExtractor.extractArtworkImage(for: track)
    }
}
