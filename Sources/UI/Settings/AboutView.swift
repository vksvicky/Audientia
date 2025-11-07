//
//  AboutView.swift
//  Audientia
//
//  About screen showing app and module versions
//

import Shared
import SwiftUI

/// SwiftUI view for the About screen
public struct AboutView: View {
    @ObservedObject private var settings: AppSettings
    
    public init(settings: AppSettings = AppSettings.shared) {
        self.settings = settings
    }
    
    public var body: some View {
        HStack(spacing: 20) {
            // App Icon
            if let icon = NSImage(named: "AppIcon") {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .frame(width: 128, height: 128)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.clear, lineWidth: 0)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .padding(.leading, 20)
            } else {
                // Fallback if icon not found
                Image(systemName: "music.note")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)
                    .frame(width: 128, height: 128)
                    .padding(.leading, 20)
            }
            
            VStack(alignment: .leading, spacing: 20) {
                // App Name (no version)
                Text(appName)
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 20)
                
                Divider()
                    
                    // Module/Plugin Versions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Modules & Plugins")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.bottom, 4)
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                // App version (in the list)
                                HStack {
                                    Text("Audientia")
                                        .font(.system(size: 12))
                                    Spacer()
                                    Text(settings.appVersion.description)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                
                                // Module versions
                                ForEach(
                                    settings.activeModuleVersions.sorted(by: { $0.key < $1.key }),
                                    id: \.key
                                ) { moduleName, version in
                                    HStack {
                                        Text(moduleName)
                                            .font(.system(size: 12))
                                        Spacer()
                                        Text(version.description)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        .frame(maxHeight: 200)
                    }
                    
                    // Copyright
                    if let copyright = copyrightString {
                        Text(copyright)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.7))
                            .padding(.bottom, 20)
                    }
                }
                .padding(.trailing, 20)
        }
        .frame(width: 550, height: 400)
        .padding()
    }
    
    private var appName: String {
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Audientia"
    }
    
    private var appVersion: String {
        if let infoDict = Bundle.main.infoDictionary,
           let shortVersion = infoDict["CFBundleShortVersionString"] as? String {
            return shortVersion
        }
        return settings.appVersion.description
    }
    
    private var copyrightString: String? {
        Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String
    }
}

#Preview {
    AboutView()
}
