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
        Form {
            Section("Layout Mode") {
                Picker("Layout Mode", selection: Binding(
                    get: { viewModel.currentLayout.layoutMode },
                    set: { viewModel.setLayoutMode($0) }
                )) {
                    ForEach(LayoutMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
            }
            
            Section("Panel Visibility") {
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
            
            Section("Panel Sizes") {
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
                            Text("\(Int(viewModel.currentLayout.panelSizes[panel] ?? 300)) points")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Section {
                Button("Save Layout") {
                    Task {
                        await viewModel.saveLayout()
                    }
                }
                .disabled(viewModel.isSaving)
                
                Button("Reset to Defaults") {
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
        .alert("Error", isPresented: .constant(viewModel.lastError != nil)) {
            Button("OK") {
                viewModel.clearLastError()
            }
        } message: {
            if let error = viewModel.lastError {
                Text(error.localizedDescription)
            }
        }
        .alert("Success", isPresented: .constant(viewModel.successMessage != nil)) {
            Button("OK") {
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

extension LayoutMode {
    var displayName: String {
        switch self {
        case .horizontalSplit: return "Horizontal Split"
        case .verticalSplit: return "Vertical Split"
        case .tabbed: return "Tabbed"
        case .floating: return "Floating"
        }
    }
}
