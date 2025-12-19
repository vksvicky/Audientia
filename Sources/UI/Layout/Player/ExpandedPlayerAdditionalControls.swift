//
//  ExpandedPlayerAdditionalControls.swift
//  Audientia
//
//  Additional controls (shuffle, loop, volume) for expanded player bar
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import Shared
import SwiftUI

/// Additional controls section for expanded player bar
struct ExpandedPlayerAdditionalControls: View {
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    var onMinimize: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 8) {
            // Minimize button removed - using title bar minimize button instead
            shuffleButton
            loopButton
            gainControlButton
            playbackSpeedControl
            volumeControl
        }
    }
    
    private var shuffleButton: some View {
        Button("Shuffle", systemImage: "shuffle") {
            nowPlayingViewModel.toggleShuffle()
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 14))
        .foregroundColor(nowPlayingViewModel.isShuffleEnabled ? Color.accentColor : .primary)
        .buttonStyle(.plain)
        .accessibilityLabel("Shuffle")
        .accessibilityHint(
            nowPlayingViewModel.isShuffleEnabled
                ? "Shuffle is enabled. Press to disable."
                : "Shuffle is disabled. Press to enable."
        )
        .accessibilityAddTraits(nowPlayingViewModel.isShuffleEnabled ? [.isSelected, .isButton] : .isButton)
        .accessibilityValue(nowPlayingViewModel.isShuffleEnabled ? "Enabled" : "Disabled")
    }
    
    private var loopButton: some View {
        Button("Loop", systemImage: loopIconName) {
            nowPlayingViewModel.toggleLoopMode()
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 14))
        .foregroundColor(nowPlayingViewModel.loopMode != .none ? Color.accentColor : .primary)
        .buttonStyle(.plain)
        .accessibilityLabel("Loop mode")
        .accessibilityHint(loopAccessibilityHint)
        .accessibilityAddTraits(nowPlayingViewModel.loopMode != .none ? [.isSelected, .isButton] : .isButton)
        .accessibilityValue(loopAccessibilityValue)
    }
    
    private var loopIconName: String {
        switch nowPlayingViewModel.loopMode {
        case .none, .queue: return "repeat"
        case .track: return "repeat.1"
        }
    }
    
    private var loopAccessibilityHint: String {
        switch nowPlayingViewModel.loopMode {
        case .none:
            return "Loop is disabled. Press to enable loop mode."
        case .track:
            return "Loop track is enabled. Press to change loop mode."
        case .queue:
            return "Loop queue is enabled. Press to disable loop mode."
        }
    }
    
    private var loopAccessibilityValue: String {
        switch nowPlayingViewModel.loopMode {
        case .none: return "Disabled"
        case .track: return "Loop track"
        case .queue: return "Loop queue"
        }
    }
    
    private var gainControlButton: some View {
        Button("Gain Control", systemImage: "waveform") {
            nowPlayingViewModel.toggleGainControl()
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 14))
        .foregroundColor(nowPlayingViewModel.isGainControlEnabled ? Color.accentColor : .primary)
        .buttonStyle(.plain)
        .frame(width: 20, height: 20) // Fixed frame to prevent alignment shifts
        .accessibilityLabel("Gain Control")
        .accessibilityHint(
            nowPlayingViewModel.isGainControlEnabled
                ? "Gain control is enabled. Press to disable."
                : "Gain control is disabled. Press to enable."
        )
        .accessibilityAddTraits(nowPlayingViewModel.isGainControlEnabled ? [.isSelected, .isButton] : .isButton)
        .accessibilityValue(nowPlayingViewModel.isGainControlEnabled ? "Enabled" : "Disabled")
    }
    
    private var playbackSpeedControl: some View {
        PlaybackSpeedControl(playbackSpeed: $nowPlayingViewModel.playbackSpeed)
    }
    
    private var volumeControl: some View {
        VolumeControlButton(nowPlayingViewModel: nowPlayingViewModel)
    }
}

// MARK: - Volume Control Button with Popover

private struct VolumeControlButton: View {
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    @State private var isPopoverPresented = false
    
