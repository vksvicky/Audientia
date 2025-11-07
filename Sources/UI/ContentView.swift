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
        VStack(spacing: 0) {
            // Now Playing View
            NowPlayingView()
                .frame(maxHeight: .infinity)
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings.shared)
}
