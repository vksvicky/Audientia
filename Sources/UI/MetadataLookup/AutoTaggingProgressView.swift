//
//  AutoTaggingProgressView.swift
//  Audientia - Metadata Lookup UI
//
//  SwiftUI view that displays auto-tagging progress information
//

import AppKit
import SwiftUI

public struct AutoTaggingProgressView: View {
    @ObservedObject private var viewModel: AutoTaggingProgressViewModel
    
    public init(viewModel: AutoTaggingProgressViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Auto-tagging Progress")
                    .font(.headline)
                Spacer()
                if viewModel.isRunning {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
            
            ProgressView(value: viewModel.progress)
                .progressViewStyle(.linear)
            
            Text(viewModel.statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if !viewModel.currentTrackName.isEmpty {
                Text("Current track: \(viewModel.currentTrackName)")
                    .font(.footnote)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}
