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

private struct ProgramView: View {
    var body: some View {
        NavigationStack {
            Text("Program overview coming soon")
                .navigationTitle("Program")
        }
    }
}

private struct AnalyticsView: View {
    var body: some View {
        NavigationStack {
            Text("Analytics coming soon")
                .navigationTitle("Analytics")
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
