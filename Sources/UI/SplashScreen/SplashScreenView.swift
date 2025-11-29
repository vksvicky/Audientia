//
//  SplashScreenView.swift
//  Audientia
//
//  Splash screen shown on app launch
//
//  Copyright © 2025 CycleRunCode Club. All rights reserved.
//

import Shared
import SwiftUI

/// Splash screen view similar to MediaMonkey's design
/// Shows app logo, name, year, and copyright information
@MainActor
public struct SplashScreenView: View {
    @ObservedObject private var settings: AppSettings
    @State private var isVisible = true
    
    private let splashDuration: TimeInterval = 5.0 // Show for 5 seconds
    
    public init(settings: AppSettings = AppSettings.shared) {
        self.settings = settings
    }
    
    public var body: some View {
        ZStack {
            // Semi-transparent background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            // Splash screen card
            VStack(spacing: 0) {
                // Logo section
                logoSection
                
                // App name
                Text("Audientia")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                // Year
                Text("2025")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 4)
                
                // Copyright
                Text("Copyright CycleRunCode Club 2025")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 30)
            }
            .frame(width: 400, height: 500)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black)
            )
            .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
            .opacity(isVisible ? 1.0 : 0.0)
            .scaleEffect(isVisible ? 1.0 : 0.95)
        }
    }
    
    private var logoSection: some View {
        VStack(spacing: 16) {
            // App icon or fallback music note
            if let icon = NSImage(named: "AppIcon") {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color("AccentColor"), Color("AccentColor").opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 4
                            )
                    )
                    .shadow(color: Color("AccentColor").opacity(0.5), radius: 10, x: 0, y: 5)
            } else {
                // Fallback: Music note icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color("AccentColor"), Color("AccentColor").opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(.white)
                }
                .shadow(color: Color("AccentColor").opacity(0.5), radius: 10, x: 0, y: 5)
            }
        }
        .padding(.top, 60)
        .padding(.bottom, 20)
    }
}

#Preview {
    SplashScreenView()
        .frame(width: 800, height: 600)
}
