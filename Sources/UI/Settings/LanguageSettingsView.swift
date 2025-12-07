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
@MainActor
struct LanguageSettingsView: View {
    @ObservedObject private var appSettings = AppSettings.shared
    @ObservedObject private var localisation = LocalisationManager.shared
    
    var body: some View {
        Form {
            Section {
                Picker(localisation[LocalisationManager.language], selection: $appSettings.language) {
                    ForEach(Language.allCases, id: \.self) { language in
                        Text(language.displayName)
                            .tag(language)
                    }
                }
                .pickerStyle(.radioGroup)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(localisation[LocalisationManager.languageSelection])
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(localisation[LocalisationManager.languageDescription])
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
                        key: localisation[LocalisationManager.audioVisualiser],
                        value: localisation[LocalisationManager.audioVisualiser]
                    )
                    PreviewRow(
                        key: localisation[LocalisationManager.minimise],
                        value: localisation[LocalisationManager.minimise]
                    )
                    PreviewRow(
                        key: localisation[LocalisationManager.visualiserSettings],
                        value: localisation[LocalisationManager.visualiserSettings]
                    )
                }
            } header: {
                Text(localisation[LocalisationManager.languagePreview])
            }
        }
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
