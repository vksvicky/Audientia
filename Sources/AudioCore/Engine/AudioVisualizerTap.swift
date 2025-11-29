//
//  AudioVisualizerTap.swift
//  AudioCore
//
//  Audio tap implementation for real-time visualization using AVAudioEngine
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@preconcurrency import AVFoundation
import Foundation
import os.log
import Shared

// AudioVisualizerProtocol is in the same module (AudioCore)
// No explicit import needed as it's part of the AudioCore module

/// Manages audio tap for real-time visualization
/// Processes audio samples and feeds them to the visualizer
@MainActor
public final class AudioVisualizerTap {
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var audioFile: AVAudioFile?
    private let visualizer: any AudioVisualizerProtocol
    private var isTapped = false
    
    /// Visualization volume (0.0 to 1.0)
    /// Controls the output volume of the visualization engine
    /// Higher values provide better visualization data but may be audible
    public var volume: Float = 1.0 {
        didSet {
            let clamped = max(0.0, min(1.0, volume))
            if clamped != volume {
                volume = clamped
                return
            }
            // Update the engine's output volume in real-time
            audioEngine?.mainMixerNode.outputVolume = clamped
        }
    }
    
    public init(visualizer: any AudioVisualizerProtocol) {
        self.visualizer = visualizer
    }
    
    /// Setup audio engine and install tap for visualization
    /// This runs in parallel with the main playback engine for visualization only
    /// - Parameter filePath: Path to the audio file
    /// - Returns: True if setup successful
    public func setupAudioEngine(filePath: String) -> Bool {
        guard let url = URL(string: filePath) ?? URL(fileURLWithPath: filePath) as URL? else {
            return false
        }
        
        do {
            // Create audio engine
            let engine = AVAudioEngine()
            let playerNode = AVAudioPlayerNode()
            
            // Load audio file
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.processingFormat
            let sampleRate = Int(format.sampleRate)
            let channels = format.channelCount
            
            // Attach player node
            engine.attach(playerNode)
            
            // Connect directly to main mixer (simple, reliable path)
            // This ensures audio flows through the mixer and can be tapped
            engine.connect(playerNode, to: engine.mainMixerNode, format: format)
            
            // Use the current volume setting (defaults to 1.0)
            // This can be adjusted in real-time via the volume property
            engine.mainMixerNode.outputVolume = volume
            
            // Connect to output (required for engine to process audio)
            engine.connect(engine.mainMixerNode, to: engine.outputNode, format: format)
            
            // Install tap on main mixer for real-time audio visualization
            // Tapping the main mixer (which is connected to output) guarantees audio will flow
            // Use smaller buffer size (2048 frames) for more responsive visualization
            // This matches audioMotion-analyzer's approach of using smaller buffers for real-time updates
            let bufferSize: AVAudioFrameCount = 2048
            engine.mainMixerNode.installTap(
                onBus: 0,
                bufferSize: bufferSize,
                format: format
            ) { [weak self] buffer, _ in
                self?.processAudioBuffer(buffer, sampleRate: sampleRate, channels: Int(channels))
            }
            
            // Start engine - this will process audio through the tap
            try engine.start()
            
            Logger.audio.info("AudioVisualizerTap: Engine started, tap installed, sampleRate: \(sampleRate), channels: \(channels)")
            
            self.audioEngine = engine
            self.playerNode = playerNode
            self.audioFile = audioFile
            self.isTapped = true
            
            return true
        } catch {
            return false
        }
    }
    
