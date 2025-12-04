//
//  HomeContentView.swift
//  Audientia
//
//  Home tab content view with recently played, recently added, and other sections
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

@preconcurrency import Shared
import SwiftUI

/// Home tab content view displaying recently played, recently added, most played, and favourites
struct HomeContentView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome to Audientia")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("Your powerful media library manager")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Recently Played Section
                recentlyPlayedSection
                
                // Recently Added Section
                recentlyAddedSection
                
                // Most Played Section
                mostPlayedSection
                
                // Favourites Section
                favouritesSection
                
                // Quick Links
                VStack(alignment: .leading, spacing: 12) {
                    Text("Get Started")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        if let url = URL(string: "https://github.com/vksvicky/Audientia") {
                            Link(">> What's New?", destination: url)
                            Link(">> Introduction", destination: url)
                            Link(">> Add files to the library", destination: url)
                            Link(">> Play files", destination: url)
                            Link(">> Update/Edit your files", destination: url)
                            Link(">> Sync your files", destination: url)
                        }
                    }
                    .font(.system(size: 13))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(30)
        }
        .task {
            await viewModel.refresh()
        }
    }
    
    // MARK: - Recently Played Section
    
    private var recentlyPlayedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENTLY PLAYED")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            
            if viewModel.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading...")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            } else if viewModel.recentlyPlayedTracks.isEmpty {
                Text("No recently played tracks")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.recentlyPlayedTracks.prefix(10)) { track in
                            AlbumCardView(track: track)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    // MARK: - Recently Added Section
    
    private var recentlyAddedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENTLY ADDED")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            
            if viewModel.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading...")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            } else if viewModel.recentlyAddedTracks.isEmpty {
                Text("No recently added tracks")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.recentlyAddedTracks.prefix(10)) { track in
                            AlbumCardView(track: track)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    // MARK: - Most Played Section
    
    private var mostPlayedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MOST PLAYED")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            
            if viewModel.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading...")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            } else if viewModel.mostPlayedTracks.isEmpty {
                Text("No most played tracks")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.mostPlayedTracks.prefix(10)) { track in
                            AlbumCardView(track: track)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    // MARK: - Favourites Section
    
    private var favouritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FAVOURITES")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            
            if viewModel.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading...")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            } else if viewModel.favouriteTracks.isEmpty {
                Text("No favourite tracks")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.favouriteTracks.prefix(10)) { track in
                            AlbumCardView(track: track)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

// MARK: - Album Card View

private struct AlbumCardView: View {
    let track: Track
    
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 30))
                        .foregroundColor(.secondary)
                )
            
            VStack(spacing: 2) {
                Text(track.album.isEmpty ? track.title : track.album)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(track.artist)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(width: 100)
    }
}

// MARK: - Album Placeholder View

private struct AlbumPlaceholderView: View {
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 30))
                        .foregroundColor(.secondary)
                )
            
            Text("Album")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(width: 100)
    }
}
