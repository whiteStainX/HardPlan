//
//  MainTabView.swift
//  HardPlan
//
//  Primary navigation shell for the app. Displays the top-level tabs
//  for Dashboard, Program, Analytics, and Settings.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }

            ProgramView()
                .tabItem {
                    Label("Program", systemImage: "list.bullet.rectangle")
                }

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.xaxis")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
