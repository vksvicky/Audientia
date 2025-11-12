//
//  LibraryIndexer.swift
//  DataLayer
//
//  Library indexer implementation
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
@preconcurrency import Shared

// Import SearchField from LibrarySearch (same module, so we can reference it directly)
// SearchField is defined in LibrarySearch.swift as a public enum

/// Library indexer for managing indexed tracks
/// Uses in-memory storage for fast lookups
public final class LibraryIndexer: LibraryIndexerProtocol, @unchecked Sendable {
    
    /// Actor for thread-safe index operations
    private let indexActor = IndexActor()
    
    /// Initialize the indexer
    public init() {}
    
    /// Index a collection of tracks
    /// - Parameter tracks: Array of tracks to index
    /// - Throws: Error if indexing fails
    public func index(tracks: [Track]) async throws {
        try await indexActor.index(tracks: tracks)
    }
    
    /// Remove a track from the index
    /// - Parameter track: Track to remove
    /// - Throws: Error if removal fails
    public func remove(track: Track) async throws {
        try await indexActor.remove(track: track)
    }
    
    /// Clear all tracks from the index
    /// - Throws: Error if clearing fails
    public func clear() async throws {
        await indexActor.clear()
    }
    
    /// Get a track by its ID
    /// - Parameter id: Track ID
    /// - Returns: Track if found, nil otherwise
    public func getTrack(by id: UUID) async -> Track? {
        await indexActor.getTrack(by: id)
    }
    
    /// Get the count of indexed tracks
    /// - Returns: Number of indexed tracks
    public func getIndexedTrackCount() async -> Int {
        await indexActor.getCount()
    }
    
    /// Get all indexed tracks
    /// - Returns: Array of all indexed tracks
    public func getAllTracks() async -> [Track] {
        await indexActor.getAllTracks()
    }
    
    /// Search tracks using optimized search index
    /// - Parameters:
    ///   - query: Normalized search query string (lowercased)
    ///   - field: Field to search in
    /// - Returns: Array of matching track IDs
    internal func searchTracks(query: String, field: SearchField) async -> [UUID] {
        await indexActor.search(query: query, field: field)
    }
}

