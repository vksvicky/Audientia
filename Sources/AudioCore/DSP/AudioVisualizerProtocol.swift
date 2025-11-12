import Foundation
@preconcurrency import Shared

/// Configuration for the audio visualizer feed
public struct AudioVisualizerConfig: Equatable, Sendable {
    private static let minimumFFTSize = 256
    private static let maximumFFTSize = 8192
    
    /// Number of samples used for the FFT (must be power of two)
    public let fftSize: Int
    
    /// Exponential moving average smoothing factor (0.0 - 0.95)
    public let smoothingFactor: Float
    
    /// Number of frames retained in history for UI consumption
    public let historyLength: Int
    
    public init(fftSize: Int = 1024, smoothingFactor: Float = 0.3, historyLength: Int = 5) {
        self.fftSize = AudioVisualizerConfig.clampFFTSize(fftSize)
        self.smoothingFactor = AudioVisualizerConfig.clampSmoothing(smoothingFactor)
        self.historyLength = max(1, historyLength)
    }
    
    private static func clampFFTSize(_ value: Int) -> Int {
        var size = max(minimumFFTSize, min(maximumFFTSize, value))
        // Ensure power of two
        if size.nonzeroBitCount != 1 {
            var power = minimumFFTSize
            while power < size {
                power <<= 1
            }
            size = min(power, maximumFFTSize)
        }
        return size
    }
    
    private static func clampSmoothing(_ value: Float) -> Float {
        max(0.0, min(0.95, value))
    }
}

/// FFT frame produced by the audio visualizer feed
public struct AudioVisualizerFrame: Equatable, Sendable {
    public let magnitudes: [Float]
    public let timestamp: Date
    public let sampleRate: Int
    public let fftSize: Int
    
    public init(magnitudes: [Float], timestamp: Date, sampleRate: Int, fftSize: Int) {
        self.magnitudes = magnitudes
        self.timestamp = timestamp
        self.sampleRate = sampleRate
        self.fftSize = fftSize
    }
    
    /// Maximum magnitude within this frame
    public var maxMagnitude: Float {
        magnitudes.max() ?? 0.0
    }
    
    /// Dominant FFT bin index
    public var dominantBin: Int? {
        magnitudes.enumerated().max(by: { $0.element < $1.element })?.offset
    }
    
    /// Dominant frequency (Hz) associated with the dominant bin
    public var dominantFrequency: Float {
        guard let bin = dominantBin, fftSize > 0 else {
            return 0.0
        }
        // For real FFT with vDSP_fft_zrip, output has N/2 bins (0 to N/2-1)
        // Bin k represents frequency k * sampleRate / fftSize
        // Note: vDSP_fft_zrip stores output where bin k is at index k
        // Frequency resolution: sampleRate / fftSize Hz per bin
        return Float(bin) * Float(sampleRate) / Float(fftSize)
    }
}

/// Errors that can occur during visualizer processing
public enum AudioVisualizerError: Error, Equatable {
    case invalidFFTSize
    case invalidSampleRate
    case invalidChannelCount
    case invalidAudioData
    case fftSetupFailed
}

/// Audio visualizer protocol for producing FFT magnitude data for the UI
public protocol AudioVisualizerProtocol: Sendable {
    /// Process audio data and return a visualizer frame
    func process(audioData: [Float], sampleRate: Int, channels: Int) async throws -> AudioVisualizerFrame
    
    /// Latest processed frame, if available
    func latestFrame() async -> AudioVisualizerFrame?
    
    /// Recent frames ordered from oldest to newest, capped by `limit`
    func recentFrames(limit: Int) async -> [AudioVisualizerFrame]
}
