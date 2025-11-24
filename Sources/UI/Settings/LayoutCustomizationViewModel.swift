//
//  LayoutCustomizationViewModel.swift
//  Audientia
//
//  ViewModel for Layout Customization UI
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Foundation
import os.log
import Shared
import SwiftUI

/// ViewModel for Layout Customization UI
@MainActor
public final class LayoutCustomizationViewModel: ObservableObject {
    
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
    
    /// Update panel visibility
    public func setPanelVisibility(_ panel: LayoutPanel, visible: Bool) {
        currentLayout.panelVisibility[panel] = visible
    }
    
    /// Update panel size
    public func setPanelSize(_ panel: LayoutPanel, size: CGFloat) {
        currentLayout.panelSizes[panel] = size
    }
    
    /// Update layout mode
    public func setLayoutMode(_ mode: LayoutMode) {
        currentLayout.layoutMode = mode
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
    
    /// Reset to default layout
    public func resetToDefault() async {
        do {
            try await layoutManager.resetToDefault()
            currentLayout = await layoutManager.loadLayout()
            successMessage = "Layout reset to defaults"
            logger.info("Layout reset to defaults")
        } catch {
            lastError = error
            logger.error("Failed to reset layout: \(error.localizedDescription)")
        }
    }
    
    /// Clear success message
    public func clearSuccessMessage() {
        successMessage = nil
    }

    /// Clear the last error shown to the user
    public func clearLastError() {
        lastError = nil
    }
}
