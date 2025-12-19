//
//  AudioVisualiserTap.swift
//  AudioCore
//
//  Audio tap implementation for real-time visualisation using AVAudioEngine
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@preconcurrency import AVFoundation
import Foundation
import os.log
import Shared

// AudioVisualiserProtocol is in the same module (AudioCore)
// No explicit import needed as it's part of the AudioCore module

/// Manages audio tap for real-time visualisation
/// Processes audio samples and feeds them to the visualiser
@MainActor
public final class AudioVisualiserTap {
    var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var audioFile: AVAudioFile?
    private let visualiser: any AudioVisualiserProtocol
    private var isTapped = false
    
    /// Visualization volume (0.0 to 1.0)
    /// Controls the output volume of the visualisation engine
    /// Higher values provide better visualisation data but may be audible
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
    
    public init(visualiser: any AudioVisualiserProtocol) {
        self.visualiser = visualiser
    }
    
    /// Setup audio engine and install tap for visualisation
    /// This runs in parallel with the main playback engine for visualisation only
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
            
            // Install tap on main mixer for real-time audio visualisation
            // Tapping the main mixer (which is connected to output) guarantees audio will flow
            // Use smaller buffer size (2048 frames) for more responsive visualisation
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
            
            Logger.audio.info("AudioVisualiserTap: Engine started, tap installed, sampleRate: \(sampleRate), channels: \(channels)")
            
            self.audioEngine = engine
            self.playerNode = playerNode
            self.audioFile = audioFile
            self.isTapped = true
            
