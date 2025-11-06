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
        VStack {
            Text("Audientia")
                .font(.largeTitle)
            Text("Version: \(versionString)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 400, minHeight: 300)
    }
    
    private var versionString: String {
        // Try to get version from Info.plist first (most accurate)
        if let infoDict = Bundle.main.infoDictionary,
           let shortVersion = infoDict["CFBundleShortVersionString"] as? String {
            return shortVersion
        }
        // Fallback to AppSettings version
        return settings.appVersion.description
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings.shared)
}
