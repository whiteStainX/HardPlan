//
//  HardPlanApp.swift
//  HardPlan
//
//  Created by HUANG SONG on 27/11/25.
//

import SwiftUI

@main
struct HardPlanApp: App {
    @StateObject private var appState = AppState()
    
    // 1. Flag to ensure animation only plays on the very first launch of a session
    private static var hasLaunchedBefore = false
    
    // 2. Initialize isLoading based on the flag
    @State private var isLoading = !Self.hasLaunchedBefore

    var body: some Scene {
        WindowGroup {
            if isLoading {
                SplashScreenView()
                    .onAppear {
                        // Increased delay to let the full animation play out
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                isLoading = false
                                
                                // 3. Mark that the first launch has happened
                                Self.hasLaunchedBefore = true
                            }
                        }
                    }
            } else {
                ContentView()
                    .environmentObject(appState)
                    .onAppear(perform: appState.loadData)
            }
        }
    }
}

private struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.userProfile == nil {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
    }
}
