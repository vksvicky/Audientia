//
//  MinimisedVolumeControl.swift
//  Audientia
//
//  Volume control components for minimized player view
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import Shared
import SwiftUI

// MARK: - Volume Popover View

struct MinimisedVolumePopoverView: View {
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
                    .frame(width: 16, height: 16)
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
            MinimisedVerticalVolumeSlider(
                value: Binding(
                    get: { Double(nowPlayingViewModel.volume) },
                    set: { nowPlayingViewModel.volume = Float($0) }
                )
            )
            .frame(width: 20, height: 120)
            .contentShape(Rectangle())
            .background(MinimisedScrollHandlerView(volume: $nowPlayingViewModel.volume))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(width: 160)
        .frame(minHeight: 220)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Custom Vertical Volume Slider

struct MinimisedVerticalVolumeSlider: NSViewRepresentable {
    @Binding var value: Double
    
    func makeNSView(context: Context) -> MinimisedVerticalSliderView {
        let slider = MinimisedVerticalSliderView()
        slider.minValue = 0.0
        slider.maxValue = 1.0
        slider.doubleValue = value
        slider.target = context.coordinator
        slider.action = #selector(Coordinator.valueChanged(_:))
        return slider
    }
    
    func updateNSView(_ nsView: MinimisedVerticalSliderView, context: Context) {
        nsView.doubleValue = value
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: MinimisedVerticalVolumeSlider
        
        init(_ parent: MinimisedVerticalVolumeSlider) {
            self.parent = parent
        }
        
        @objc func valueChanged(_ sender: MinimisedVerticalSliderView) {
            parent.value = sender.doubleValue
        }
    }
}

internal class MinimisedVerticalSliderView: NSControl {
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
        
        // Draw track background
        let trackColor = NSColor.quaternaryLabelColor
        context.setFillColor(trackColor.cgColor)
        context.fill(trackRect)
        
        // Draw track border
        let borderColor = NSColor.separatorColor
        context.setStrokeColor(borderColor.cgColor)
        context.setLineWidth(1.0)
        context.stroke(trackRect)
        
        // Draw filled portion
        let fillHeight = trackRect.height * CGFloat((doubleValue - minValue) / (maxValue - minValue))
        let fillRect = NSRect(
            x: trackRect.minX,
            y: trackRect.minY,
            width: trackRect.width,
            height: fillHeight
        )
        let fillColor = NSColor.controlAccentColor
        context.setFillColor(fillColor.cgColor)
        context.fill(fillRect)
        
        // Draw thumb
        let thumbY = trackRect.minY + fillHeight - thumbSize / 2
        let thumbRect = NSRect(
            x: bounds.midX - thumbSize / 2,
            y: thumbY,
            width: thumbSize,
            height: thumbSize
        )
        let thumbColor = NSColor.controlAccentColor
        context.setFillColor(thumbColor.cgColor)
        context.fillEllipse(in: thumbRect)
        
        // Draw thumb border
        context.setStrokeColor(NSColor.white.cgColor)
        context.setLineWidth(1.5)
        context.strokeEllipse(in: thumbRect)
    }
    
    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        updateValue(from: location)
        isDragging = true
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard isDragging else { return }
        let location = convert(event.locationInWindow, from: nil)
        updateValue(from: location)
    }
    
    override func mouseUp(with event: NSEvent) {
        isDragging = false
    }
    
    private func updateValue(from location: NSPoint) {
        let bounds = self.bounds
        let trackRect = NSRect(
            x: bounds.midX - trackWidth / 2,
            y: thumbSize / 2,
            width: trackWidth,
            height: bounds.height - thumbSize
        )
        
        let relativeY = location.y - trackRect.minY
        let normalizedY = max(0.0, min(1.0, relativeY / trackRect.height))
        let invertedY = 1.0 - normalizedY // Invert so top is max
        
        let newValue = minValue + (maxValue - minValue) * Double(invertedY)
        doubleValue = newValue
        sendAction(action, to: target)
    }
}

// MARK: - Scroll Handler View

struct MinimisedScrollHandlerView: NSViewRepresentable {
    @Binding var volume: Float
    
    func makeNSView(context: Context) -> MinimisedScrollHandlerNSView {
        let view = MinimisedScrollHandlerNSView()
        view.onScroll = { deltaY in
            let sensitivity: Float = 0.001
            var newVolume = volume + Float(deltaY) * sensitivity
            newVolume = max(0.0, min(1.0, newVolume))
            if abs(newVolume - volume) > 0.0001 {
                volume = newVolume
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: MinimisedScrollHandlerNSView, context: Context) {
        nsView.onScroll = { deltaY in
            let sensitivity: Float = 0.001
            var newVolume = volume + Float(deltaY) * sensitivity
            newVolume = max(0.0, min(1.0, newVolume))
            if abs(newVolume - volume) > 0.0001 {
                volume = newVolume
            }
        }
    }
}

internal class MinimisedScrollHandlerNSView: NSView {
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
            onScroll?(Double(deltaY))
        } else {
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
