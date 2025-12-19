import Accelerate
import Foundation
@preconcurrency import Shared

/// Audio visualiser implementation that produces FFT magnitude data for UI visualisers
public final class AudioVisualiser: AudioVisualiserProtocol, @unchecked Sendable {
    private let actor: VisualizerActor
    private let config: AudioVisualiserConfig
    
    /// Current configuration (read-only)
    public var currentConfig: AudioVisualiserConfig {
        config
    }
    
    public init(config: AudioVisualiserConfig = AudioVisualiserConfig()) {
        precondition(config.fftSize >= 256, "FFT size must be at least 256")
        precondition(config.fftSize.nonzeroBitCount == 1, "FFT size must be a power of two")
        self.config = config
        actor = VisualizerActor(config: config)
    }
    
    public func process(
        audioData: [Float],
        sampleRate: Int,
        channels: Int
    ) async throws -> AudioVisualiserFrame {
        try await actor.process(audioData: audioData, sampleRate: sampleRate, channels: channels)
    }
    
    public func latestFrame() async -> AudioVisualiserFrame? {
        await actor.latestFrame()
    }
    
    public func recentFrames(limit: Int) async -> [AudioVisualiserFrame] {
        await actor.recentFrames(limit: limit)
    }
}

private actor VisualizerActor {
    private let config: AudioVisualiserConfig
    private var previousMagnitudes: [Float]
    private var history: [AudioVisualiserFrame]
    private let hannWindow: [Float]
    private let fftSetup: FFTSetup?
    private let fftSize: Int
    private let smoothingFactor: Float
    private let log2n: vDSP_Length
    
    init(config: AudioVisualiserConfig) {
        self.config = config
        self.fftSize = config.fftSize
        self.smoothingFactor = config.smoothingFactor
        self.log2n = vDSP_Length(log2(Double(config.fftSize)))
        self.previousMagnitudes = [Float](repeating: 0.0, count: config.fftSize / 2)
        self.history = []
        var window = [Float](repeating: 0.0, count: config.fftSize)
        vDSP_hann_window(&window, vDSP_Length(config.fftSize), Int32(vDSP_HANN_NORM))
        self.hannWindow = window
        self.fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))
    }
    
    func process(
        audioData: [Float],
        sampleRate: Int,
        channels: Int
    ) throws -> AudioVisualiserFrame {
        try validateInputs(audioData: audioData, sampleRate: sampleRate, channels: channels)
        var monoBuffer = makeMonoBuffer(from: audioData, channels: channels)
        var magnitudes = try performFFT(on: &monoBuffer)
        applySmoothing(to: &magnitudes)
        let frame = makeFrame(with: magnitudes, sampleRate: sampleRate)
        storeFrame(frame)
        return frame
    }
    
    func latestFrame() -> AudioVisualiserFrame? {
        history.last
    }
    
    func recentFrames(limit: Int) -> [AudioVisualiserFrame] {
        guard limit > 0 else { return [] }
        let count = min(limit, history.count)
        return Array(history.suffix(count))
    }
    
    // MARK: - Helpers
    
    private func validateInputs(audioData: [Float], sampleRate: Int, channels: Int) throws {
        guard fftSize >= 256, fftSize.nonzeroBitCount == 1 else {
            throw AudioVisualiserError.invalidFFTSize
        }
        guard sampleRate > 0 else {
            throw AudioVisualiserError.invalidSampleRate
        }
        guard channels > 0 else {
            throw AudioVisualiserError.invalidChannelCount
        }
        guard !audioData.isEmpty, audioData.count % channels == 0 else {
            throw AudioVisualiserError.invalidAudioData
        }
        guard fftSetup != nil else {
            throw AudioVisualiserError.fftSetupFailed
        }
    }
    
    private func makeMonoBuffer(from audioData: [Float], channels: Int) -> [Float] {
        var monoBuffer = [Float](repeating: 0.0, count: fftSize)
        let framesAvailable = audioData.count / channels
        let frameCount = min(framesAvailable, fftSize)
        let channelCount = Float(channels)
        for frameIndex in 0..<frameCount {
            var sum: Float = 0.0
            let base = frameIndex * channels
            for channelIndex in 0..<channels {
                sum += audioData[base + channelIndex]
            }
            monoBuffer[frameIndex] = sum / channelCount
        }
        return monoBuffer
    }
    
    private func performFFT(on monoBuffer: inout [Float]) throws -> [Float] {
        applyWindow(to: &monoBuffer)
        var (real, imaginary) = try executeDFT(on: monoBuffer)
        return try calculateMagnitudes(real: &real, imaginary: &imaginary)
    }
    
    private func applyWindow(to buffer: inout [Float]) {
        buffer.withUnsafeMutableBufferPointer { bufferPtr in
            guard let bufferBase = bufferPtr.baseAddress else { return }
            hannWindow.withUnsafeBufferPointer { windowPtr in
                guard let windowBase = windowPtr.baseAddress else { return }
                vDSP_vmul(
                    bufferBase,
                    1,
                    windowBase,
                    1,
                    bufferBase,
                    1,
                    vDSP_Length(fftSize)
                )
            }
        }
    }
    
    private func executeDFT(on buffer: [Float]) throws -> (real: [Float], imaginary: [Float]) {
        guard let fftSetup else {
            throw AudioVisualiserError.fftSetupFailed
        }
        // Prepare buffers for FFT following the pattern from working implementations
        // Reference: OnlySwitch RealtimeAnalyzer.swift
        // https://github.com/jacklandrin/OnlySwitch/blob/0f99e74ef3cd35a7e21633f60ac4b1f48d666362/
        // OnlySwitch/Player/CommonPlayer/AudioSpectrum/RealtimeAnalyzer.swift
        var realp = [Float](repeating: 0.0, count: fftSize / 2)
        var imagp = [Float](repeating: 0.0, count: fftSize / 2)
        
        // Make a mutable copy of the input buffer for vDSP_ctoz
        var mutableBuffer = buffer
        
        mutableBuffer.withUnsafeMutableBufferPointer { inputPtr in
            guard let inputBase = inputPtr.baseAddress else { return }
            realp.withUnsafeMutableBufferPointer { realPtr in
                guard let realBase = realPtr.baseAddress else { return }
                imagp.withUnsafeMutableBufferPointer { imagPtr in
                    guard let imagBase = imagPtr.baseAddress else { return }
                    
                    var fftInOut = DSPSplitComplex(realp: realBase, imagp: imagBase)
                    
                    // Convert real input to complex format (interleaved to split)
                    // This prepares the data for vDSP_fft_zrip
                    inputBase.withMemoryRebound(to: DSPComplex.self, capacity: fftSize) { typeConvertedBuffer in
                        vDSP_ctoz(typeConvertedBuffer, 2, &fftInOut, 1, vDSP_Length(fftSize / 2))
                    }
                    
                    // Perform real-to-complex FFT
                    vDSP_fft_zrip(
                        fftSetup,
                        &fftInOut,
                        1,
                        log2n,
                        FFTDirection(FFT_FORWARD)
                    )
                    
                    // Normalize FFT output (divide by fftSize)
                    let fftNormFactor = Float(1.0 / Float(fftSize))
                    vDSP_vsmul(fftInOut.realp, 1, [fftNormFactor], fftInOut.realp, 1, vDSP_Length(fftSize / 2))
                    vDSP_vsmul(fftInOut.imagp, 1, [fftNormFactor], fftInOut.imagp, 1, vDSP_Length(fftSize / 2))
                    
                    // DC component is real-only, set imaginary to 0
                    fftInOut.imagp[0] = 0
                    
                    // Output is already in realp and imagp arrays via fftInOut pointers
                }
            }
        }
        
        return (realp, imagp)
    }
    
    private func calculateMagnitudes(real: inout [Float], imaginary: inout [Float]) throws -> [Float] {
        var pointerFailure = false
        let magnitudeCount = fftSize / 2
        var magnitudes = [Float](repeating: 0.0, count: magnitudeCount)
        real.withUnsafeMutableBufferPointer { realPtr in
            guard let realBase = realPtr.baseAddress else {
                pointerFailure = true
                return
            }
            imaginary.withUnsafeMutableBufferPointer { imagPtr in
                guard let imagBase = imagPtr.baseAddress else {
                    pointerFailure = true
                    return
                }
                let splitComplex = DSPSplitComplex(realp: realBase, imagp: imagBase)
                magnitudes.withUnsafeMutableBufferPointer { magPtr in
                    guard let magBase = magPtr.baseAddress else {
                        pointerFailure = true
                        return
                    }
                    var mutableSplit = splitComplex
                    vDSP_zvmags(
                        &mutableSplit,
                        1,
                        magBase,
                        1,
                        vDSP_Length(magnitudeCount)
                    )
                }
            }
        }
        if pointerFailure {
            throw AudioVisualiserError.fftSetupFailed
        }
        // Calculate square root of each magnitude squared to get magnitude
        var result = magnitudes
        for index in 0..<result.count {
            result[index] = sqrtf(result[index])
        }
        
        return result
    }
    
    private func applySmoothing(to magnitudes: inout [Float]) {
        guard smoothingFactor > 0.0, previousMagnitudes.count == magnitudes.count else {
            previousMagnitudes = magnitudes
            return
        }
        // Apply exponential moving average smoothing
        // Formula: smoothed = (1 - factor) * current + factor * previous
        // Higher factor = more smoothing (retains more of previous frame)
        for index in 0..<magnitudes.count {
            let previous = previousMagnitudes[index]
            magnitudes[index] = (1.0 - smoothingFactor) * magnitudes[index] + smoothingFactor * previous
        }
        previousMagnitudes = magnitudes
    }
    
    private func makeFrame(with magnitudes: [Float], sampleRate: Int) -> AudioVisualiserFrame {
        AudioVisualiserFrame(
            magnitudes: magnitudes,
            timestamp: Date(),
            sampleRate: sampleRate,
            fftSize: fftSize
        )
    }
    
    private func storeFrame(_ frame: AudioVisualiserFrame) {
        history.append(frame)
        let maxHistory = config.historyLength
        if history.count > maxHistory {
            history.removeFirst(history.count - maxHistory)
        }
    }
}
