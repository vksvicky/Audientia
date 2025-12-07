//
//  ThemeSelectorView.swift
//  Audientia
//
//  Theme Selector UI
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Shared
import SwiftUI

/// Theme selector view
/// BDD: As a user, I want to select a theme and have it persist
@MainActor
public struct ThemeSelectorView: View {
    @StateObject private var viewModel: ThemeSelectorViewModel
    
    public init(viewModel: ThemeSelectorViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            _viewModel = StateObject(wrappedValue: ThemeSelectorViewModel())
        }
    }
    
    public var body: some View {
        let localisation = LocalisationManager.shared
        return Form {
            Section(localisation[LocalisationManager.themeTheme]) {
                Picker(localisation[LocalisationManager.themeTheme], selection: Binding(
                    get: { viewModel.currentTheme },
                    set: { theme in
                        Task {
                            await viewModel.selectTheme(theme)
                        }
                    }
                )) {
                    ForEach(viewModel.availableThemes, id: \.identifier) { theme in
                        Text(theme.name).tag(theme)
                    }
                }
                .disabled(viewModel.isSaving)
            }
            
            Section {
                Button(localisation[LocalisationManager.resetToDefault]) {
                    Task {
                        await viewModel.resetToDefault()
                    }
                }
                .disabled(viewModel.isSaving)
            }
        }
        .padding()
        .task {
            await viewModel.loadThemes()
        }
        .alert(localisation[LocalisationManager.error], isPresented: .constant(viewModel.lastError != nil)) {
            Button(localisation[LocalisationManager.apply]) {
                viewModel.clearLastError()
            }
        } message: {
            if let error = viewModel.lastError {
                Text(error.localizedDescription)
            }
        }
        .alert(localisation[LocalisationManager.success], isPresented: .constant(viewModel.successMessage != nil)) {
            Button(localisation[LocalisationManager.apply]) {
                viewModel.clearSuccessMessage()
            }
        } message: {
            if let message = viewModel.successMessage {
                Text(message)
            }
        }
    }
}
