//
//  LayoutCustomisationView.swift
//  Audientia
//
//  Layout Customization UI
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Shared
import SwiftUI

/// Layout customization view
/// BDD: As a user, I want to customize my layout and have it saved
@MainActor
public struct LayoutCustomisationView: View {
    @StateObject private var viewModel: LayoutCustomisationViewModel
    
    public init(viewModel: LayoutCustomisationViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            _viewModel = StateObject(wrappedValue: LayoutCustomisationViewModel())
        }
    }
    
    public var body: some View {
        let localisation = LocalisationManager.shared
        return Form {
            Section(localisation[LocalisationManager.layoutMode]) {
                Picker(localisation[LocalisationManager.layoutMode], selection: Binding(
                    get: { viewModel.currentLayout.layoutMode },
                    set: { viewModel.setLayoutMode($0) }
                )) {
                    ForEach(LayoutMode.allCases, id: \.self) { mode in
                        Text(modeDisplayName(mode, localisation: localisation)).tag(mode)
                    }
                }
            }
            
            Section(localisation[LocalisationManager.panelVisibility]) {
                ForEach(LayoutPanel.allCases, id: \.self) { panel in
                    Toggle(
                        panel.displayName,
                        isOn: Binding(
                            get: { viewModel.currentLayout.panelVisibility[panel] ?? false },
                            set: { viewModel.setPanelVisibility(panel, visible: $0) }
                        )
                    )
                }
            }
            
            Section(localisation[LocalisationManager.panelSizes]) {
                ForEach(LayoutPanel.allCases, id: \.self) { panel in
                    if viewModel.currentLayout.panelVisibility[panel] ?? false {
                        VStack(alignment: .leading) {
                            Text(panel.displayName)
                            Slider(
                                value: Binding(
                                    get: { viewModel.currentLayout.panelSizes[panel] ?? 300 },
                                    set: { viewModel.setPanelSize(panel, size: $0) }
                                ),
                                in: 100...800,
                                step: 10
                            )
                            Text(
                                "\(Int(viewModel.currentLayout.panelSizes[panel] ?? 300)) "
                                + "\(localisation[LocalisationManager.points])"
                            )
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Section {
                Button(localisation[LocalisationManager.saveLayout]) {
                    Task {
                        await viewModel.saveLayout()
                    }
                }
                .disabled(viewModel.isSaving)
                
                Button(localisation[LocalisationManager.resetToDefaults]) {
                    Task {
                        await viewModel.resetToDefault()
                    }
                }
            }
        }
        .padding()
        .task {
            await viewModel.loadLayout()
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
        .alert(
            localisation[LocalisationManager.layoutSuccess],
            isPresented: .constant(viewModel.successMessage != nil)
        ) {
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

// MARK: - Display Names

@MainActor
private func modeDisplayName(_ mode: LayoutMode, localisation: LocalisationManager) -> String {
    switch mode {
    case .horizontalSplit: return localisation[LocalisationManager.horizontalSplit]
    case .verticalSplit: return localisation[LocalisationManager.verticalSplit]
    case .tabbed: return localisation[LocalisationManager.tabbed]
    case .floating: return localisation[LocalisationManager.floating]
    }
}
