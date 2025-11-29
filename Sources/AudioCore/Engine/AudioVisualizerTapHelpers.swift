//
//  AudioVisualizerTapHelpers.swift
//  AudioCore
//
//  Helper methods for AudioVisualizerTap
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@preconcurrency import AVFoundation
import Foundation
import os.log
import Shared

// MARK: - AudioVisualizerTap Helper Methods Extension

extension AudioVisualizerTap {
    /// Result of scheduling operation
    struct SchedulingResult {
        let shouldSchedule: Bool
        let needsReschedule: Bool
    }
    
    /// Calculate the start time for scheduling
    /// - Parameters:
    ///   - engine: The audio engine
    ///   - audioFile: The audio file
    /// - Returns: AVAudioTime for scheduling, or nil for immediate scheduling
    func calculateStartTime(engine: AVAudioEngine, audioFile: AVAudioFile) -> AVAudioTime? {
        guard let renderTime = engine.outputNode.lastRenderTime else {
            return nil // Schedule immediately
        }
        return AVAudioTime(sampleTime: renderTime.sampleTime, atRate: audioFile.fileFormat.sampleRate)
    }
    
    /// Determine if file should be scheduled based on playback state and position
    /// - Parameters:
    ///   - startPosition: Optional start position
    ///   - needsReschedule: Whether node needs rescheduling
    /// - Returns: True if file should be scheduled
    func shouldScheduleFile(startPosition: TimeInterval?, needsReschedule: Bool) -> Bool {
        if startPosition == nil || startPosition == 0 {
            return needsReschedule
        } else if let position = startPosition, position > 0 {
            return true
        } else {
            return false
        }
    }
    
    /// Schedule the audio file for playback
    /// - Parameters:
    ///   - playerNode: The player node
    ///   - audioFile: The audio file to schedule
    ///   - scheduleTime: When to schedule (nil for immediate)
    ///   - startPosition: Optional start position
    func scheduleAudioFile(
        playerNode: AVAudioPlayerNode,
        audioFile: AVAudioFile,
        scheduleTime: AVAudioTime?,
        startPosition: TimeInterval?
    ) {
        let fileToReschedule = audioFile
        let nodeToReschedule = playerNode
        // Capture engine before closure to avoid MainActor isolation issues
        let engineToCheck = audioEngine
        
        playerNode.scheduleFile(audioFile, at: scheduleTime) {
            // File playback completed - reschedule to loop for continuous visualization
            guard let engine = engineToCheck,
                  engine.isRunning,
                  nodeToReschedule.isPlaying else {
                Logger.audio.debug("AudioVisualizerTap: Skipping reschedule (engine stopped or node not playing)")
                return
            }
            
            // Reschedule to continue processing
            let nextStartTime: AVAudioTime?
            if let renderTime = engine.outputNode.lastRenderTime {
                nextStartTime = AVAudioTime(sampleTime: renderTime.sampleTime, atRate: fileToReschedule.fileFormat.sampleRate)
            } else {
                nextStartTime = nil // Schedule immediately
            }
            nodeToReschedule.scheduleFile(fileToReschedule, at: nextStartTime, completionHandler: nil)
            Logger.audio.debug("AudioVisualizerTap: File rescheduled for continuous visualization")
        }
    }
    
    /// Verify and log player node status after starting
    /// - Parameters:
    ///   - playerNode: The player node
    ///   - engine: The audio engine
    func verifyPlayerNodeStatus(playerNode: AVAudioPlayerNode, engine: AVAudioEngine) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms delay to allow engine to start
            let isNodePlaying = playerNode.isPlaying
            let isEngineRunning = engine.isRunning
            let mixerVolume = engine.mainMixerNode.outputVolume
            
