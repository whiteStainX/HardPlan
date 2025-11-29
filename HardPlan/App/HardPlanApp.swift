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
    @State private var isLoading = true

    var body: some Scene {
        WindowGroup {
            if isLoading {
                SplashScreenView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                isLoading = false
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
