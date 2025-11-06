//
//  ContentView.swift
//  Audientia
//
//  Main content view
//

import SwiftUI
import Shared

struct ContentView: View {
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        VStack {
            Text("Audientia")
                .font(.largeTitle)
            Text("Version: \(settings.appVersion.description)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings.shared)
}