/// Actor for thread-safe index operations
private actor IndexActor {
    /// In-memory index of tracks by ID
    private var tracksById: [UUID: Track] = [:]
    
    /// In-memory index of tracks by file path (for duplicate detection)
    private var tracksByPath: [String: UUID] = [:]
    
    /// Inverted search index: maps normalized search terms to sets of track IDs
    /// This enables O(1) lookup for search terms instead of O(n) linear search
    private var searchIndex: [String: Set<UUID>] = [:]
    
    /// Minimum search term length to index (to avoid indexing single characters)
    private let minSearchTermLength = 2
    
    func index(tracks: [Track]) throws {
        for track in tracks {
            // Validate track has non-empty file path
            guard !track.filePath.isEmpty else {
                throw LibraryIndexerError.invalidTrack
            }
            
            // Handle duplicates: if track with same path exists, replace it
            if let existingId = tracksByPath[track.filePath], existingId != track.id {
                // Remove old track from search index
                removeTrackFromSearchIndex(trackId: existingId)
                // Remove old track
                tracksById.removeValue(forKey: existingId)
            }
            
            // Add/update track
            tracksById[track.id] = track
            tracksByPath[track.filePath] = track.id
            
            // Add to search index
            addTrackToSearchIndex(track: track)
        }
    }
    
    func remove(track: Track) throws {
        guard tracksById[track.id] != nil else {
            throw LibraryIndexerError.trackNotFound
        }
        
        // Remove from search index
        removeTrackFromSearchIndex(trackId: track.id)
        
        tracksById.removeValue(forKey: track.id)
        tracksByPath.removeValue(forKey: track.filePath)
    }
    
    func clear() {
        tracksById.removeAll()
        tracksByPath.removeAll()
        searchIndex.removeAll()
    }
    
    func getTrack(by id: UUID) -> Track? {
        tracksById[id]
    }
    
    func getCount() -> Int {
        tracksById.count
    }
    
    func getAllTracks() -> [Track] {
        Array(tracksById.values)
    }
    
    /// Search tracks using the inverted index
    /// - Parameters:
    ///   - query: Normalized search query (lowercased)
    ///   - field: Field to search in
    /// - Returns: Array of matching track IDs
    func search(query: String, field: SearchField) -> [UUID] {
        guard !query.isEmpty else {
            return []
        }
        
        // For queries shorter than minimum, fall back to linear search
        // This supports single-character searches while keeping the index efficient
        if query.count < minSearchTermLength {
            return linearSearch(query: query, field: field)
        }
        
        var candidateIds = findCandidatesForQuery(query)
        
        guard !candidateIds.isEmpty else {
            return []
        }
        
        // Filter by field if needed and verify matches
        let matchingIds = candidateIds.filter { trackId in
            guard let track = tracksById[trackId] else { return false }
            return matchesQuery(track: track, query: query, field: field)
        }
        
        return Array(matchingIds)
    }
    
    /// Find candidate track IDs for a search query using multiple strategies
    /// - Parameter query: Normalized search query (lowercased)
    /// - Returns: Set of candidate track IDs
    private func findCandidatesForQuery(_ query: String) -> Set<UUID> {
        var candidateIds: Set<UUID> = []
        
        // Strategy 1: Direct lookup for the full query
        candidateIds.formUnion(findDirectMatches(for: query))
        
        // Strategy 2: Extract words from query and look them up
        candidateIds.formUnion(findWordBasedMatches(for: query))
        
        // Strategy 3: For substring matching (only if needed)
        candidateIds.formUnion(findSubstringMatches(for: query, existingMatches: candidateIds))
        
        return candidateIds
    }
    
    /// Strategy 1: Direct lookup for the full query
    /// - Parameter query: Search query
    /// - Returns: Set of matching track IDs
    private func findDirectMatches(for query: String) -> Set<UUID> {
        guard let directMatches = searchIndex[query] else {
            return []
        }
        return directMatches
    }
    
    /// Strategy 2: Extract words from query and look them up
    /// - Parameter query: Search query
    /// - Returns: Set of matching track IDs
    private func findWordBasedMatches(for query: String) -> Set<UUID> {
        var matches: Set<UUID> = []
        let wordSeparators = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "-_"))
        let queryWords = query.components(separatedBy: wordSeparators).filter { !$0.isEmpty }
        
        for word in queryWords where word.count >= minSearchTermLength {
            // Direct lookup for the word
            if let wordMatches = searchIndex[word] {
                matches.formUnion(wordMatches)
            }
            
            // Lookup prefixes of the word
            matches.formUnion(findPrefixMatches(for: word))
        }
        
        return matches
    }
    
    /// Find matches for all prefixes of a word
    /// - Parameter word: Word to find prefixes for
    /// - Returns: Set of matching track IDs
    private func findPrefixMatches(for word: String) -> Set<UUID> {
        var matches: Set<UUID> = []
        
        for i in minSearchTermLength...word.count {
            let prefix = String(word.prefix(i))
            if let prefixMatches = searchIndex[prefix] {
                matches.formUnion(prefixMatches)
            }
        }
        
        return matches
    }
    
    /// Strategy 3: For substring matching, check if query is a substring of indexed terms
    /// - Parameters:
    ///   - query: Search query
    ///   - existingMatches: Already found matches
    /// - Returns: Set of additional matching track IDs
    private func findSubstringMatches(for query: String, existingMatches: Set<UUID>) -> Set<UUID> {
        // Only do this if we haven't found many matches yet (to avoid full scan)
        guard existingMatches.count < 100, query.count <= 10 else {
            return []
        }
        
        var matches: Set<UUID> = []
        
        // Check indexed terms that could contain the query
        for (indexedTerm, trackIds) in searchIndex {
            if indexedTerm.contains(query) || query.contains(indexedTerm) {
                matches.formUnion(trackIds)
            }
        }
        
        return matches
    }
    
    /// Linear search fallback for short queries (e.g., single characters)
    /// - Parameters:
    ///   - query: Normalized search query (lowercased)
    ///   - field: Field to search in
    /// - Returns: Array of matching track IDs
    private func linearSearch(query: String, field: SearchField) -> [UUID] {
        var matchingIds: [UUID] = []
        
        for (trackId, track) in tracksById where matchesQuery(track: track, query: query, field: field) {
            matchingIds.append(trackId)
        }
        
        return matchingIds
    }
    
    // MARK: - Search Index Management
    
    /// Add a track to the search index
    private func addTrackToSearchIndex(track: Track) {
        // Index all searchable fields
        let fields = [
            track.title,
            track.artist,
            track.album
        ]
        
        for text in fields {
            let normalized = text.lowercased()
            let terms = extractSearchTerms(from: normalized)
            
            for term in terms {
                if searchIndex[term] == nil {
                    searchIndex[term] = Set<UUID>()
                }
                searchIndex[term]?.insert(track.id)
            }
        }
    }
    
    /// Remove a track from the search index
    private func removeTrackFromSearchIndex(trackId: UUID) {
        // Remove track ID from all search index entries
        for (term, trackIds) in searchIndex {
            var updatedIds = trackIds
            updatedIds.remove(trackId)
            if updatedIds.isEmpty {
                searchIndex.removeValue(forKey: term)
            } else {
                searchIndex[term] = updatedIds
            }
        }
    }
    
    /// Extract search terms from a string
    /// Indexes words and full strings for efficient searching
    private func extractSearchTerms(from text: String) -> [String] {
        var terms: Set<String> = []
        let normalized = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add the full normalized string
        if normalized.count >= minSearchTermLength {
            terms.insert(normalized)
        }
        
        // Index words (split by whitespace and common separators)
        let wordSeparators = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "-_"))
        let words = normalized.components(separatedBy: wordSeparators).filter { !$0.isEmpty }
        
        for word in words where word.count >= minSearchTermLength {
            terms.insert(word)
            // Also add prefixes of words for partial matching
            // e.g., "track" -> "tr", "tra", "trac", "track"
            for i in minSearchTermLength...word.count {
                let prefix = String(word.prefix(i))
                if prefix.count >= minSearchTermLength {
                    terms.insert(prefix)
                }
            }
        }
        
        // Also index character sequences for substring matching
        // This allows "track 50000" to be found by searching "50000"
        // But limit to reasonable length to avoid index bloat
        let maxSequenceLength = 20
        if normalized.count >= minSearchTermLength {
            for startIndex in normalized.indices {
                let remaining = String(normalized[startIndex...])
                let sequenceLength = min(remaining.count, maxSequenceLength)
                if sequenceLength >= minSearchTermLength {
                    let sequence = String(remaining.prefix(sequenceLength))
                    terms.insert(sequence)
                }
            }
        }
        
        return Array(terms)
    }
    
    /// Check if a track matches the search query
    private func matchesQuery(track: Track, query: String, field: SearchField) -> Bool {
        let normalizedQuery = query.lowercased()
        
        switch field {
        case .title:
            return track.title.lowercased().contains(normalizedQuery)
        case .artist:
            return track.artist.lowercased().contains(normalizedQuery)
        case .album:
            return track.album.lowercased().contains(normalizedQuery)
        case .all:
            return track.title.lowercased().contains(normalizedQuery) ||
                   track.artist.lowercased().contains(normalizedQuery) ||
                   track.album.lowercased().contains(normalizedQuery)
        }
    }
}
