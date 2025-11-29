//
//  SetupWizardView.swift
//  Audientia
//
//  Setup wizard view for first launch configuration
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import AppKit
import DataLayer
import Shared
import SwiftUI

/// Setup wizard view similar to MediaMonkey's design
/// Shows on first launch and can be relaunched from menu
@MainActor
// swiftlint:disable:next type_body_length
public struct SetupWizardView: View {
    @StateObject private var viewModel = SetupWizardViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLocation: URL?
    @State private var qrImage: NSImage?
    @State private var bmacImage: NSImage?
    
    public init() {}
    
    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content area
                HStack(spacing: 0) {
                    // Left navigation pane
                    navigationPane
                        .frame(width: 200)
                        .background(Color(NSColor.controlBackgroundColor))
                    
                    Divider()
                    
                    // Right content pane
                    contentPane
                        .frame(maxWidth: .infinity)
                        .padding(30)
                }
                
                // Footer
                footerView
            }
            .frame(width: 700, height: 550)
            .background(Color(NSColor.windowBackgroundColor))
            
            // Progress overlay when scanning
            if let coordinator = viewModel.scanCoordinator, coordinator.isScanning {
                scanProgressOverlay(coordinator: coordinator)
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.scanCoordinator?.showResults ?? false },
            set: { viewModel.scanCoordinator?.showResults = $0 }
        )) {
            if let coordinator = viewModel.scanCoordinator {
                ScanResultsView(
                    coordinator: coordinator,
                    isPresented: Binding(
                        get: { coordinator.showResults },
                        set: { coordinator.showResults = $0 }
                    )
                )
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Text("Setup Wizard").font(.system(size: 18, weight: .semibold)).foregroundColor(Color("AccentColor"))
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color("AccentColor").opacity(0.1))
    }
    
    // MARK: - Navigation Pane
    
    private var navigationPane: some View {
        List(SetupWizardStep.allCases, id: \.id) { step in
            Button(
                action: {
                    viewModel.goToStep(step)
                },
                label: {
                    HStack {
                        if step == viewModel.currentStep {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color("AccentColor"))
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.secondary)
                        }
                        Text(step.displayName)
                            .foregroundColor(step == viewModel.currentStep ? .primary : .secondary)
                    }
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            )
            .buttonStyle(.plain)
        }
        .listStyle(.sidebar)
    }
    
    // MARK: - Content Pane
    
    @ViewBuilder
    private var contentPane: some View {
        switch viewModel.currentStep {
        case .welcome:
            welcomeStep
        case .librarySetup:
            librarySetupStep
        case .preferences:
            preferencesStep
        case .support:
            supportStep
        }
    }
    
    // MARK: - Welcome Step
    
    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Welcome to Audientia").font(.system(size: 24, weight: .bold))
            Text("To get started, let's configure your music library and preferences.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 12) {
                Label("Scan and organize your music library", systemImage: "music.note.list")
                Label("Configure playback preferences", systemImage: "play.circle")
                Label("Set up library locations", systemImage: "folder")
            }
            .padding(.top, 20)
            Spacer()
        }
    }
    
    // MARK: - Library Setup Step
    
    private var librarySetupStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Library Setup").font(.system(size: 24, weight: .bold))
            Text("Scan the following locations for media:")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            // Library locations table
            VStack(spacing: 0) {
                // Table header
                HStack {
                    Text("Location")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Schedule")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 120)
                    Text("Media Type")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 120)
                    Spacer()
                        .frame(width: 30)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Table rows
                if viewModel.libraryLocations.isEmpty {
                    Text("No locations added")
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(Array(viewModel.libraryLocations.enumerated()), id: \.element) { _, location in
                        VStack(spacing: 0) {
                            libraryLocationRow(location)
                            Divider()
                        }
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
            
            // Add location button
            Button("Add Location >>") {
                addLocation()
            }
            .buttonStyle(.bordered)
            .padding(.top, 8)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func libraryLocationRow(_ location: URL) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill").foregroundColor(Color("AccentColor"))
            Text(location.path)
                .font(.system(size: 12))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .truncationMode(.middle)
            Picker("", selection: Binding(
                get: { viewModel.scanSchedule },
                set: { viewModel.scanSchedule = $0 }
            )) {
                ForEach(ScanSchedule.allCases, id: \.self) { schedule in
                    Text(schedule.displayName).tag(schedule)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 120)
            Text("Auto detection")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 120)
            Button {
                viewModel.removeLibraryLocation(location)
            } label: {
                Image(systemName: "minus.circle.fill").foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .frame(width: 30)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    private func addLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        
        if panel.runModal() == .OK, let url = panel.url {
            viewModel.addLibraryLocation(url)
        }
    }
    
    // MARK: - Preferences Step
    
    private var preferencesStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Preferences").font(.system(size: 24, weight: .bold))
            VStack(alignment: .leading, spacing: 16) {
                Toggle("Enable automatic library scanning", isOn: $viewModel.enableAutoScan)
                    .help("Automatically scan library locations for new music files")
                if viewModel.enableAutoScan {
                    Picker("Scan Schedule:", selection: $viewModel.scanSchedule) {
                        ForEach(ScanSchedule.allCases, id: \.self) { schedule in
                            Text(schedule.displayName).tag(schedule)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .padding(.top, 20)
            Spacer()
        }
    }
    
    // MARK: - Support Step
    
    private var supportStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Support Audientia").font(.system(size: 24, weight: .bold))
            Text("Audientia is free and open source. If you find it useful, consider supporting the project:")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            HStack(spacing: 30) {
                // QR Code
                VStack {
                    if let qrImage = qrImage {
                        Image(nsImage: qrImage)
                            .resizable()
                            .interpolation(.high)
                            .antialiased(true)
                            .frame(width: 200, height: 200)
                    } else {
                        // Fallback placeholder
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 200, height: 200)
                            .overlay(
                                Text("QR Code")
                                    .foregroundColor(.secondary)
                            )
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    if let bmacImage = bmacImage,
                       let coffeeURL = URL(string: "https://buymeacoffee.com/vksvicky") {
                        Link(destination: coffeeURL) {
                            Image(nsImage: bmacImage)
                                .resizable()
                                .interpolation(.high)
                                .antialiased(true)
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 60)
                        }
                        .buttonStyle(.plain)
                    } else {
                        // Fallback text link
                        if let coffeeURL = URL(string: "https://buymeacoffee.com/vksvicky") {
                            Link("buymeacoffee.com/vksvicky", destination: coffeeURL)
                                .font(.system(size: 14))
                                .foregroundColor(Color("AccentColor"))
                        }
                    }
                    
                    Text("Scan the QR code or visit the link to support the project.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .onAppear {
            loadQRImage()
            loadBMACImage()
        }
    }
    
    // MARK: - Image Loading Helpers
    
    private func loadQRImage() {
        qrImage = loadImage(named: "SupportQRCode")
    }
    
    private func loadBMACImage() {
        bmacImage = loadImage(named: "SupportBMAC")
    }
    
    private func loadImage(named name: String) -> NSImage? {
        // Try asset catalog first
        if let assetImage = NSImage(named: name) {
            return assetImage
        }
        // Try with subdirectory first
        if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "images"),
           let image = NSImage(contentsOf: url) {
            return image
        }
        // Try without subdirectory
        if let url = Bundle.main.url(forResource: name, withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            return image
        }
        // Try in Resources/images/ directly
        if let url = Bundle.main.resourceURL?.appendingPathComponent("images/\(name).png"),
           let image = NSImage(contentsOf: url) {
            return image
        }
        return nil
    }
    
    // MARK: - Scan Progress Overlay

    @ViewBuilder
    private func scanProgressOverlay(coordinator: LibraryScanCoordinator) -> some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 20) {
                    ProgressView(value: coordinator.progress, total: 1.0)
                        .progressViewStyle(.linear)
                        .frame(width: 400)
                    Text(coordinator.currentStatus)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    Text("\(Int(coordinator.progress * 100))%")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(30)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .frame(width: 500)
            }
    }

    // MARK: - Footer
    
    private var footerView: some View {
        HStack {
            // Options button removed - not needed for setup wizard
            // Users can access settings from the main app menu
            
            Spacer()
            
            if viewModel.canGoBack {
                Button("Previous") {
                    viewModel.previousStep()
                }
                .buttonStyle(.bordered)
            }
            
            if viewModel.canGoNext {
                Button("Next") {
                    viewModel.nextStep()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("AccentColor"))
            } else {
                Button("Done") {
                    viewModel.completeWizard()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("AccentColor"))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color("AccentColor").opacity(0.1))
    }
}

#Preview {
    SetupWizardView()
        .frame(width: 700, height: 550)
}
