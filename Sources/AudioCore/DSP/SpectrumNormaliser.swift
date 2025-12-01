//
//  SpectrumNormaliser.swift
//  Audientia
//
//  Spectrum normalization utilities for audio visualisation
//  Inspired by audioMotion-analyzer's logarithmic frequency scaling
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation

/// Normalizes spectrum magnitudes for visualisation
/// Uses logarithmic scaling similar to audioMotion-analyzer for better frequency representation
public struct SpectrumNormaliser {
    /// Logarithmic scaling factor for frequency bands
    /// Higher values compress low frequencies more (typical range: 1.0-3.0)
    public let logScale: Float
    
    /// Minimum frequency to display (Hz)
    public let minFreq: Float
    
    /// Maximum frequency to display (Hz)
    public let maxFreq: Float
    
    /// Sample rate of the audio (Hz)
    public let sampleRate: Int
    
    /// FFT size used for analysis
    public let fftSize: Int
    
    public init(
        logScale: Float = 2.0,
        minFreq: Float = 20.0,
        maxFreq: Float = 20000.0,
        sampleRate: Int = 44100,
        fftSize: Int = 1024
    ) {
        self.logScale = max(1.0, min(5.0, logScale))
        self.minFreq = max(1.0, minFreq)
        self.maxFreq = min(Float(sampleRate) / 2.0, maxFreq)
        self.sampleRate = sampleRate
        self.fftSize = fftSize
    }
    
    /// Normalizes raw FFT magnitudes using logarithmic frequency scaling
    /// This provides better visual representation matching human hearing perception
    /// Similar to audioMotion-analyzer's logarithmic frequency mapping
    public func normalize(_ magnitudes: [Float]) -> [Float] {
        guard !magnitudes.isEmpty else { return magnitudes }
        
        let magnitudeCount = magnitudes.count
        var normalized = [Float](repeating: 0.0, count: magnitudeCount)
        
        // Calculate frequency resolution (Hz per bin)
        let freqResolution = Float(sampleRate) / Float(fftSize)
        
        // Create logarithmic frequency bins (similar to audioMotion-analyzer)
        // Map linear FFT bins to logarithmic frequency space
        for outputIndex in 0..<magnitudeCount {
            // Calculate target frequency for this output bin using logarithmic scale
            let logPosition = Float(outputIndex) / Float(magnitudeCount - 1)
            let targetFreq = minFreq * pow(maxFreq / minFreq, logPosition)
            
            // Filter out frequencies outside the specified range
            // Only interpolate if the target frequency is within range
            if targetFreq >= minFreq && targetFreq <= maxFreq {
                // Find the corresponding linear FFT bin(s) for this frequency
                let linearBin = targetFreq / freqResolution
                let lowerBin = Int(linearBin)
                let upperBin = min(lowerBin + 1, magnitudeCount - 1)
                let fraction = linearBin - Float(lowerBin)
                
                // Only use bins that are within the valid frequency range
                let lowerFreq = Float(lowerBin) * freqResolution
                let upperFreq = Float(upperBin) * freqResolution
                
                // Only use lower bin if its frequency is at or above minFreq
                let lowerMag = (lowerFreq >= minFreq && lowerBin >= 0 && lowerBin < magnitudeCount)
                    ? magnitudes[lowerBin]
                    : 0.0
                
                // Only use upper bin if its frequency is at or below maxFreq
                let upperMag = (upperFreq <= maxFreq && upperBin >= 0 && upperBin < magnitudeCount)
                    ? magnitudes[upperBin]
                    : 0.0
                
                // Interpolate only if we have at least one valid bin
                if lowerMag > 0.0 || upperMag > 0.0 {
                    normalized[outputIndex] = lowerMag * (1.0 - fraction) + upperMag * fraction
                } else {
                    normalized[outputIndex] = 0.0
                }
            } else {
                normalized[outputIndex] = 0.0
            }
        }
        
        return normalized
    }
    
    /// Applies dynamic range compression to enhance visualisation
    /// Similar to audioMotion-analyzer's sensitivity and smoothing
    /// Higher sensitivity values reduce dynamic range more (compress more)
    public func compress(_ magnitudes: [Float], sensitivity: Float = 1.0) -> [Float] {
        guard !magnitudes.isEmpty else { return magnitudes }
        
        let maxMagnitude = magnitudes.max() ?? 1.0
        let minMagnitude = magnitudes.min() ?? 0.0
        let threshold = maxMagnitude * 0.1 // Bottom 10% threshold
        
        // Calculate original range for compression
        let originalRange = maxMagnitude - minMagnitude
        guard originalRange > 0 else { return magnitudes }
        
        return magnitudes.map { magnitude in
            // Normalize magnitude to 0-1 range relative to min and max
            let normalized = (magnitude - minMagnitude) / originalRange
            
            // Apply sensitivity scaling (higher sensitivity = more compression)
            // pow(normalized, 1.0 / sensitivity) compresses the range
            // When sensitivity > 1, this reduces the dynamic range
            let compressedNormalized = pow(max(0.0, normalized), 1.0 / sensitivity)
            
            // Scale back to a compressed range
            // The compressed range is reduced proportionally to sensitivity
            // This ensures the range is actually reduced
            let compressedRange = originalRange / sensitivity
            let compressedValue = compressedNormalized * compressedRange + minMagnitude
            
            // Apply threshold to very quiet values
            if compressedValue < threshold {
                return compressedValue * 0.1 // Reduce but don't zero
            }
            return compressedValue
        }
    }
    
    /// Maps frequency bin index to actual frequency in Hz
    public func frequencyForBin(_ binIndex: Int) -> Float {
        guard binIndex >= 0 && binIndex < fftSize / 2 else {
            return 0.0
        }
        return Float(binIndex) * Float(sampleRate) / Float(fftSize)
    }
    
    /// Maps frequency in Hz to bin index
    public func binForFrequency(_ frequency: Float) -> Int {
        guard frequency >= minFreq && frequency <= maxFreq else {
            return -1
        }
        return Int(frequency * Float(fftSize) / Float(sampleRate))
    }
}
