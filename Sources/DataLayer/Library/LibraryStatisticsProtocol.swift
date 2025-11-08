import Foundation
@preconcurrency import Shared

/// Statistics about the music library
public struct LibraryStatistics: Equatable {
    /// Total number of tracks in the library
    public let trackCount: Int
    
    /// Total duration of all tracks in seconds
    public let totalDuration: TimeInterval
    
    /// Total file size of all tracks in bytes
    public let totalFileSize: Int64
    
    /// Number of unique artists
    public let artistCount: Int
    
    /// Number of unique albums
    public let albumCount: Int
    
    /// Average bitrate in kbps
    public let averageBitrate: Double
    
    /// Average sample rate in Hz
    public let averageSampleRate: Double
    
    /// Initialize library statistics
    public init(
        trackCount: Int,
        totalDuration: TimeInterval,
        totalFileSize: Int64,
        artistCount: Int,
        albumCount: Int,
        averageBitrate: Double,
        averageSampleRate: Double
    ) {
        self.trackCount = trackCount
        self.totalDuration = totalDuration
        self.totalFileSize = totalFileSize
        self.artistCount = artistCount
        self.albumCount = albumCount
        self.averageBitrate = averageBitrate
        self.averageSampleRate = averageSampleRate
    }
}

/// Protocol for calculating library statistics
public protocol LibraryStatisticsProtocol: Sendable {
    /// Calculate statistics for all tracks in the library
    /// - Returns: LibraryStatistics object with calculated values
    /// - Throws: Error if calculation fails
    func calculateStatistics() async throws -> LibraryStatistics
}

/// Errors that can occur during statistics calculation
public enum LibraryStatisticsError: Error {
    case calculationFailed
    case indexerUnavailable
}
