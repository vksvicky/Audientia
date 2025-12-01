//
//  MetadataLookupViewModel.swift
//  Audientia - Metadata Lookup UI
//
//  ViewModel for metadata lookup, merge conflict resolution, and auto-tagging progress
//

import Foundation
import MetadataEngine
import Shared

/// Represents a metadata match from any external source
public struct MetadataMatch: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let source: MetadataSourceType
    public let confidence: Double
    public let fields: MetadataFields
    public let summary: String
    
    public init(
        id: UUID = UUID(),
        source: MetadataSourceType,
        confidence: Double,
        fields: MetadataFields,
        summary: String
    ) {
        self.id = id
        self.source = source
        self.confidence = confidence
        self.fields = fields
        self.summary = summary
    }
}

/// ViewModel responsible for metadata lookup, conflict resolution, and merge previews
@MainActor
public final class MetadataLookupViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var currentTrack: Shared.Track?
    @Published public private(set) var matches: [MetadataMatch] = []
    @Published public private(set) var selectedMatchID: UUID?
    @Published public private(set) var isLookingUp = false
    @Published public private(set) var mergePreview: Shared.Track?
    @Published public private(set) var lastError: Error?
    @Published public var mergeStrategy: MergeStrategy = .fillMissing {
        didSet { updateMergePreview() }
    }
    @Published public private(set) var statusMessage: String = "Select a track to begin"
    
    public let autoTaggingProgressViewModel = AutoTaggingProgressViewModel()
    
    // MARK: - Dependencies
    
    private let acoustIDService: any AcoustIDServicing
    private let musicBrainzClient: any MusicBrainzClientProtocol
    private let discogsClient: any DiscogsClientProtocol
    private let baseMetadataMerger: any MetadataMergeStrategyProtocol
    
    // MARK: - Initialisation
    
    public init(
        acoustIDService: any AcoustIDServicing,
        musicBrainzClient: any MusicBrainzClientProtocol,
        discogsClient: any DiscogsClientProtocol,
        metadataMerger: any MetadataMergeStrategyProtocol = MetadataMerger()
    ) {
        self.acoustIDService = acoustIDService
        self.musicBrainzClient = musicBrainzClient
        self.discogsClient = discogsClient
        self.baseMetadataMerger = metadataMerger
    }
    
    // MARK: - Public API
    
    public func loadTrack(_ track: Shared.Track) {
        currentTrack = track
        matches = []
        selectedMatchID = nil
        mergePreview = nil
        statusMessage = "Ready to lookup metadata for \(track.title)"
    }
    
    public func performLookup() async {
        guard let track = currentTrack else { return }
        await performLookup(for: track)
    }
    
    public func selectMatch(_ id: UUID) {
        guard matches.contains(where: { $0.id == id }) else { return }
        selectedMatchID = id
        updateMergePreview()
    }
    
    public func applySelectedMatch() -> Shared.Track? {
        mergePreview
    }
    
    public func autoTag(tracks: [Shared.Track]) async {
        guard !tracks.isEmpty else { return }
        autoTaggingProgressViewModel.start(total: tracks.count)
        for (index, track) in tracks.enumerated() {
            loadTrack(track)
            await performLookup(for: track)
            autoTaggingProgressViewModel.update(
                completed: index + 1,
                trackName: track.title
            )
        }
        autoTaggingProgressViewModel.complete()
    }
    
    // MARK: - Private Helpers
    
    private func performLookup(for track: Shared.Track) async {
        isLookingUp = true
        statusMessage = "Looking up metadata..."
        defer { isLookingUp = false }
        
        do {
            let fileURL = URL(fileURLWithPath: track.filePath)
            let acoustMatches = try await acoustIDService.identifyTrack(fileURL: fileURL)
            var aggregated: [MetadataMatch] = []
            
            for acoustMatch in acoustMatches {
                var fields = createFieldsFromAcoustIDMatch(acoustMatch)
                fields = await enrichWithMusicBrainz(fields: fields, recordingID: acoustMatch.recordingID)
                fields = await enrichWithDiscogs(fields: fields, acoustMatch: acoustMatch)
                
                let match = createMetadataMatch(from: acoustMatch, fields: fields)
                aggregated.append(match)
            }
            
            matches = aggregated.sorted { $0.confidence > $1.confidence }
            selectedMatchID = matches.first?.id
            statusMessage = matches.isEmpty ? "No matches found" : "Found \(matches.count) matches"
            lastError = nil
            updateMergePreview()
        } catch {
            matches = []
            selectedMatchID = nil
            mergePreview = nil
            lastError = error
            statusMessage = "Lookup failed"
        }
    }
    
    private func createFieldsFromAcoustIDMatch(_ match: AcoustIDMatch) -> MetadataFields {
        MetadataFields(
            title: match.title,
            artist: match.artist,
            album: match.album,
            year: match.year,
            trackNumber: match.trackNumber,
            discNumber: match.discNumber,
            genre: match.genre
        )
    }
    
    private func enrichWithMusicBrainz(fields: MetadataFields, recordingID: String) async -> MetadataFields {
        guard !recordingID.isEmpty else { return fields }
        
        guard let recording = try? await musicBrainzClient.lookupRecording(recordingID: recordingID) else {
            return fields
        }
        
        return MetadataFields(
            title: recording.title.isEmpty ? fields.title : recording.title,
            artist: recording.artist.isEmpty ? fields.artist : recording.artist,
            album: recording.release ?? fields.album,
            year: recording.date ?? fields.year,
            trackNumber: recording.trackNumber ?? fields.trackNumber,
            discNumber: recording.discNumber ?? fields.discNumber,
            genre: recording.genres.first ?? fields.genre
        )
    }
    
    private func enrichWithDiscogs(fields: MetadataFields, acoustMatch: AcoustIDMatch) async -> MetadataFields {
        guard fields.album == nil, let albumName = acoustMatch.album else { return fields }
        
        let discogsQuery = "\(acoustMatch.artist) \(albumName)"
        guard let discogsRelease = try? await discogsClient.searchReleases(query: discogsQuery).first else {
            return fields
        }
        
        return MetadataFields(
            title: fields.title ?? discogsRelease.title,
            artist: fields.artist ?? discogsRelease.artist,
            album: discogsRelease.title,
            year: discogsRelease.year ?? fields.year,
            trackNumber: fields.trackNumber,
            discNumber: fields.discNumber,
            genre: discogsRelease.genres.first ?? fields.genre
        )
    }
    
    private func createMetadataMatch(from acoustMatch: AcoustIDMatch, fields: MetadataFields) -> MetadataMatch {
        MetadataMatch(
            source: MetadataSourceType.acoustID,
            confidence: acoustMatch.score,
            fields: fields,
            summary: "\(fields.title ?? acoustMatch.title) • \(fields.artist ?? acoustMatch.artist)"
        )
    }
    
    private func updateMergePreview() {
        guard let track = currentTrack,
              let matchID = selectedMatchID,
              let selectedMatch = matches.first(where: { $0.id == matchID }) else {
            mergePreview = nil
            return
        }
        
        do {
            // Create a new merger with the selected strategy
            // Note: If baseMetadataMerger is a MetadataMerger, we can create a new instance
            // Otherwise, we use the base merger (which may not support strategy changes)
            let merger: any MetadataMergeStrategyProtocol
            if baseMetadataMerger is MetadataMerger {
                merger = MetadataMerger(strategy: mergeStrategy)
            } else {
                merger = baseMetadataMerger
            }
            
            let merged = try merger.merge(
                originalTrack: track,
                sources: [
                    MetadataSource(
                        type: selectedMatch.source,
                        confidence: selectedMatch.confidence,
                        metadata: selectedMatch.fields
                    )
                ]
            )
            mergePreview = merged
        } catch {
            lastError = error
            mergePreview = nil
        }
    }
}
