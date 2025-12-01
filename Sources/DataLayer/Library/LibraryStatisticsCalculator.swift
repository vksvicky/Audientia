import Foundation
@preconcurrency import Shared

/// Calculator for library statistics
public final class LibraryStatisticsCalculator: LibraryStatisticsProtocol, @unchecked Sendable {
    private let indexer: LibraryIndexerProtocol?
    
    /// Initialise with a LibraryIndexerProtocol instance
    /// - Parameter indexer: The indexer to calculate statistics from (optional)
    public init(indexer: LibraryIndexerProtocol?) {
        self.indexer = indexer
    }
    
    /// Calculate statistics for all tracks in the library
    /// - Returns: LibraryStatistics object with calculated values
    /// - Throws: Error if calculation fails
    public func calculateStatistics() async throws -> LibraryStatistics {
        guard let indexer = indexer else {
            throw LibraryStatisticsError.indexerUnavailable
        }
        
        let allTracks = await indexer.getAllTracks()
        
        // Handle empty library
        guard !allTracks.isEmpty else {
            return LibraryStatistics(
                trackCount: 0,
                totalDuration: 0.0,
                totalFileSize: 0,
                artistCount: 0,
                albumCount: 0,
                averageBitrate: 0.0,
                averageSampleRate: 0.0
            )
        }
        
        // Calculate basic statistics
        let trackCount = allTracks.count
        let totalDuration = allTracks.reduce(0.0) { $0 + $1.duration }
        let totalFileSize = allTracks.reduce(Int64(0)) { $0 + $1.fileSize }
        
        // Calculate unique counts
        let uniqueArtists = Set(allTracks.map { $0.artist })
        let uniqueAlbums = Set(allTracks.map { $0.album })
        let artistCount = uniqueArtists.count
        let albumCount = uniqueAlbums.count
        
        // Calculate averages
        let totalBitrate = allTracks.reduce(0) { $0 + $1.bitrate }
        let averageBitrate = trackCount > 0 ? Double(totalBitrate) / Double(trackCount) : 0.0
        
        let totalSampleRate = allTracks.reduce(0) { $0 + $1.sampleRate }
        let averageSampleRate = trackCount > 0 ? Double(totalSampleRate) / Double(trackCount) : 0.0
        
        return LibraryStatistics(
            trackCount: trackCount,
            totalDuration: totalDuration,
            totalFileSize: totalFileSize,
            artistCount: artistCount,
            albumCount: albumCount,
            averageBitrate: averageBitrate,
            averageSampleRate: averageSampleRate
        )
    }
}
