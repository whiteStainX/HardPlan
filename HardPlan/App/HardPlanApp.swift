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

    init() {
        print("✅ HardPlanApp: Initialized.")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
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