    var body: some View {
        Button("Volume", systemImage: nowPlayingViewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill") {
            isPopoverPresented.toggle()
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 14))
        .foregroundColor(nowPlayingViewModel.isMuted ? .red : .primary)
        .buttonStyle(.plain)
        .frame(width: 20, height: 20) // Fixed frame to prevent alignment shifts
        .popover(isPresented: $isPopoverPresented, attachmentAnchor: .point(.bottom), arrowEdge: .bottom) {
            VolumePopoverView(nowPlayingViewModel: nowPlayingViewModel)
                .frame(width: 160)
                .frame(minHeight: 220) // Explicit frame for popover content
        }
        .accessibilityLabel("Volume")
        .accessibilityHint("Click to adjust volume")
        .accessibilityValue("\(Int(nowPlayingViewModel.volume * 100)) percent")
    }
}

private struct VolumePopoverView: View {
    @ObservedObject var nowPlayingViewModel: NowPlayingViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            // Mute button
            Button {
                nowPlayingViewModel.toggleMute()
            } label: {
                HStack {
                    Image(
                        systemName: nowPlayingViewModel.isMuted
                            ? "speaker.slash.fill"
                            : "speaker.wave.2.fill"
                    )
                    .frame(width: 16, height: 16) // Fixed frame for icon
                    Text(nowPlayingViewModel.isMuted ? "Unmute" : "Mute")
                }
            }
            .buttonStyle(.bordered)
            .padding(.top, 4)
            
            Divider()
            
