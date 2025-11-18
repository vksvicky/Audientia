//
//  MusicBrainzClient.swift
//  MetadataEngine
//
//  MusicBrainz API client implementation
//

import Foundation
@preconcurrency import Shared

/// MusicBrainz API client implementation
public final class MusicBrainzClient: MusicBrainzClientProtocol, @unchecked Sendable {
    private let baseURL = "https://musicbrainz.org/ws/2"
    private let userAgent: String
    private let session: URLSession
    
    /// Initialize with custom user agent and URL session
    /// - Parameters:
    ///   - userAgent: User agent string (required by MusicBrainz API)
    ///   - session: URLSession for network requests (default: shared session)
    public init(userAgent: String = "Audientia/1.0.0", session: URLSession = .shared) {
        self.userAgent = userAgent
        self.session = session
    }
    
    /// Lookup a recording by MusicBrainz recording ID
    /// - Parameter recordingID: The MusicBrainz recording ID (MBID)
    /// - Returns: Recording metadata if found
    /// - Throws: Error if lookup fails
    public func lookupRecording(recordingID: String) async throws -> MusicBrainzRecording {
        guard !recordingID.isEmpty else {
            throw MusicBrainzError.invalidRecordingID(recordingID)
        }
        
        let urlString = "\(baseURL)/recording/\(recordingID)?fmt=json&inc=artists+releases+genres"
        guard let url = URL(string: urlString) else {
            throw MusicBrainzError.invalidRecordingID(recordingID)
        }
        
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MusicBrainzError.invalidResponse("Invalid response type")
            }
            
            if httpResponse.statusCode == 404 {
                throw MusicBrainzError.recordingNotFound(recordingID)
            }
            
            if httpResponse.statusCode == 503 {
                throw MusicBrainzError.rateLimitExceeded
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw MusicBrainzError.networkError("HTTP \(httpResponse.statusCode)")
            }
            
            let recording = try JSONDecoder().decode(MusicBrainzRecordingResponse.self, from: data)
            return recording.toRecording()
        } catch let error as MusicBrainzError {
            throw error
        } catch let error as DecodingError {
            throw MusicBrainzError.invalidResponse("Decoding error: \(error.localizedDescription)")
        } catch {
            throw MusicBrainzError.networkError(error.localizedDescription)
        }
    }
    
    /// Search for recordings by query
    /// - Parameter query: Search query (e.g., "artist:Queen title:Bohemian Rhapsody")
    /// - Returns: Array of matching recordings
    /// - Throws: Error if search fails
    public func searchRecordings(query: String) async throws -> [MusicBrainzRecording] {
        guard !query.isEmpty else {
            throw MusicBrainzError.invalidQuery(query)
        }
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/recording?query=\(encodedQuery)&fmt=json&limit=100"
        guard let url = URL(string: urlString) else {
            throw MusicBrainzError.invalidQuery(query)
        }
        
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MusicBrainzError.invalidResponse("Invalid response type")
            }
            
            if httpResponse.statusCode == 503 {
                throw MusicBrainzError.rateLimitExceeded
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw MusicBrainzError.networkError("HTTP \(httpResponse.statusCode)")
            }
            
            let searchResponse = try JSONDecoder().decode(
                MusicBrainzSearchResponse<MusicBrainzRecordingResponse>.self,
                from: data
            )
            return searchResponse.recordings.map { $0.toRecording() }
        } catch let error as MusicBrainzError {
            throw error
        } catch let error as DecodingError {
            throw MusicBrainzError.invalidResponse("Decoding error: \(error.localizedDescription)")
        } catch {
            throw MusicBrainzError.networkError(error.localizedDescription)
        }
    }
    
    /// Lookup a release by MusicBrainz release ID
    /// - Parameter releaseID: The MusicBrainz release ID (MBID)
    /// - Returns: Release metadata if found
    /// - Throws: Error if lookup fails
    public func lookupRelease(releaseID: String) async throws -> MusicBrainzRelease {
        guard !releaseID.isEmpty else {
            throw MusicBrainzError.invalidReleaseID(releaseID)
        }
        
        let urlString = "\(baseURL)/release/\(releaseID)?fmt=json&inc=artists+recordings+genres"
        guard let url = URL(string: urlString) else {
            throw MusicBrainzError.invalidReleaseID(releaseID)
        }
        
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MusicBrainzError.invalidResponse("Invalid response type")
            }
            
            if httpResponse.statusCode == 404 {
                throw MusicBrainzError.releaseNotFound(releaseID)
            }
            
            if httpResponse.statusCode == 503 {
                throw MusicBrainzError.rateLimitExceeded
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw MusicBrainzError.networkError("HTTP \(httpResponse.statusCode)")
            }
            
            let release = try JSONDecoder().decode(MusicBrainzReleaseResponse.self, from: data)
            return release.toRelease()
        } catch let error as MusicBrainzError {
            throw error
        } catch let error as DecodingError {
            throw MusicBrainzError.invalidResponse("Decoding error: \(error.localizedDescription)")
        } catch {
            throw MusicBrainzError.networkError(error.localizedDescription)
        }
    }
    
    /// Search for releases by query
    /// - Parameter query: Search query (e.g., "artist:Queen release:A Night at the Opera")
    /// - Returns: Array of matching releases
    /// - Throws: Error if search fails
    public func searchReleases(query: String) async throws -> [MusicBrainzRelease] {
        guard !query.isEmpty else {
            throw MusicBrainzError.invalidQuery(query)
        }
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/release?query=\(encodedQuery)&fmt=json&limit=100"
        guard let url = URL(string: urlString) else {
            throw MusicBrainzError.invalidQuery(query)
        }
        
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MusicBrainzError.invalidResponse("Invalid response type")
            }
            
            if httpResponse.statusCode == 503 {
                throw MusicBrainzError.rateLimitExceeded
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw MusicBrainzError.networkError("HTTP \(httpResponse.statusCode)")
            }
            
            let searchResponse = try JSONDecoder().decode(
                MusicBrainzSearchResponse<MusicBrainzReleaseResponse>.self,
                from: data
            )
            return searchResponse.releases.map { $0.toRelease() }
        } catch let error as MusicBrainzError {
            throw error
        } catch let error as DecodingError {
            throw MusicBrainzError.invalidResponse("Decoding error: \(error.localizedDescription)")
        } catch {
            throw MusicBrainzError.networkError(error.localizedDescription)
        }
    }
}

