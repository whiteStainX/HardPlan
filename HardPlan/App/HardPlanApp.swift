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

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .task {
                    appState.loadData()
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
