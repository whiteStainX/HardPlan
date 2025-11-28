//
//  SettingsView.swift
//  HardPlan
//
//  Implements the Settings & Data Management surface introduced in
//  Phase 3.5. Users can review their profile, trigger data export,
//  and reset the app state.

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var exportMessage: String?
    @State private var isShowingExportAlert = false
    @State private var isConfirmingReset = false

    private let exportService: ExportServiceProtocol

    init(exportService: ExportServiceProtocol = DependencyContainer.shared.resolve()) {
        self.exportService = exportService
    }

    var body: some View {
        NavigationStack {
            List {
                profileSection
                dataManagementSection
            }
            .navigationTitle("Settings")
            .alert("Export Complete", isPresented: $isShowingExportAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportMessage ?? "Your data is ready.")
            }
            .confirmationDialog(
                "This will remove your profile, program, and logs.",
                isPresented: $isConfirmingReset,
                titleVisibility: .visible
            ) {
                Button("Reset App", role: .destructive) {
                    appState.resetApp()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var profileSection: some View {
        Section("User Profile") {
            if let profile = appState.userProfile {
                LabeledContent("Name", value: profile.name)
                LabeledContent("Goal", value: profile.goal.rawValue.capitalized)
                LabeledContent("Training Age", value: profile.trainingAge.rawValue.capitalized)
                LabeledContent("Preferred Unit", value: profile.unit.rawValue.uppercased())
                LabeledContent("Min Plate Increment", value: String(format: "%.1f", profile.minPlateIncrement))
                LabeledContent("Training Days", value: availableDaysLabel(for: profile.availableDays))
            } else {
                Text("Onboarding not completed yet.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var dataManagementSection: some View {
        Section("Data Management") {
            Button {
                exportData()
            } label: {
                Label("Export Data", systemImage: "square.and.arrow.up")
            }

            Text("Export a JSON snapshot of your profile, program, and recent logs.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button(role: .destructive) {
                isConfirmingReset = true
            } label: {
                Label("Reset App", systemImage: "arrow.counterclockwise")
            }
        }
    }

    private func availableDaysLabel(for days: [Int]) -> String {
        let sortedDays = days.sorted()
        if sortedDays.isEmpty {
            return "Not set"
        }

        return "\(sortedDays.count) days (\(sortedDays.map(String.init).joined(separator: ", ")) per week)"
    }

    private func exportData() {
        guard let bundle = exportService.exportBundle(
            profile: appState.userProfile,
            activeProgram: appState.activeProgram,
            workoutLogs: appState.workoutLogs
        ) else {
            exportMessage = "Unable to export data right now."
            isShowingExportAlert = true
            return
        }

        exportMessage = "JSON size: \(bundle.jsonSizeDescription). Workouts CSV rows: \(bundle.csvRowCount)."
        isShowingExportAlert = true
    }
}

#Preview {
    SettingsView(exportService: ExportService())
        .environmentObject(AppState())
}
