//
//  MultiPaneLayoutViewModel.swift
//  Audientia
//
//  ViewModel for Multi-pane Layout System
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import os.log
import Shared
import SwiftUI

/// ViewModel for Multi-pane Layout System
/// Manages the MediaMonkey-style multi-pane interface with resizable panels
@MainActor
public final class MultiPaneLayoutViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current layout configuration
    @Published public private(set) var currentLayout: LayoutConfiguration = .default
    
    /// Whether layout is being saved
    @Published public private(set) var isSaving = false
    
    /// Last error that occurred
    @Published public private(set) var lastError: Error?
    
    /// Success message
    @Published public private(set) var successMessage: String?
    
    // MARK: - Private Properties
    
    private let layoutManager: any LayoutConfigurationManagerProtocol
    private let logger = Logger.userInterface
    
    // MARK: - Initialization
    
    public init(layoutManager: any LayoutConfigurationManagerProtocol = LayoutConfigurationManager()) {
        self.layoutManager = layoutManager
    }
    
    // MARK: - Public Methods
    
    /// Load current layout
    public func loadLayout() async {
        currentLayout = await layoutManager.loadLayout()
        logger.debug("Layout loaded")
    }
    
    /// Toggle panel visibility
    public func togglePanelVisibility(_ panel: LayoutPanel) {
        let currentVisibility = currentLayout.panelVisibility[panel] ?? false
        currentLayout.panelVisibility[panel] = !currentVisibility
        logger.debug("Panel \(panel.rawValue) visibility toggled to \(!currentVisibility)")
    }
    
    /// Update panel size
    public func updatePanelSize(_ panel: LayoutPanel, size: CGFloat) {
        // Clamp to minimum size
        let minSize: CGFloat = 100
        let clampedSize = max(size, minSize)
        currentLayout.panelSizes[panel] = clampedSize
        logger.debug("Panel \(panel.rawValue) size updated to \(clampedSize)")
    }
    
    /// Update layout mode
    public func setLayoutMode(_ mode: LayoutMode) {
        currentLayout.layoutMode = mode
        logger.debug("Layout mode changed to \(mode.rawValue)")
    }
    
    /// Save layout configuration
    public func saveLayout() async {
        isSaving = true
        lastError = nil
        
        do {
            try await layoutManager.saveLayout(currentLayout)
            successMessage = "Layout saved successfully"
            logger.info("Layout configuration saved")
        } catch {
            lastError = error
            logger.error("Failed to save layout: \(error.localizedDescription)")
        }
        
        isSaving = false
    }
    
    /// Clear success message
    public func clearSuccessMessage() {
        successMessage = nil
    }
}
