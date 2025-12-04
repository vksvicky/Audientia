//
//  MinimizeButtonTarget.swift
//  Audientia
//
//  Target class for minimize button in title bar
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import os.log
@preconcurrency import Shared
import SwiftUI

/// Target class for minimize button in title bar
class MinimizeButtonTarget: NSObject {
    let viewModel: NowPlayingViewModel
    
    init(viewModel: NowPlayingViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    @objc func minimize() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            var appDelegate: AppDelegate?
            appDelegate = AppDelegate.shared
            
            if appDelegate == nil {
                appDelegate = NSApplication.shared.delegate as? AppDelegate
            }
            
            if appDelegate == nil,
               let window = NSApplication.shared.windows.first(where: { $0.isMainWindow || $0.isKeyWindow }) {
                appDelegate = window.delegate as? AppDelegate
            }
            
            guard let appDelegate = appDelegate else {
                let delegateDescription = String(describing: NSApplication.shared.delegate)
                Logger.userInterface.error("Failed to get AppDelegate - delegate: \(delegateDescription)")
                return
            }
            
            appDelegate.minimizeToPlayer(nowPlayingViewModel: self.viewModel)
        }
    }
}
