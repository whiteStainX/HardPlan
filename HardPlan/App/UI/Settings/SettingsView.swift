//
//  SettingsView.swift
//  HardPlan
//
//  Implements the Settings & Data Management surface introduced in
//  Phase 3.5. Users can review their profile, trigger data export,
//  and reset the app state.

import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var exportErrorMessage: String?
    @State private var isShowingExportAlert = false
    @State private var isPresentingShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var isConfirmingReset = false

    private let exportService: ExportServiceProtocol
    private let exerciseRepository: ExerciseRepositoryProtocol

    init(
        exportService: ExportServiceProtocol = DependencyContainer.shared.resolve(),
        exerciseRepository: ExerciseRepositoryProtocol = DependencyContainer.shared.resolve()
    ) {
        self.exportService = exportService
        self.exerciseRepository = exerciseRepository
    }

    var body: some View {
        NavigationStack {
            List {
                if let profileBinding {
                    trainingSection(profileBinding)
                    preferencesSection(profileBinding)
                } else {
                    onboardingPlaceholder
                }

                exerciseSection
                dataManagementSection
            }
            .navigationTitle("Settings")
            .alert("Export", isPresented: $isShowingExportAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportErrorMessage ?? "Your export is ready to share.")
            }
            .sheet(isPresented: $isPresentingShareSheet) {
                ShareSheet(activityItems: shareItems)
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

    private var exerciseSection: some View {
        Section("Exercises") {
            NavigationLink {
                ExerciseListView()
            } label: {
                Label("Custom Exercises", systemImage: "plus.rectangle.on.rectangle")
            }

            Text("Add your own movements to use across workouts and exports.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func trainingSection(_ profile: Binding<UserProfile>) -> some View {
        Section("Training") {
            NavigationLink("Training Focus") {
                TrainingFocusView(
                    goal: binding(\.goal, in: profile),
                    weakPoints: binding(\.weakPoints, in: profile)
                )
            }

            NavigationLink("Experience Level") {
                ExperienceView(selectedTrainingAge: binding(\.trainingAge, in: profile))
            }

            NavigationLink("Weekly Schedule") {
                ScheduleView(
                    trainingAge: profile.wrappedValue.trainingAge,
                    availableDays: availableDaysBinding(for: profile),
                    warningText: nil
                )
            }
        }
    }

    private func preferencesSection(_ profile: Binding<UserProfile>) -> some View {
        Section("Preferences") {
            NavigationLink("Units & Loading") {
                UnitSettingsView(
                    unit: binding(\.unit, in: profile),
                    minPlateIncrement: binding(\.minPlateIncrement, in: profile)
                )
            }

            LabeledContent("Training Days", value: availableDaysLabel(for: profile.wrappedValue.availableDays))
                .foregroundStyle(.secondary)
        }
    }

    private var onboardingPlaceholder: some View {
        Section("User Profile") {
            Text("Onboarding not completed yet.")
                .foregroundStyle(.secondary)
        }
    }

    private var dataManagementSection: some View {
        Section("Data Management") {
            Button {
                exportData()
            } label: {
                Label("Export Data", systemImage: "square.and.arrow.up")
            }

            Text("Export a JSON snapshot of your profile, program, exercises, and workout logs as CSV.")
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
            workoutLogs: appState.workoutLogs,
            exercises: exerciseRepository.getAllExercises()
        ) else {
            exportErrorMessage = "Unable to export data right now."
            isShowingExportAlert = true
            return
        }

        do {
            shareItems = try prepareShareItems(from: bundle)
            isPresentingShareSheet = true
        } catch {
            exportErrorMessage = "Unable to prepare export files."
            isShowingExportAlert = true
        }
    }

    private func prepareShareItems(from bundle: ExportBundle) throws -> [Any] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let timestamp = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")

        let exportDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("HardPlanExports", isDirectory: true)
        try FileManager.default.createDirectory(at: exportDirectory, withIntermediateDirectories: true)

        let jsonURL = exportDirectory.appendingPathComponent("hardplan-export-\(timestamp).json")
        try bundle.jsonData.write(to: jsonURL, options: .atomic)

        guard let csvData = bundle.csvString.data(using: .utf8) else {
            throw ExportError.unableToEncodeCSV
        }

        let csvURL = exportDirectory.appendingPathComponent("hardplan-workouts-\(timestamp).csv")
        try csvData.write(to: csvURL, options: .atomic)

        return [jsonURL, csvURL]
    }

    private var profileBinding: Binding<UserProfile>? {
        guard appState.userProfile != nil else { return nil }

        return Binding(
            get: { appState.userProfile ?? UserProfile(name: "", trainingAge: .novice, goal: .strength) },
            set: { appState.userProfile = $0 }
        )
    }

    private func binding<Value>(
        _ keyPath: WritableKeyPath<UserProfile, Value>,
        in profile: Binding<UserProfile>
    ) -> Binding<Value> {
        Binding(
            get: { profile.wrappedValue[keyPath: keyPath] },
            set: { profile.wrappedValue[keyPath: keyPath] = $0 }
        )
    }

    private func availableDaysBinding(for profile: Binding<UserProfile>) -> Binding<Int> {
        Binding(
            get: { max(2, min(6, profile.wrappedValue.availableDays.count)) },
            set: { newValue in
                let clamped = max(2, min(6, newValue))
                profile.wrappedValue.availableDays = Array(1...clamped)
            }
        )
    }
}

#Preview {
    SettingsView(exportService: ExportService(), exerciseRepository: ExerciseRepository())
        .environmentObject(AppState())
}

private enum ExportError: Error {
    case unableToEncodeCSV
}

private struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