    /// Process audio buffer and feed to visualizer
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, sampleRate: Int, channels: Int) {
        // Convert audio buffer to Float array
        let frameLength = Int(buffer.frameLength)
        var audioData: [Float] = []
        
        // Extract audio samples from buffer
        guard let channelData = buffer.floatChannelData else {
            Logger.audio.debug("AudioVisualizerTap: No channel data in buffer")
            return
        }
        
        // Convert stereo to mono by averaging channels, or use mono directly
        if channels == 1 {
            audioData = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
        } else if channels >= 2 {
            // For stereo, mix down to mono by averaging left and right channels
            // This provides better visualization than just using one channel
            let leftChannel = UnsafeBufferPointer(start: channelData[0], count: frameLength)
            let rightChannel = UnsafeBufferPointer(start: channelData[1], count: frameLength)
            audioData = (0..<frameLength).map { index in
                (leftChannel[index] + rightChannel[index]) / 2.0
            }
        } else {
            Logger.audio.warning("AudioVisualizerTap: Unexpected channel count: \(channels)")
            return
        }
        
        // Log first few buffers to confirm we're receiving data
        // Only log occasionally to avoid spam
        struct BufferCounter {
            static var count = 0
        }
        BufferCounter.count += 1
        
        // Check if we're getting actual audio data (non-zero samples)
        let maxSample = audioData.map { abs($0) }.max() ?? 0.0
        let minSample = audioData.map { abs($0) }.min() ?? 0.0
        
        if BufferCounter.count <= 3 || BufferCounter.count % 100 == 0 {
            if BufferCounter.count <= 3 {
                Logger.audio.debug("AudioVisualizerTap: Buffer #\(BufferCounter.count) - frames: \(frameLength), max: \(maxSample), min: \(minSample), first 5 samples: \(Array(audioData.prefix(5)))")
            } else {
                Logger.audio.debug("AudioVisualizerTap: Buffer #\(BufferCounter.count) - frames: \(frameLength), max: \(maxSample), min: \(minSample)")
            }
        }
        
        // Warn if we're getting all zeros (audio not flowing)
        // Only log warning occasionally to avoid spam (every 50 buffers with zeros)
        if maxSample == 0.0 && BufferCounter.count > 10 && BufferCounter.count % 50 == 0 {
            Logger.audio.warning("AudioVisualizerTap: Receiving all-zero buffers - audio may not be flowing. Check engine setup and playerNode state. (Buffer #\(BufferCounter.count))")
        }
        
        // Process audio data through visualizer
        // Use Task.detached to avoid blocking the audio thread
        // This ensures frames are created asynchronously without blocking audio processing
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            do {
                let frame = try await self.visualizer.process(
                    audioData: audioData,
                    sampleRate: sampleRate,
                    channels: 1 // Process as mono
                )
                // Log occasionally to confirm processing (every 50th buffer)
                if BufferCounter.count % 50 == 0 {
                    Logger.audio.debug("AudioVisualizerTap: Processed frame #\(BufferCounter.count) - max: \(String(format: "%.2f", frame.maxMagnitude)), freq: \(String(format: "%.1f", frame.dominantFrequency)) Hz")
                }
            } catch {
                Logger.audio.error("AudioVisualizerTap: Processing error: \(error.localizedDescription)")
            }
        }
    }
    
    /// Start processing audio for visualization (does not play audio)
    /// This reads the file and processes it through the tap for visualization only
    /// - Parameter startPosition: Optional position in seconds to start from (for syncing with main playback)
    public func play(startPosition: TimeInterval? = nil) -> Bool {
        guard let playerNode = playerNode,
              let audioFile = audioFile,
              let engine = audioEngine else {
            Logger.audio.warning("AudioVisualizerTap: Cannot play - playerNode, audioFile, or engine is nil")
            return false
        }
        
        // Ensure engine is running
        guard engine.isRunning else {
            Logger.audio.warning("AudioVisualizerTap: Engine is not running")
            return false
        }
        
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
        let engineToCheck = engine
        
        // Only schedule the full file if we didn't already schedule a segment
        if startPosition == nil || startPosition == 0 {
            playerNode.scheduleFile(audioFile, at: startTime) {
                // File playback completed - reschedule to loop for continuous visualization
                // This ensures we keep getting audio data throughout playback
                // Note: This closure runs on the audio thread, not MainActor
                guard engineToCheck.isRunning,
                      nodeToReschedule.isPlaying else {
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
        }
        
        // Start playing - this will feed audio through the tap
        // The engine must be running and the file must be scheduled
        playerNode.play()
        
        // Verify playerNode is actually playing and log status
        // Note: isPlaying might not be true immediately, so we check after a brief delay
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms delay to allow engine to start
            if playerNode.isPlaying {
                Logger.audio.info("AudioVisualizerTap: playerNode is playing, audio should flow through tap")
            } else {
                Logger.audio.warning("AudioVisualizerTap: playerNode.play() called but node is not playing after delay - audio may not flow")
            }
        }
        
        Logger.audio.info("AudioVisualizerTap: Started processing audio file for visualization - file length: \(audioFile.length) frames, format: \(audioFile.processingFormat)")
        
        return true
    }
    
    /// Pause playback
    public func pause() {
        playerNode?.pause()
    }
    
    /// Stop playback
    public func stop() {
        playerNode?.stop()
    }
    
    /// Remove tap and cleanup
    public func cleanup() {
        // Remove tap from main mixer
        audioEngine?.mainMixerNode.removeTap(onBus: 0)
        audioEngine?.stop()
        playerNode?.stop()
        isTapped = false
        audioEngine = nil
        playerNode = nil
        audioFile = nil
    }
    
    deinit {
        // Note: deinit is nonisolated, so we can't safely access MainActor properties
        // The cleanup() method should be called explicitly before deallocation
        // This is a safety fallback that may not execute if properties are already deallocated
    }
}
