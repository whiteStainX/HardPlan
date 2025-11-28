//
//  ContentView.swift
//  HardPlan
//
//  This is the root view of the application. It decides whether to show
//  the onboarding flow or the main tab view.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            if appState.userProfile == nil {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .task {
            appState.loadData()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
