//
//  PlaylistStatisticsCalculator.swift
//  DataLayer
//
//  Playlist statistics calculation
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

/// Protocol for calculating playlist statistics
public protocol PlaylistStatisticsCalculatorProtocol: Sendable {
    /// Calculate statistics for a playlist
    /// - Parameter tracks: Array of tracks in the playlist
    /// - Returns: Playlist statistics
    func calculateStatistics(for tracks: [Track]) -> PlaylistStatistics
}

/// Playlist statistics
public struct PlaylistStatistics: Equatable, Sendable {
    /// Total number of tracks
    public let trackCount: Int
    
    /// Total duration in seconds
    public let totalDuration: TimeInterval
    
    /// Average duration per track in seconds
    public let averageDuration: TimeInterval
    
    /// Total file size in bytes
    public let totalFileSize: Int64
    
    /// Average file size per track in bytes
    public let averageFileSize: Int64
    
    /// Number of unique artists
    public let uniqueArtists: Int
    
    /// Number of unique albums
    public let uniqueAlbums: Int
    
    /// Number of unique genres
    public let uniqueGenres: Int
    
    /// Average rating (1-5, nil if no ratings)
    public let averageRating: Double?
    
    /// Year range (earliest to latest)
    public let yearRange: (earliest: Int?, latest: Int?)
    
    public init(
        trackCount: Int,
        totalDuration: TimeInterval,
        averageDuration: TimeInterval,
        totalFileSize: Int64,
        averageFileSize: Int64,
        uniqueArtists: Int,
        uniqueAlbums: Int,
        uniqueGenres: Int,
        averageRating: Double?,
        yearRange: (earliest: Int?, latest: Int?)
    ) {
        self.trackCount = trackCount
        self.totalDuration = totalDuration
        self.averageDuration = averageDuration
        self.totalFileSize = totalFileSize
        self.averageFileSize = averageFileSize
        self.uniqueArtists = uniqueArtists
        self.uniqueAlbums = uniqueAlbums
        self.uniqueGenres = uniqueGenres
        self.averageRating = averageRating
        self.yearRange = yearRange
    }
    
    // MARK: - Equatable
    
    public static func == (lhs: PlaylistStatistics, rhs: PlaylistStatistics) -> Bool {
        lhs.trackCount == rhs.trackCount &&
        lhs.totalDuration == rhs.totalDuration &&
        lhs.averageDuration == rhs.averageDuration &&
        lhs.totalFileSize == rhs.totalFileSize &&
        lhs.averageFileSize == rhs.averageFileSize &&
        lhs.uniqueArtists == rhs.uniqueArtists &&
        lhs.uniqueAlbums == rhs.uniqueAlbums &&
        lhs.uniqueGenres == rhs.uniqueGenres &&
        lhs.averageRating == rhs.averageRating &&
        lhs.yearRange.earliest == rhs.yearRange.earliest &&
        lhs.yearRange.latest == rhs.yearRange.latest
    }
}

/// Playlist statistics calculator implementation
public final class PlaylistStatisticsCalculator: PlaylistStatisticsCalculatorProtocol, @unchecked Sendable {
    
    /// Initialise the calculator
    public init() {}
    
    /// Calculate statistics for a playlist
    public func calculateStatistics(for tracks: [Track]) -> PlaylistStatistics {
        guard !tracks.isEmpty else {
            return PlaylistStatistics(
                trackCount: 0,
                totalDuration: 0.0,
                averageDuration: 0.0,
                totalFileSize: 0,
                averageFileSize: 0,
                uniqueArtists: 0,
                uniqueAlbums: 0,
                uniqueGenres: 0,
                averageRating: nil,
                yearRange: (earliest: nil, latest: nil)
            )
        }
        
        let trackCount = tracks.count
        let totalDuration = tracks.reduce(0.0) { $0 + $1.duration }
        let averageDuration = totalDuration / Double(trackCount)
        
        let totalFileSize = tracks.reduce(Int64(0)) { $0 + $1.fileSize }
        let averageFileSize = totalFileSize / Int64(trackCount)
        
        let uniqueArtists = Set(tracks.map { $0.artist }).count
        let uniqueAlbums = Set(tracks.map { $0.album }).count
        let uniqueGenres = Set(tracks.compactMap { $0.genre }).count
        
        let ratings = tracks.compactMap { $0.rating.map { Double($0) } }
        let averageRating = ratings.isEmpty ? nil : ratings.reduce(0.0, +) / Double(ratings.count)
        
        let years = tracks.compactMap { $0.year }
        let earliestYear = years.min()
        let latestYear = years.max()
        
        return PlaylistStatistics(
            trackCount: trackCount,
            totalDuration: totalDuration,
            averageDuration: averageDuration,
            totalFileSize: totalFileSize,
            averageFileSize: averageFileSize,
            uniqueArtists: uniqueArtists,
            uniqueAlbums: uniqueAlbums,
            uniqueGenres: uniqueGenres,
            averageRating: averageRating,
            yearRange: (earliest: earliestYear, latest: latestYear)
        )
    }
}
