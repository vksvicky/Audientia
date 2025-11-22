//
//  AVFoundationFeatureExtractor.swift
//  MetadataEngine
//
//  AVFoundation-based audio feature extraction (Feature 5.2)
//

import AVFoundation
import CoreMedia
import Foundation
import os.log
@preconcurrency import Shared

/// AVFoundation-based audio feature extractor
/// Extracts basic audio features (spectral features, RMS, etc.) for ML classification
public actor AVFoundationFeatureExtractor: AudioFeatureExtractorProtocol {
    private let logger = Logger(subsystem: "club.cycleruncode.audientia", category: "FeatureExtractor")
    
    public init() {}
    
    public func extractFeatures(from track: Track) async throws -> [Float] {
        // Validate file exists
        guard FileManager.default.fileExists(atPath: track.filePath) else {
            throw AudioFeatureExtractionError.fileNotFound
        }
        
        let fileURL = URL(fileURLWithPath: track.filePath)
        let asset = AVURLAsset(url: fileURL)
        
        // Load audio file
        guard let audioTrack = try await asset.loadTracks(withMediaType: .audio).first else {
            throw AudioFeatureExtractionError.unsupportedFormat
        }
        
        // Get audio format
        let formatDescriptions = try await audioTrack.load(.formatDescriptions)
        guard let formatDescription = formatDescriptions.first else {
            throw AudioFeatureExtractionError.unsupportedFormat
        }
        
        // Extract basic features using AVAssetReader
        // CMAudioFormatDescription is a type alias for CMFormatDescription
        // The cast always succeeds, but we use conditional cast for type safety
        guard let audioFormatDescription = formatDescription as? CMAudioFormatDescription else {
            throw AudioFeatureExtractionError.unsupportedFormat
        }
        return try await extractSpectralFeatures(from: asset, audioFormatDescription: audioFormatDescription)
    }
    
    // MARK: - Private Helpers
    
    private func extractSpectralFeatures(
        from asset: AVURLAsset,
        audioFormatDescription: CMAudioFormatDescription
    ) async throws -> [Float] {
        let (sampleRate, channelCount) = try extractAudioFormat(from: audioFormatDescription)
        let readerOutput = try await setupAssetReader(asset: asset, sampleRate: sampleRate, channelCount: channelCount)
        let samples = try readAudioSamples(from: readerOutput)
        return computeSpectralFeatures(from: samples)
    }
    
    private func extractAudioFormat(from description: CMAudioFormatDescription) throws -> (sampleRate: Int, channelCount: Int) {
        let basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(description)
        guard let streamDescription = basicDescription?.pointee else {
            throw AudioFeatureExtractionError.unsupportedFormat
        }
        return (Int(streamDescription.mSampleRate), Int(streamDescription.mChannelsPerFrame))
    }
    
    private func setupAssetReader(
        asset: AVURLAsset,
        sampleRate: Int,
        channelCount: Int
    ) async throws -> AVAssetReaderTrackOutput {
        guard let assetReader = try? AVAssetReader(asset: asset) else {
            throw AudioFeatureExtractionError.extractionFailed("Failed to create asset reader")
        }
        
        guard let audioTrack = try await asset.loadTracks(withMediaType: .audio).first else {
            throw AudioFeatureExtractionError.unsupportedFormat
        }
        
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channelCount
        ]
        
        let readerOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings)
        readerOutput.alwaysCopiesSampleData = false
        
        guard assetReader.canAdd(readerOutput) else {
            throw AudioFeatureExtractionError.extractionFailed("Cannot add reader output")
        }
        
        assetReader.add(readerOutput)
        
        guard assetReader.startReading() else {
            throw AudioFeatureExtractionError.extractionFailed("Failed to start reading")
        }
        
        return readerOutput
    }
    
    private func readAudioSamples(from readerOutput: AVAssetReaderTrackOutput) throws -> [Float] {
        var samples: [Float] = []
        var sampleCount = 0
        let maxSamples = 44100 * 30 // 30 seconds max for feature extraction
        
        while let sampleBuffer = readerOutput.copyNextSampleBuffer() {
            guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
                continue
            }
            
            var length = 0
            var dataPointer: UnsafeMutablePointer<Int8>?
            let status = CMBlockBufferGetDataPointer(
                blockBuffer,
                atOffset: 0,
                lengthAtOffsetOut: nil,
                totalLengthOut: &length,
                dataPointerOut: &dataPointer
            )
            
            guard status == noErr, let pointer = dataPointer else {
                continue
            }
            
            let (bufferSamples, newCount) = convertSamples(
                from: pointer,
                length: length,
                currentCount: sampleCount,
                maxSamples: maxSamples
            )
            samples.append(contentsOf: bufferSamples)
            sampleCount = newCount
            
            if sampleCount >= maxSamples {
                break
            }
        }
        
        guard !samples.isEmpty else {
            throw AudioFeatureExtractionError.insufficientAudioData
        }
        
        return samples
    }
    
    private func convertSamples(
        from pointer: UnsafeMutablePointer<Int8>,
        length: Int,
        currentCount: Int,
        maxSamples: Int
    ) -> (samples: [Float], newCount: Int) {
        let rawPointer = UnsafeMutableRawPointer(pointer)
        let int16Pointer = rawPointer.assumingMemoryBound(to: Int16.self)
        let sampleCountInBuffer = length / MemoryLayout<Int16>.size
        let samplesToRead = min(sampleCountInBuffer, maxSamples - currentCount)
        
        var samples: [Float] = []
        samples.reserveCapacity(samplesToRead)
        
        for i in 0..<samplesToRead {
            let sample = Float(int16Pointer[i]) / Float(Int16.max)
            samples.append(sample)
        }
        
        return (samples, currentCount + samplesToRead)
    }
    
    private func computeSpectralFeatures(from samples: [Float]) -> [Float] {
        // Compute basic features:
        // 1. RMS (Root Mean Square) - overall energy
        // 2. Zero Crossing Rate
        // 3. Spectral centroid (simplified)
        // 4. Spectral rolloff (simplified)
        // 5. MFCC-like features (simplified using FFT)
        
        var features: [Float] = []
        
        // RMS
        let rms = sqrt(samples.map { $0 * $0 }.reduce(0, +) / Float(samples.count))
        features.append(rms)
        
        // Zero Crossing Rate
        var zeroCrossings = 0
        for i in 1..<samples.count {
            if (samples[i - 1] >= 0 && samples[i] < 0) || (samples[i - 1] < 0 && samples[i] >= 0) {
                zeroCrossings += 1
            }
        }
        let zcr = Float(zeroCrossings) / Float(samples.count)
        features.append(zcr)
        
        // Simple spectral features using FFT
        let fftSize = min(2048, samples.count)
        let fftSamples = Array(samples.prefix(fftSize))
        
        // Compute FFT magnitude spectrum (simplified)
        // For a real implementation, we'd use vDSP_fft_zrip
        // For now, compute simple frequency domain features
        let windowedSamples = applyHammingWindow(to: fftSamples)
        
        // Spectral centroid (simplified - average frequency weighted by magnitude)
        let spectralCentroid = computeSpectralCentroid(from: windowedSamples)
        features.append(spectralCentroid)
        
        // Spectral rolloff (simplified - frequency below which 85% of energy is contained)
        let spectralRolloff = computeSpectralRolloff(from: windowedSamples)
        features.append(spectralRolloff)
        
        // Add more features to reach a reasonable feature vector size
        // For now, pad with statistical features
        let mean = samples.reduce(0, +) / Float(samples.count)
        let variance = samples.map { pow($0 - mean, 2) }.reduce(0, +) / Float(samples.count)
        let stdDev = sqrt(variance)
        
        features.append(mean)
        features.append(stdDev)
        
        // Add more frequency domain features (simplified)
        // In a real implementation, we'd compute MFCC coefficients
        for _ in 0..<10 {
            features.append(0.0) // Placeholder for MFCC coefficients
        }
        
        return features
    }
    
    private func applyHammingWindow(to samples: [Float]) -> [Float] {
        var windowed = [Float](repeating: 0, count: samples.count)
        for i in 0..<samples.count {
            let window = 0.54 - 0.46 * cos(2.0 * Float.pi * Float(i) / Float(samples.count - 1))
            windowed[i] = samples[i] * window
        }
        return windowed
    }
    
    private func computeSpectralCentroid(from samples: [Float]) -> Float {
        // Simplified spectral centroid calculation
        // Real implementation would use FFT
        var weightedSum: Float = 0.0
        var magnitudeSum: Float = 0.0
        
        for (index, sample) in samples.enumerated() {
            let magnitude = abs(sample)
            weightedSum += Float(index) * magnitude
            magnitudeSum += magnitude
        }
        
        guard magnitudeSum > 0 else { return 0.0 }
        return weightedSum / magnitudeSum
    }
    
    private func computeSpectralRolloff(from samples: [Float]) -> Float {
        // Simplified spectral rolloff calculation
        // Real implementation would use FFT
        let totalEnergy = samples.map { abs($0) }.reduce(0, +)
        let threshold = totalEnergy * 0.85
        
        var cumulativeEnergy: Float = 0.0
        for (index, sample) in samples.enumerated() {
            cumulativeEnergy += abs(sample)
            if cumulativeEnergy >= threshold {
                return Float(index) / Float(samples.count)
            }
        }
        
        return 1.0
    }
}
