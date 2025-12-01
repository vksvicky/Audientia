//
//  LanguageSettingsView.swift
//  Audientia
//
//  Language settings view for selecting application language
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Shared
import SwiftUI

/// View for language settings
struct LanguageSettingsView: View {
    @ObservedObject private var appSettings = AppSettings.shared
    @ObservedObject private var localisation = LocalisationManager.shared
    
    var body: some View {
        Form(content: {
            Section {
                Picker(localisation[LocalisationManager.language], selection: $appSettings.language) {
                    ForEach(Language.allCases, id: \.self) { language in
                        Text(language.displayName)
                            .tag(language)
                    }
                }
                .pickerStyle(.radioGroup)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Language Selection")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Choose your preferred language for the application interface. " +
                         "British English uses British spelling (visualiser, colour, minimise). " +
                         "American English uses American spelling (visualiser, color, minimize).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 8)
            } header: {
                Text(localisation[LocalisationManager.language])
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    PreviewRow(
                        key: "Audio " + (appSettings.language == .britishEnglish ? "Visualiser" : "Visualizer"),
                        value: localisation[LocalisationManager.audioVisualiser]
                    )
                    PreviewRow(
                        key: appSettings.language == .britishEnglish ? "Minimise" : "Minimize",
                        value: localisation[LocalisationManager.minimise]
                    )
                    PreviewRow(
                        key: appSettings.language == .britishEnglish ? "Visualiser Settings" : "Visualizer Settings",
                        value: localisation[LocalisationManager.visualiserSettings]
                    )
                }
            } header: {
                Text("Preview")
            }
        })
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// Preview row for language examples
private struct PreviewRow: View {
    let key: String
    let value: String
    
    var body: some View {
        HStack {
            Text(key)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#if DEBUG
struct LanguageSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        LanguageSettingsView()
            .frame(width: 600, height: 400)
    }
}
#endif
