//
//  ScrollingTextView.swift
//  Audientia
//
//  Scrolling text view for long track titles and artist names
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import SwiftUI

/// A view that continuously scrolls text horizontally when it exceeds the available width
struct ScrollingTextView: View {
    let text: String
    let font: Font
    let foregroundColor: Color
    let scrollSpeed: Double // pixels per second
    let frameWidth: CGFloat
    
    @State private var scrollOffset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var timer: Timer?
    
    init(
        text: String,
        font: Font = .system(size: 13),
        foregroundColor: Color = .primary,
        scrollSpeed: Double = 30.0,
        frameWidth: CGFloat
    ) {
        self.text = text
        self.font = font
        self.foregroundColor = foregroundColor
        self.scrollSpeed = scrollSpeed
        self.frameWidth = frameWidth
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Hidden measuring text to get intrinsic width, unconstrained by frameWidth
            Text(text)
                .font(font)
                .fixedSize(horizontal: true, vertical: false)
                .background(
                    GeometryReader { textGeometry in
                        Color.clear
                            .onAppear {
                                textWidth = textGeometry.size.width
                            }
                            .onChange(of: text) { _, _ in
                                textWidth = textGeometry.size.width
                            }
                    }
                )
                .hidden()
            
            if textWidth > frameWidth {
                // Scrolling overlay when content is wider than available width
                // Use smaller spacing for seamless loop
                HStack(spacing: 20) {
                    Text(text)
                        .font(font)
                        .foregroundColor(foregroundColor)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    
                    Text(text)
                        .font(font)
                        .foregroundColor(foregroundColor)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .offset(x: -scrollOffset)
                .frame(width: frameWidth, alignment: .leading)
                .clipped()
                .onAppear {
                    startScrolling()
                }
                .onDisappear {
                    stopScrolling()
                }
                .onChange(of: text) { _, _ in
                    stopScrolling()
                    scrollOffset = 0
                    startScrolling()
                }
                .onChange(of: scrollSpeed) { _, _ in
                    stopScrolling()
                    startScrolling()
                }
                .onChange(of: textWidth) { _, _ in
                    if textWidth > frameWidth {
                        stopScrolling()
                        scrollOffset = 0
                        startScrolling()
                    } else {
                        stopScrolling()
                        scrollOffset = 0
                    }
                }
            } else {
                // Simple, non-scrolling text when it fits
                Text(text)
                    .font(font)
                    .foregroundColor(foregroundColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .frame(width: frameWidth, alignment: .leading)
    }
    
    private func startScrolling() {
        guard textWidth > frameWidth else {
            stopScrolling()
            return
        }
        
        stopScrolling() // Stop any existing timer
        
        // Reset to start position
        scrollOffset = 0
        let spacing: CGFloat = 20
        let totalDistance = textWidth + spacing // text width + spacing between copies
        
        // Calculate update interval (60 FPS for smooth scrolling)
        let updateInterval = 1.0 / 60.0
        let pixelsPerUpdate = scrollSpeed * updateInterval
        
        // Start timer on main run loop to continuously update scroll offset
        // Use easing for smoother acceleration/deceleration
        let newTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
            // Update scroll offset with easing for smoother motion
            // Linear scrolling with slight easing at loop boundaries
            scrollOffset += pixelsPerUpdate
            
            // Seamlessly reset when we've scrolled past one complete text + spacing
            // This creates a continuous loop since the second copy is now in the same position
            if scrollOffset >= totalDistance {
                scrollOffset -= totalDistance
            }
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }
    
    private func stopScrolling() {
        timer?.invalidate()
        timer = nil
        scrollOffset = 0
    }
}
