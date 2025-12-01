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
        // Base text view - exactly like original Text view for layout
        Text(text)
            .font(font)
            .foregroundColor(foregroundColor)
            .lineLimit(1)
            .truncationMode(.tail)
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
            .overlay(
                // Overlay scrolling version when text exceeds width
                Group {
                    if textWidth > frameWidth {
                        HStack(spacing: 40) {
                            Text(text)
                                .font(font)
                                .foregroundColor(foregroundColor)
                                .lineLimit(1)
                            
                            Text(text)
                                .font(font)
                                .foregroundColor(foregroundColor)
                                .lineLimit(1)
                        }
                        .offset(x: -scrollOffset)
                        .frame(width: frameWidth, alignment: .leading)
                        .clipped()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                startScrolling()
                            }
                        }
                        .onDisappear {
                            stopScrolling()
                        }
                        .onChange(of: text) { _, _ in
                            stopScrolling()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                startScrolling()
                            }
                        }
                        .onChange(of: scrollSpeed) { _, _ in
                            stopScrolling()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                startScrolling()
                            }
                        }
                        .onChange(of: textWidth) { _, _ in
                            if textWidth > frameWidth {
                                stopScrolling()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    startScrolling()
                                }
                            } else {
                                stopScrolling()
                            }
                        }
                    }
                }
            )
    }
    
    private func startScrolling() {
        guard textWidth > frameWidth else {
            stopScrolling()
            return
        }
        
        stopScrolling() // Stop any existing timer
        
        scrollOffset = 0
        let totalDistance = textWidth + 40 // text width + spacing
        
        // Calculate update interval (60 FPS for smooth scrolling)
        let updateInterval = 1.0 / 60.0
        let pixelsPerUpdate = scrollSpeed * updateInterval
        
        // Start timer on main run loop to continuously update scroll offset
        let newTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
            // Timer callbacks are delivered on the main run loop; update state directly
            scrollOffset += pixelsPerUpdate
            
            // Reset when we've scrolled past the first text + spacing
            if scrollOffset >= totalDistance {
                scrollOffset = 0
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
