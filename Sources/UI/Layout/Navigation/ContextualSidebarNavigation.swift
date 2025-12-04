//
//  ContextualSidebarNavigation.swift
//  Audientia
//
//  Tab-specific navigation content for contextual sidebar
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import SwiftUI

// MARK: - Home Tab Navigation

struct HomeNavigationContent: View {
    var onImportFiles: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SidebarSection(title: "QUICK ACCESS") {
                SidebarNavItem(icon: "clock.arrow.circlepath", title: "Recently Played")
                SidebarNavItem(icon: "plus.circle", title: "Recently Added")
                SidebarNavItem(icon: "chart.bar", title: "Most Played")
                SidebarNavItem(icon: "heart", title: "Favourites")
            }
            
            SidebarSection(title: "ACTIONS") {
                SidebarActionButton(icon: "plus", title: "Import Files") {
                    onImportFiles?()
                }
                SidebarActionButton(icon: "gearshape", title: "Settings") {
                    onOpenSettings?()
                }
            }
        }
    }
}

// MARK: - Library Tab Navigation

struct LibraryNavigationContent: View {
    @ObservedObject var libraryBrowserViewModel: LibraryBrowserViewModel
    @ObservedObject var statisticsViewModel: LibraryStatisticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SidebarSection(title: "BROWSE BY") {
                SidebarNavItem(
                    icon: "music.note.list",
                    title: "All Tracks",
                    count: statisticsViewModel.statistics?.trackCount,
                    action: {
                        Task {
                            await libraryBrowserViewModel.setBrowseMode(.allTracks)
                        }
                    }
                )
                SidebarNavItem(
                    icon: "person.2",
                    title: "Artists",
                    count: statisticsViewModel.statistics?.artistCount,
                    action: {
                        Task {
                            await libraryBrowserViewModel.setBrowseMode(.artists)
                        }
                    }
                )
                SidebarNavItem(
                    icon: "opticaldisc",
                    title: "Albums",
                    count: statisticsViewModel.statistics?.albumCount,
                    action: {
                        Task {
                            await libraryBrowserViewModel.setBrowseMode(.albums)
                        }
                    }
                )
                SidebarNavItem(
                    icon: "guitars",
                    title: "Genres",
                    action: {
                        Task {
                            await libraryBrowserViewModel.setBrowseMode(.genres)
                        }
                    }
                )
                SidebarNavItem(
                    icon: "calendar",
                    title: "Years",
                    action: {
                        Task {
                            await libraryBrowserViewModel.setBrowseMode(.years)
                        }
                    }
                )
                SidebarNavItem(
                    icon: "folder",
                    title: "Folders",
                    action: {
                        Task {
                            await libraryBrowserViewModel.setBrowseMode(.folders)
                        }
                    }
                )
            }
            
            SidebarSection(title: "FILTER BY GENRE") {
                GenreFilterSection(viewModel: libraryBrowserViewModel)
            }
        }
    }
}

// MARK: - Playlists Tab Navigation

struct PlaylistsNavigationContent: View {
    @ObservedObject var playlistSidebarViewModel: PlaylistSidebarViewModel
    @ObservedObject var smartPlaylistViewModel: SmartPlaylistViewModel
    var onCreatePlaylist: (() -> Void)?
    var onCreateSmartPlaylist: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SidebarSection(title: "PLAYLISTS") {
                PlaylistListSection(viewModel: playlistSidebarViewModel)
            }
            
            SidebarActionButton(icon: "plus", title: "New Playlist") {
                onCreatePlaylist?()
            }
            
            SidebarSection(title: "SMART PLAYLISTS") {
                SmartPlaylistSection(viewModel: smartPlaylistViewModel)
            }
            
            SidebarActionButton(icon: "gearshape", title: "New Smart Playlist") {
                onCreateSmartPlaylist?()
            }
        }
    }
}

// MARK: - Devices Tab Navigation

struct DevicesNavigationContent: View {
    @ObservedObject var deviceSidebarViewModel: DeviceSidebarViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SidebarSection(title: "CONNECTED") {
                DeviceListSection(viewModel: deviceSidebarViewModel)
            }
            
            SidebarSection(title: "SYNC OPTIONS") {
                SyncOptionsSection(viewModel: deviceSidebarViewModel)
            }
        }
    }
}

// MARK: - Visualiser Tab Navigation

struct VisualiserNavigationContent: View {
    @ObservedObject var audioVisualiserViewModel: AudioVisualiserViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SidebarSection(title: "VISUALISATION STYLE") {
                VisualisationStyleSection(viewModel: audioVisualiserViewModel)
            }
            
            SidebarSection(title: "SETTINGS") {
                VisualisationSettingsSection(viewModel: audioVisualiserViewModel)
            }
        }
    }
}
