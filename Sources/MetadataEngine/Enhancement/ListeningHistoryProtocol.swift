//
//  ListeningHistoryProtocol.swift
//  MetadataEngine
//
//  Protocol for listening history tracking (Feature 5.2)
//

import Foundation
@preconcurrency import Shared

/// Represents a listening event
public struct ListeningEvent: Sendable, Equatable {
    public let trackId: UUID
    public let timestamp: Date
    public let playDuration: TimeInterval // How long the track was played
    public let wasSkipped: Bool
    
    public init(trackId: UUID, timestamp: Date, playDuration: TimeInterval, wasSkipped: Bool = false) {
        self.trackId = trackId
        self.timestamp = timestamp
        self.playDuration = playDuration
        self.wasSkipped = wasSkipped
    }
}

/// Protocol for listening history tracking
public protocol ListeningHistoryProtocol: Sendable {
    /// Record a listening event
    func recordEvent(_ event: ListeningEvent) async
    
    /// Get recent listening events
    func getRecentEvents(limit: Int) async -> [ListeningEvent]
    
    /// Get play count for a track
    func getPlayCount(for trackId: UUID) async -> Int
    
    /// Get skip count for a track
    func getSkipCount(for trackId: UUID) async -> Int
    
    /// Get tracks played in a time range
    func getTracksPlayed(from startDate: Date, to endDate: Date) async -> [UUID]
}

/// Simple in-memory listening history implementation
public actor InMemoryListeningHistory: ListeningHistoryProtocol {
    private var events: [ListeningEvent] = []
    private let maxEvents = 10000 // Keep last 10k events
    
    public init() {}
    
    public func recordEvent(_ event: ListeningEvent) async {
        events.append(event)
        
        // Trim to max events (keep most recent)
        if events.count > maxEvents {
            events.removeFirst(events.count - maxEvents)
        }
    }
    
    public func getRecentEvents(limit: Int) async -> [ListeningEvent] {
        Array(events.suffix(limit))
    }
    
    public func getPlayCount(for trackId: UUID) async -> Int {
        events.filter { $0.trackId == trackId && !$0.wasSkipped }.count
    }
    
    public func getSkipCount(for trackId: UUID) async -> Int {
        events.filter { $0.trackId == trackId && $0.wasSkipped }.count
    }
    
    public func getTracksPlayed(from startDate: Date, to endDate: Date) async -> [UUID] {
        events
            .filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
            .map { $0.trackId }
    }
}
