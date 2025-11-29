//
//  ScanResultsView.swift
//  Audientia
//
//  Scan results dialog similar to MediaMonkey's design
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import Shared
import SwiftUI

/// Scan results dialog view
@MainActor
public struct ScanResultsView: View {
    @ObservedObject var coordinator: LibraryScanCoordinator
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    
    public init(coordinator: LibraryScanCoordinator, isPresented: Binding<Bool>) {
        self.coordinator = coordinator
        self._isPresented = isPresented
    }
    
    public var body: some View {
        if let results = coordinator.scanResults {
            VStack(spacing: 0) {
                // Orange header
                HStack {
                    Text("Scan results")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { isPresented = false }, label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.system(size: 12))
                    })
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color("AccentColor"))
                
                // Dark gray body
                VStack(alignment: .leading, spacing: 16) {
                    Text("Search and update took \(results.formattedDuration)")
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                    
                    Text("Added \(results.newFiles) new files")
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                    
                    Text("Updated \(results.updatedFiles) files")
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                    
                    Text("Failed to add \(results.failedFiles) files")
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Text("Skipped \(results.skippedFiles) files (filtered or disabled in")
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                        Text("Library settings")
                            .foregroundColor(Color("AccentColor"))
                            .font(.system(size: 13))
                            .underline()
                        Text(")")
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                    }
                    
                    Toggle("Don't show this again", isOn: $coordinator.dontShowResultsAgain)
                        .font(.system(size: 12))
                        .padding(.top, 8)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                
                // Footer with close button
                HStack {
                    Spacer()
                    Button("CLOSE") {
                        if coordinator.dontShowResultsAgain {
                            UserDefaults.standard.set(true, forKey: "audientia.scan.dontShowResults")
                        }
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(16)
                }
                .background(Color(NSColor.controlBackgroundColor))
            }
            .frame(width: 500)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(8)
            .shadow(radius: 10)
        }
    }
}