            if isNodePlaying && isEngineRunning {
                Logger.audio.info("AudioVisualizerTap: playerNode is playing, engine running, mixer volume: \(mixerVolume) - audio should flow through tap")
            } else {
                Logger.audio.warning("AudioVisualizerTap: playerNode.play() called but node playing: \(isNodePlaying), engine running: \(isEngineRunning), mixer volume: \(mixerVolume) - audio may not flow")
            }
        }
    }
    
    /// Schedule the entire file to be processed through the tap if needed
    /// The tap will capture audio data for visualization
    /// - Parameters:
    ///   - playerNode: The player node
    ///   - audioFile: The audio file
    ///   - engine: The audio engine
    ///   - startPosition: Optional start position
    /// - Returns: Scheduling result indicating if file was scheduled
    func scheduleFileIfNeeded(
        playerNode: AVAudioPlayerNode,
        audioFile: AVAudioFile,
        engine: AVAudioEngine,
        startPosition: TimeInterval?
    ) -> SchedulingResult {
        // Schedule the entire file to be processed through the tap
        // The tap will capture audio data for visualization
        // We need to schedule the file before playing to ensure audio flows
        // Use AVAudioTime to schedule immediately at the current engine time
        // If engine hasn't rendered yet, use nil to schedule immediately
        let startTime: AVAudioTime?
        if let renderTime = engine.outputNode.lastRenderTime {
            startTime = AVAudioTime(sampleTime: renderTime.sampleTime, atRate: audioFile.fileFormat.sampleRate)
        } else {
            // Schedule immediately (nil means "now")
            startTime = nil
        }
        
        // Capture references before the closure to avoid MainActor isolation issues
        let fileToReschedule = audioFile
        let nodeToReschedule = playerNode
        // Capture engine before closure to avoid MainActor isolation issues
        let engineToCheck = engine
        
        // Check if node is currently playing
        // NOTE: After pause() or stop() (which now uses pause()), buffers remain scheduled
        // However, if we want to play from beginning (startPosition nil/0), we need to reschedule
        let needsReschedule = !playerNode.isPlaying
        
        // Reschedule if:
        // - We want to play from beginning (startPosition is nil or 0) and node is not playing
        //   This handles the case where stop() was called and we want to restart from beginning
        // - OR we have a specific start position > 0 (need to reschedule to that position)
        // If node is paused and we want to resume from current position, we don't need to reschedule
        let shouldSchedule: Bool
        if startPosition == nil || startPosition == 0 {
            shouldSchedule = needsReschedule
        } else if let position = startPosition, position > 0 {
            shouldSchedule = true
        } else {
            shouldSchedule = false
        }
        
        if needsReschedule {
            Logger.audio.info("AudioVisualizerTap: Node not playing, will reschedule file (likely after stop/pause)")
        }
        
        if shouldSchedule {
            Logger.audio.info("AudioVisualizerTap: Scheduling file for playback (startPosition: \(startPosition?.description ?? "nil"), needsReschedule: \(needsReschedule))")
            
            // OPTIMIZATION: Schedule the file FIRST, then stop old schedules if needed
            // This way the new file is ready immediately, minimizing delay
            // Use nil for immediate scheduling - fastest and most reliable
            let scheduleTime: AVAudioTime? = (startPosition == nil || startPosition == 0) ? nil : startTime
            
            // CRITICAL OPTIMIZATION: Don't stop before scheduling - this causes the 2-3 second delay
            // Instead, schedule the new file immediately. If node is paused, the old schedule won't interfere.
            // When we call play(), it will start the newly scheduled file immediately.
            // This makes stop->play as fast as pause->play!
            playerNode.scheduleFile(audioFile, at: scheduleTime) {
                // File playback completed - reschedule to loop for continuous visualization
                // This ensures we keep getting audio data throughout playback
                // Note: This closure runs on the audio thread, not MainActor
                guard engineToCheck.isRunning,
                      nodeToReschedule.isPlaying else {
                    Logger.audio.debug("AudioVisualizerTap: Skipping reschedule (engine stopped or node not playing)")
                    return
                }
                
                // Reschedule to continue processing
                let nextStartTime: AVAudioTime?
                if let renderTime = engineToCheck.outputNode.lastRenderTime {
                    nextStartTime = AVAudioTime(sampleTime: renderTime.sampleTime, atRate: fileToReschedule.fileFormat.sampleRate)
                } else {
                    nextStartTime = nil // Schedule immediately
                }
                nodeToReschedule.scheduleFile(fileToReschedule, at: nextStartTime, completionHandler: nil)
                Logger.audio.debug("AudioVisualizerTap: File rescheduled for continuous visualization")
            }
            
            Logger.audio.info("AudioVisualizerTap: File scheduled successfully at time: \(scheduleTime?.description ?? "immediately")")
            
            // CRITICAL: When rescheduling from beginning, we need to clear the old paused schedule
            // But stop() takes time and causes delay. Instead, we schedule first, then stop briefly
            // However, stop() clears ALL schedules including the new one, so we need to reschedule
            // Actually, the best approach: Don't stop at all if node is just paused
            // The new schedule will play when we call play(), and the old paused schedule won't interfere
            // This makes stop->play as fast as pause->play!
            if (startPosition == nil || startPosition == 0) && needsReschedule && !playerNode.isPlaying {
                // Node is paused, old schedule exists. We've scheduled new file.
                // When we call play(), it should start the new schedule immediately
                // No need to stop - this is the key optimization!
                Logger.audio.debug("AudioVisualizerTap: New file scheduled over paused node, will play immediately")
            }
        }
        
        return SchedulingResult(shouldSchedule: shouldSchedule, needsReschedule: needsReschedule)
    }
    
    /// Start playback and verify player node status
    /// - Parameters:
    ///   - playerNode: The player node
    ///   - engine: The audio engine
    ///   - audioFile: The audio file
    ///   - schedulingResult: Result from scheduling operation
    func startPlayback(
        playerNode: AVAudioPlayerNode,
        engine: AVAudioEngine,
        audioFile: AVAudioFile,
        schedulingResult: SchedulingResult
    ) {
        // Start playing - this will feed audio through the tap
        // The engine must be running and the file must be scheduled
        Logger.audio.info("AudioVisualizerTap: Starting playerNode (engine running: \(engine.isRunning), node playing: \(playerNode.isPlaying), scheduled: \(schedulingResult.shouldSchedule))")
        
        // If we scheduled a file, ensure we call play() to start it
        // If we didn't schedule (shouldn't happen after stop), log a warning
        if !schedulingResult.shouldSchedule && schedulingResult.needsReschedule {
            Logger.audio.warning("AudioVisualizerTap: File was not scheduled but node needs reschedule - this should not happen")
        }
        
        // Ensure mixer volume is set before playing
        engine.mainMixerNode.outputVolume = self.volume
        
        // If we just scheduled a file, play immediately - this minimizes delay
        // For pause/resume (no reschedule), this just resumes immediately
        // For stop/play (with reschedule), this starts the newly scheduled file immediately
        playerNode.play()
        
        Logger.audio.debug("AudioVisualizerTap: Player node started (scheduled: \(schedulingResult.shouldSchedule), volume: \(self.volume))")
        
        // Verify playerNode is actually playing and log status
        // Note: isPlaying might not be true immediately, so we check after a brief delay
        verifyPlayerNodeStatus(playerNode: playerNode, engine: engine)
        
        Logger.audio.info("AudioVisualizerTap: Started processing audio file for visualization - file length: \(audioFile.length) frames, format: \(audioFile.processingFormat)")
    }
}