// MARK: - Response Models (Internal)

private struct MusicBrainzRecordingResponse: Codable {
    let id: String
    let title: String
    let artistCredit: [ArtistCredit]?
    let releases: [ReleaseInfo]?
    let tags: [Tag]?
    let length: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artistCredit = "artist-credit"
        case releases
        case tags
        case length
    }
    
    func toRecording() -> MusicBrainzRecording {
        let artist = artistCredit?.first?.name ?? "Unknown Artist"
        let artistIDs = artistCredit?.compactMap { $0.artist?.id } ?? []
        let release = releases?.first?.title
        let releaseID = releases?.first?.id
        let date = releases?.first?.date.flatMap { extractYear(from: $0) }
        let trackNumber = releases?.first?.media?.first?.tracks?.first?.number.flatMap { Int($0) }
        let discNumber = releases?.first?.media?.first?.position.flatMap { Int($0) }
        let genres = tags?.map { $0.name } ?? []
        let duration = length
        
        return MusicBrainzRecording(
            id: id,
            title: title,
            artist: artist,
            artistIDs: artistIDs,
            release: release,
            releaseID: releaseID,
            date: date,
            trackNumber: trackNumber,
            discNumber: discNumber,
            genres: genres,
            duration: duration
        )
    }
}

private struct MusicBrainzReleaseResponse: Codable {
    let id: String
    let title: String
    let artistCredit: [ArtistCredit]?
    let date: String?
    let releaseGroup: ReleaseGroup?
    let media: [Media]?
    let tags: [Tag]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artistCredit = "artist-credit"
        case date
        case releaseGroup = "release-group"
        case media
        case tags
    }
    
    func toRelease() -> MusicBrainzRelease {
        let artist = artistCredit?.first?.name ?? "Unknown Artist"
        let artistIDs = artistCredit?.compactMap { $0.artist?.id } ?? []
        let year = date.flatMap { extractYear(from: $0) }
        let type = releaseGroup?.primaryType
        let trackCount = media?.flatMap { $0.tracks ?? [] }.count
        let discCount = media?.count
        let genres = tags?.map { $0.name } ?? []
        let tracks = media?.flatMap { mediaItem in
            (mediaItem.tracks ?? []).map { track in
                MusicBrainzRecording(
                    id: track.recording?.id ?? "",
                    title: track.title ?? "Unknown",
                    artist: artist,
                    artistIDs: artistIDs,
                    release: title,
                    releaseID: id,
                    date: year,
                    trackNumber: track.number.flatMap { Int($0) },
                    discNumber: mediaItem.position.flatMap { Int($0) },
                    genres: genres,
                    duration: track.length
                )
            }
        } ?? []
        
        return MusicBrainzRelease(
            id: id,
            title: title,
            artist: artist,
            artistIDs: artistIDs,
            date: year,
            type: type,
            trackCount: trackCount,
            discCount: discCount,
            genres: genres,
            tracks: tracks
        )
    }
}

private struct MusicBrainzSearchResponse<T: Codable>: Codable {
    let recordings: [T]
    let releases: [T]
    
    enum CodingKeys: String, CodingKey {
        case recordings
        case releases
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        recordings = (try? container.decode([T].self, forKey: .recordings)) ?? []
        releases = (try? container.decode([T].self, forKey: .releases)) ?? []
    }
}

private struct ArtistCredit: Codable {
    let name: String
    let artist: Artist?
}

private struct Artist: Codable {
    let id: String
}

private struct ReleaseInfo: Codable {
    let id: String
    let title: String
    let date: String?
    let media: [Media]?
}

private struct ReleaseGroup: Codable {
    let primaryType: String?
}

private struct Media: Codable {
    let position: String?
    let tracks: [TrackInfo]?
}

private struct TrackInfo: Codable {
    let number: String?
    let title: String?
    let length: Int?
    let recording: RecordingInfo?
}

private struct RecordingInfo: Codable {
    let id: String
}

private struct Tag: Codable {
    let name: String
}

private func extractYear(from dateString: String) -> Int? {
    // Extract year from date string (e.g., "1975", "1975-10-31", "1975-10")
    let components = dateString.split(separator: "-")
    return components.first.flatMap { Int($0) }
}
