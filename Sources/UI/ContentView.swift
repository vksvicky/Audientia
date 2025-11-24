//
//  ContentView.swift
//  Audientia
//
//  Main content view
//

import Shared
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        TabView {
            NowPlayingView()
                .tabItem {
                    Label("Now Playing", systemImage: "music.note.house")
                }
            
            DeviceSyncView()
                .tabItem {
                    Label("Device Sync", systemImage: "externaldrive.connected.to.line.below")
                }
            
            MultiPaneLayoutView()
                .tabItem {
                    Label("Workspace", systemImage: "rectangle.3.offgrid")
                }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings.shared)
}
