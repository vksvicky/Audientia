//
//  AudioEngine_PositionTracking.swift
//  AudioCore
//
//  Position tracking extension for AudioEngine
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.

import Foundation
import Shared

// MARK: - Position Tracking Extension
extension AudioEngine {
    func startPositionTracking() {
        stopPositionTracking()
        
        positionUpdateTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self else { break }
                
                if self.state == .playing {
                    self.currentPosition = self.nativeEngine.currentPosition
                    
                    // Check if we've reached the end using detected duration when available
                    let playbackDuration = self.duration
                    if playbackDuration > 0 {
                        // Check if position is at or very close to the end (within 0.2s tolerance)
                        // This accounts for timing precision while ensuring we catch completion
                        let isAtEnd = self.currentPosition >= playbackDuration - 0.2
                        
                        if isAtEnd {
                            // Clamp position to duration to avoid showing values beyond track length
                            self.currentPosition = min(self.currentPosition, playbackDuration)
                            
                            // Only trigger completion once - use a flag to prevent multiple calls
                            // Stop position tracking temporarily to prevent race conditions
                            self.stopPositionTracking()
                            
                            // Auto-advance to next track or stop
                            await self.handleTrackCompletion()
                            
                            // Restart position tracking if still playing (e.g., next track started)
                            if self.state == .playing {
                                self.startPositionTracking()
                            }
                        }
                    }
                }
                
                try? await Task.sleep(nanoseconds: UInt64(self.positionUpdateInterval * 1_000_000_000))
            }
        }
    }
    
    func stopPositionTracking() {
        positionUpdateTask?.cancel()
        positionUpdateTask = nil
    }
}
