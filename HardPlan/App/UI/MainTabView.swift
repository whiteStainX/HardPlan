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

private struct DashboardView: View {
    var body: some View {
        NavigationStack {
            Text("Dashboard coming soon")
                .navigationTitle("Dashboard")
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

private struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let profile = appState.userProfile {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current User")
                            .font(.headline)
                        Text("Name: \(profile.name)")
                        Text("Goal: \(profile.goal.rawValue.capitalized)")
                        Text("Training Age: \(profile.trainingAge.rawValue.capitalized)")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("No user profile found")
                        .foregroundStyle(.secondary)
                }

                Button(role: .destructive) {
                    appState.resetApp()
                } label: {
                    Label("Reset App", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
