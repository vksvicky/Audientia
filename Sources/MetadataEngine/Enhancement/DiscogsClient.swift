//
//  DiscogsClient.swift
//  MetadataEngine
//
//  Discogs API client implementation
//

import Foundation
@preconcurrency import Shared

/// Discogs API client implementation
public final class DiscogsClient: DiscogsClientProtocol, @unchecked Sendable {
    private let baseURL = "https://api.discogs.com"
    private let userAgent: String
    private let session: URLSession
    
    /// Initialise with custom user agent and URL session
    /// - Parameters:
    ///   - userAgent: User agent string (required by Discogs API)
    ///   - session: URLSession for network requests (default: shared session)
    public init(userAgent: String = "Audientia/1.0.0", session: URLSession = .shared) {
        self.userAgent = userAgent
        self.session = session
    }
    
    /// Search for releases by query
    /// - Parameter query: Search query (e.g., "Queen A Night at the Opera")
    /// - Returns: Array of matching releases
    /// - Throws: Error if search fails
    public func searchReleases(query: String) async throws -> [DiscogsRelease] {
        guard !query.isEmpty else {
            throw DiscogsError.invalidQuery(query)
        }
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/database/search?q=\(encodedQuery)&type=release&per_page=100"
        guard let url = URL(string: urlString) else {
            throw DiscogsError.invalidQuery(query)
        }
        
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw DiscogsError.invalidResponse("Invalid response type")
            }
            
            if httpResponse.statusCode == 429 {
                throw DiscogsError.rateLimitExceeded
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw DiscogsError.networkError("HTTP \(httpResponse.statusCode)")
            }
            
            let searchResponse = try JSONDecoder().decode(DiscogsSearchResponse.self, from: data)
            return searchResponse.results.compactMap { $0.toRelease() }
        } catch let error as DiscogsError {
            throw error
        } catch let error as DecodingError {
            throw DiscogsError.invalidResponse("Decoding error: \(error.localizedDescription)")
        } catch {
            throw DiscogsError.networkError(error.localizedDescription)
        }
    }
    
    /// Lookup a release by Discogs release ID
    /// - Parameter releaseID: The Discogs release ID
    /// - Returns: Release metadata if found
    /// - Throws: Error if lookup fails
    public func lookupRelease(releaseID: Int) async throws -> DiscogsRelease {
        guard releaseID > 0 else {
            throw DiscogsError.invalidReleaseID(releaseID)
        }
        
        let urlString = "\(baseURL)/releases/\(releaseID)"
        guard let url = URL(string: urlString) else {
            throw DiscogsError.invalidReleaseID(releaseID)
        }
        
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw DiscogsError.invalidResponse("Invalid response type")
            }
            
            if httpResponse.statusCode == 404 {
                throw DiscogsError.releaseNotFound(releaseID)
            }
            
            if httpResponse.statusCode == 429 {
                throw DiscogsError.rateLimitExceeded
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw DiscogsError.networkError("HTTP \(httpResponse.statusCode)")
            }
            
            let release = try JSONDecoder().decode(DiscogsReleaseResponse.self, from: data)
            return release.toRelease()
        } catch let error as DiscogsError {
            throw error
        } catch let error as DecodingError {
            throw DiscogsError.invalidResponse("Decoding error: \(error.localizedDescription)")
        } catch {
            throw DiscogsError.networkError(error.localizedDescription)
        }
    }
    
    /// Search for artists by query
    /// - Parameter query: Search query (e.g., "Queen")
    /// - Returns: Array of matching artists
    /// - Throws: Error if search fails
    public func searchArtists(query: String) async throws -> [DiscogsArtist] {
        guard !query.isEmpty else {
            throw DiscogsError.invalidQuery(query)
        }
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/database/search?q=\(encodedQuery)&type=artist&per_page=100"
        guard let url = URL(string: urlString) else {
            throw DiscogsError.invalidQuery(query)
        }
        
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw DiscogsError.invalidResponse("Invalid response type")
            }
            
            if httpResponse.statusCode == 429 {
                throw DiscogsError.rateLimitExceeded
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw DiscogsError.networkError("HTTP \(httpResponse.statusCode)")
            }
            
            let searchResponse = try JSONDecoder().decode(DiscogsSearchResponse.self, from: data)
            return searchResponse.results.compactMap { $0.toArtist() }
        } catch let error as DiscogsError {
            throw error
        } catch let error as DecodingError {
            throw DiscogsError.invalidResponse("Decoding error: \(error.localizedDescription)")
        } catch {
            throw DiscogsError.networkError(error.localizedDescription)
        }
    }
}

// MARK: - Response Models (Internal)

private struct DiscogsSearchResponse: Codable {
    let results: [DiscogsSearchResult]
}

private struct DiscogsSearchResult: Codable {
    let id: Int
    let title: String?
    let type: String
    let year: Int?
    let format: [String]?
    let genre: [String]?
    let style: [String]?
    let label: [String]?
    let catno: String?
    let country: String?
    let artist: String?
    let tracklist: [DiscogsTrackResponse]?
    
    func toRelease() -> DiscogsRelease? {
        guard type == "release", let title = title else {
            return nil
        }
        
        let artist = self.artist ?? "Unknown Artist"
        let format = format?.first
        let genres = genre ?? []
        let styles = style ?? []
        let tracks = tracklist?.map { track in
            DiscogsTrack(
                title: track.title,
                position: track.position,
                duration: track.duration
            )
        } ?? []
        let label = label?.first
        let catalogNumber = catno
        
        return DiscogsRelease(
            id: id,
            title: title,
            artist: artist,
            year: year,
            format: format,
            genres: genres,
            styles: styles,
            tracks: tracks,
            label: label,
            catalogNumber: catalogNumber,
            country: country
        )
    }
    
    func toArtist() -> DiscogsArtist? {
        guard type == "artist", let title = title else {
            return nil
        }
        
        return DiscogsArtist(
            id: id,
            name: title,
            profile: nil,
            realName: nil
        )
    }
}

private struct DiscogsReleaseResponse: Codable {
    let id: Int
    let title: String
    let artists: [DiscogsArtistResponse]?
    let year: Int?
    let formats: [DiscogsFormat]?
    let genres: [String]?
    let styles: [String]?
    let tracklist: [DiscogsTrackResponse]?
    let labels: [DiscogsLabel]?
    let country: String?
    
    func toRelease() -> DiscogsRelease {
        let artist = artists?.first?.name ?? "Unknown Artist"
        let artistIDs = artists?.compactMap { $0.id } ?? []
        let format = formats?.first?.name
        let genres = self.genres ?? []
        let styles = self.styles ?? []
        let tracks = tracklist?.map { track in
            DiscogsTrack(
                title: track.title,
                position: track.position,
                duration: track.duration
            )
        } ?? []
        let label = labels?.first?.name
        let catalogNumber = labels?.first?.catno
        
        return DiscogsRelease(
            id: id,
            title: title,
            artist: artist,
            artistIDs: artistIDs,
            year: year,
            format: format,
            genres: genres,
            styles: styles,
            tracks: tracks,
            label: label,
            catalogNumber: catalogNumber,
            country: country
        )
    }
}

private struct DiscogsArtistResponse: Codable {
    let id: Int?
    let name: String
}

private struct DiscogsFormat: Codable {
    let name: String
}

private struct DiscogsTrackResponse: Codable {
    let title: String
    let position: String?
    let duration: String?
}

private struct DiscogsLabel: Codable {
    let name: String
    let catno: String?
}