            return true
        } catch {
            return false
        }
    }
    
    /// Process audio buffer and feed to visualiser
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, sampleRate: Int, channels: Int) {
        // Extract audio data from buffer
        guard let audioData = extractAudioData(from: buffer, channels: channels) else {
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
        let hasAudioData = maxSample > 0.0
        
        // Log buffer info appropriately
        logBufferInfo(
            count: BufferCounter.count,
            frameLength: Int(buffer.frameLength),
            maxSample: maxSample,
            audioData: audioData,
            hasAudioData: hasAudioData
        )
        
        // Warn if we're getting all zeros when audio should be playing
        logZeroBufferWarning(
            count: BufferCounter.count,
            hasAudioData: hasAudioData
        )
        
        // Process audio data through visualiser asynchronously
        processAudioDataAsync(
            audioData: audioData,
            sampleRate: sampleRate,
            bufferCount: BufferCounter.count,
            hasAudioData: hasAudioData
        )
    }
    
    /// Extract audio data from buffer, converting to mono if needed
    private func extractAudioData(from buffer: AVAudioPCMBuffer, channels: Int) -> [Float]? {
        let frameLength = Int(buffer.frameLength)
        guard let channelData = buffer.floatChannelData else {
            Logger.audio.debug("AudioVisualiserTap: No channel data in buffer")
            return nil
        }
        
        // Convert stereo to mono by averaging channels, or use mono directly
        if channels == 1 {
            return Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
        } else if channels >= 2 {
            // For stereo, mix down to mono by averaging left and right channels
            let leftChannel = UnsafeBufferPointer(start: channelData[0], count: frameLength)
            let rightChannel = UnsafeBufferPointer(start: channelData[1], count: frameLength)
            return (0..<frameLength).map { index in
                (leftChannel[index] + rightChannel[index]) / 2.0
            }
        } else {
            Logger.audio.warning("AudioVisualiserTap: Unexpected channel count: \(channels)")
            return nil
        }
    }
    
    /// Log buffer information at appropriate intervals
    private func logBufferInfo(
        count: Int,
        frameLength: Int,
        maxSample: Float,
        audioData: [Float],
        hasAudioData: Bool
    ) {
        if count <= 3 {
            let samplesPreview = Array(audioData.prefix(5))
            let minSample = audioData.map { abs($0) }.min() ?? 0.0
            let bufferDebugMessage = "AudioVisualiserTap: Buffer #\(count) - frames: \(frameLength), " +
                "max: \(maxSample), min: \(minSample), " +
                "first 5 samples: \(samplesPreview)"
            Logger.audio.debug("\(bufferDebugMessage)")
        } else if hasAudioData && count % 500 == 0 {
            let minSample = audioData.map { abs($0) }.min() ?? 0.0
            let bufferInfoMessage = "AudioVisualiserTap: Buffer #\(count) - frames: \(frameLength), " +
                "max: \(maxSample), min: \(minSample)"
            Logger.audio.debug("\(bufferInfoMessage)")
        }
    }
    
    /// Log warnings for zero buffers when audio should be playing
    private func logZeroBufferWarning(count: Int, hasAudioData: Bool) {
        if !hasAudioData && count > 10 && count % 500 == 0 {
            // Only warn if playerNode is actually playing (audio should be flowing)
            if let playerNode = playerNode, playerNode.isPlaying {
                let zeroBufferWarning = "AudioVisualiserTap: Receiving all-zero buffers while playing - " +
                    "audio may not be flowing. Check engine setup. (Buffer #\(count))"
                Logger.audio.warning("\(zeroBufferWarning)")
            } else {
                // If not playing, this is expected - use debug level instead
                let zeroBufferDebug = "AudioVisualiserTap: Receiving all-zero buffers " +
                    "(no audio playing, expected). (Buffer #\(count))"
                Logger.audio.debug("\(zeroBufferDebug)")
            }
        }
    }
    
    /// Process audio data through visualiser asynchronously
    private func processAudioDataAsync(
        audioData: [Float],
        sampleRate: Int,
        bufferCount: Int,
        hasAudioData: Bool
    ) {
        // Use Task.detached to avoid blocking the audio thread
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            do {
                let frame = try await self.visualiser.process(
                    audioData: audioData,
                    sampleRate: sampleRate,
                    channels: 1 // Process as mono
                )
                // Only log processed frames when there's actual audio data (not zeros)
                // Log every 500th buffer to reduce spam
                if hasAudioData && bufferCount % 500 == 0 {
                    let maxStr = String(format: "%.2f", frame.maxMagnitude)
                    let freqStr = String(format: "%.1f", frame.dominantFrequency)
                    let processedFrameMessage = "AudioVisualiserTap: Processed frame #\(bufferCount) - " +
                        "max: \(maxStr), freq: \(freqStr) Hz"
                    Logger.audio.debug("\(processedFrameMessage)")
                }
            } catch {
                Logger.audio.error(
                    "AudioVisualiserTap: Processing error: \(error.localizedDescription)"
                )
            }
        }
    }
    
    /// Start processing audio for visualisation (does not play audio)
    /// This reads the file and processes it through the tap for visualisation only
    /// - Parameter startPosition: Optional position in seconds to start from (for syncing with main playback)
    public func play(startPosition: TimeInterval? = nil) -> Bool {
        guard let playerNode = playerNode,
              let audioFile = audioFile,
              let engine = audioEngine else {
            Logger.audio.warning("AudioVisualiserTap: Cannot play - playerNode, audioFile, or engine is nil")
            return false
        }
        
        // Ensure engine is running - restart if it stopped (e.g., after stop())
        guard ensureEngineRunning(engine: engine, playerNode: playerNode, audioFile: audioFile) else {
            return false
        }
        
        // Schedule file if needed and start playback
        let schedulingResult = scheduleFileIfNeeded(
            playerNode: playerNode,
            audioFile: audioFile,
            engine: engine,
            startPosition: startPosition
        )
        
        startPlayback(
            playerNode: playerNode,
            engine: engine,
            audioFile: audioFile,
            schedulingResult: schedulingResult
        )
        
        return true
    }
    
    /// Pause playback
    public func pause() {
        playerNode?.pause()
    }
    
    /// Stop playback
    /// NOTE: We use pause() instead of stop() to keep the engine/node state consistent
    /// When play() is called after stop() with startPosition: nil, we'll reschedule from beginning
    /// This approach works the same as pause/resume but allows position reset
    public func stop() {
        // Use pause() to keep node state consistent (like pause/resume)
        // When we play again, if startPosition is nil/0, we'll reschedule from beginning
        // This avoids the issues with stop() clearing buffers and engine restart problems
        playerNode?.pause()
        Logger.audio.info("AudioVisualiserTap: Player node paused (will reschedule from beginning on next play if needed)")
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
    
    // MARK: - Private Helper Methods
    
    /// Ensure engine is running, restarting if needed
    /// - Parameters:
    ///   - engine: The audio engine
    ///   - playerNode: The player node
    ///   - audioFile: The audio file
    /// - Returns: True if engine is running, false if restart failed
    private func ensureEngineRunning(
        engine: AVAudioEngine,
        playerNode: AVAudioPlayerNode,
        audioFile: AVAudioFile
    ) -> Bool {
        guard !engine.isRunning else {
            Logger.audio.debug("AudioVisualiserTap: Engine is already running")
            return true
        }
        
        Logger.audio.info("AudioVisualiserTap: Engine not running, restarting...")
        do {
            // Verify tap is still installed before restarting
            if !isTapped {
                Logger.audio.warning("AudioVisualiserTap: Tap not installed, cannot restart")
                return false
            }
            
            // Verify playerNode is still attached and connected
            if engine.attachedNodes.contains(playerNode) {
                Logger.audio.debug("AudioVisualiserTap: PlayerNode is still attached")
            } else {
                Logger.audio.warning("AudioVisualiserTap: PlayerNode is not attached, reattaching...")
                engine.attach(playerNode)
                engine.connect(playerNode, to: engine.mainMixerNode, format: audioFile.processingFormat)
            }
            
            try engine.start()
            engine.mainMixerNode.outputVolume = self.volume
            Logger.audio.info("AudioVisualiserTap: Engine restarted successfully, mixer volume set to \(self.volume), tap should resume receiving callbacks")
            return true
        } catch {
            Logger.audio.error("AudioVisualiserTap: Failed to restart engine: \(error.localizedDescription)")
            return false
        }
    }
    
}