            // Volume label
            HStack {
                Text("Volume")
                    .font(.caption)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(Int(nowPlayingViewModel.volume * 100))%")
                    .font(.caption)
                    .foregroundColor(.primary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 2)
            
            // Vertical volume slider
            VerticalVolumeSlider(
                value: Binding(
                    get: { Double(nowPlayingViewModel.volume) },
                    set: { nowPlayingViewModel.volume = Float($0) }
                )
            )
            .frame(width: 20, height: 120)
            .contentShape(Rectangle()) // Make entire area interactive
            .background(ScrollHandlerView(volume: $nowPlayingViewModel.volume))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(width: 160)
        .frame(minHeight: 220)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Custom Vertical Volume Slider

private struct VerticalVolumeSlider: NSViewRepresentable {
    @Binding var value: Double
    
    func makeNSView(context: Context) -> VerticalSliderView {
        let slider = VerticalSliderView()
        slider.minValue = 0.0
        slider.maxValue = 1.0
        slider.doubleValue = value
        slider.target = context.coordinator
        slider.action = #selector(Coordinator.valueChanged(_:))
        return slider
    }
    
    func updateNSView(_ nsView: VerticalSliderView, context: Context) {
        nsView.doubleValue = value
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: VerticalVolumeSlider
        
        init(_ parent: VerticalVolumeSlider) {
            self.parent = parent
        }
        
        @objc func valueChanged(_ sender: VerticalSliderView) {
            parent.value = sender.doubleValue
        }
    }
}

private class VerticalSliderView: NSControl {
    var minValue: Double = 0.0
    var maxValue: Double = 1.0
    override var doubleValue: Double {
        get {
            _doubleValue
        }
        set {
            if abs(_doubleValue - newValue) > 0.001 {
                _doubleValue = newValue
                needsDisplay = true
            }
        }
    }
    private var _doubleValue: Double = 0.0
    
    private let trackWidth: CGFloat = 4
    private let thumbSize: CGFloat = 16
    private var isDragging = false
    private var lastScrollValue: Double = 0.0
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    override var intrinsicContentSize: NSSize {
        NSSize(width: thumbSize, height: 120)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        let bounds = self.bounds
        let trackRect = NSRect(
            x: bounds.midX - trackWidth / 2,
            y: thumbSize / 2,
            width: trackWidth,
            height: bounds.height - thumbSize
        )
        
        // Draw track background (vertical line) - more visible
        let trackColor = NSColor.quaternaryLabelColor
        context.setFillColor(trackColor.cgColor)
        context.fill(trackRect)
        
        // Draw track border for better visibility
        let borderColor = NSColor.separatorColor
        context.setStrokeColor(borderColor.cgColor)
        context.setLineWidth(1.0)
        context.stroke(trackRect)
        
        // Draw filled portion (from bottom to current value)
        let normalizedValue = (doubleValue - minValue) / (maxValue - minValue)
        let filledHeight = trackRect.height * CGFloat(normalizedValue)
        let filledRect = NSRect(
            x: trackRect.minX,
            y: trackRect.minY,
            width: trackRect.width,
            height: filledHeight
        )
        
        // Use accent color for filled portion
        let accentColor = NSColor.controlAccentColor
        context.setFillColor(accentColor.cgColor)
        context.fill(filledRect)
        
        // Draw thumb (indicator) at the current value position
        let thumbY = trackRect.minY + filledHeight - thumbSize / 2
        let thumbRect = NSRect(
            x: bounds.midX - thumbSize / 2,
            y: thumbY,
            width: thumbSize,
            height: thumbSize
        )
        
        // Draw thumb with accent color
        context.setFillColor(accentColor.cgColor)
        context.fillEllipse(in: thumbRect)
        
        // Draw thumb border for better visibility
        let thumbBorderColor = NSColor.labelColor.withAlphaComponent(0.2)
        context.setStrokeColor(thumbBorderColor.cgColor)
        context.setLineWidth(2.0)
        context.strokeEllipse(in: thumbRect)
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        isDragging = true
        updateValue(from: event)
    }
    
    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        if isDragging {
            updateValue(from: event)
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        if isDragging {
            updateValue(from: event)
            isDragging = false
        }
    }
    
    private func updateValue(from event: NSEvent) {
        // Convert point from window coordinates to view coordinates
        guard self.window != nil else { return }
        let windowPoint = event.locationInWindow
        let viewPoint = convert(windowPoint, from: nil)
        
        let bounds = self.bounds
        let trackRect = NSRect(
            x: bounds.midX - trackWidth / 2,
            y: thumbSize / 2,
            width: trackWidth,
            height: bounds.height - thumbSize
        )
        
        // Calculate value based on Y position
        // Check if view is flipped (SwiftUI views often are)
        let isFlipped = self.isFlipped
        
        let relativeY = viewPoint.y - trackRect.minY
        let normalizedY = relativeY / trackRect.height
        
        // If flipped, Y=0 is at top, so we need to invert
        // If not flipped, Y=0 is at bottom, so higher Y = higher value
        let finalY = isFlipped ? (1.0 - normalizedY) : normalizedY
        let clampedY = max(0.0, min(1.0, finalY))
        let newValue = minValue + (maxValue - minValue) * Double(clampedY)
        
        if abs(newValue - doubleValue) > 0.001 {
            doubleValue = newValue
            sendAction(action, to: target)
        }
    }
    
    override func scrollWheel(with event: NSEvent) {
        // Handle trackpad scrolling
        let deltaY = event.scrollingDeltaY
        let sensitivity: Double = 0.001 // Reduced sensitivity for less smooth/more controlled scrolling
        
        var newValue = doubleValue
        if event.hasPreciseScrollingDeltas {
            // Trackpad with precise scrolling
            newValue += Double(deltaY) * sensitivity
        } else {
            // Mouse wheel - less sensitive
            newValue += Double(deltaY) * sensitivity * 0.3
        }
        
        newValue = max(minValue, min(maxValue, newValue))
        
        if abs(newValue - doubleValue) > 0.0001 {
            doubleValue = newValue
            sendAction(action, to: target)
        }
    }
    
    override var acceptsFirstResponder: Bool {
        true
    }
    
    override func becomeFirstResponder() -> Bool {
        true
    }
}

// MARK: - Scroll Handler for Trackpad Support

private struct ScrollHandlerView: NSViewRepresentable {
    @Binding var volume: Float
    
    func makeNSView(context: Context) -> ScrollHandlerNSView {
        let view = ScrollHandlerNSView()
        view.onScroll = { deltaY in
            let sensitivity: Float = 0.001 // Reduced sensitivity for less smooth/more controlled scrolling
            var newVolume = volume + Float(deltaY) * sensitivity
            newVolume = max(0.0, min(1.0, newVolume))
            if abs(newVolume - volume) > 0.0001 {
                volume = newVolume
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: ScrollHandlerNSView, context: Context) {
        nsView.onScroll = { deltaY in
            let sensitivity: Float = 0.001 // Reduced sensitivity for less smooth/more controlled scrolling
            var newVolume = volume + Float(deltaY) * sensitivity
            newVolume = max(0.0, min(1.0, newVolume))
            if abs(newVolume - volume) > 0.0001 {
                volume = newVolume
            }
        }
    }
}

private class ScrollHandlerNSView: NSView {
    var onScroll: ((Double) -> Void)?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    override func scrollWheel(with event: NSEvent) {
        let deltaY = event.scrollingDeltaY
        if event.hasPreciseScrollingDeltas {
            // Trackpad with precise scrolling
            onScroll?(Double(deltaY))
        } else {
            // Mouse wheel - less sensitive
            onScroll?(Double(deltaY) * 0.5)
        }
    }
    
    override var acceptsFirstResponder: Bool {
        true
    }
    
    override func becomeFirstResponder() -> Bool {
        true
    }
}
