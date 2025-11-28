import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = AnalyticsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if viewModel.snapshots.isEmpty {
                        emptyState
                    } else {
                        liftPicker
                        e1rmSection
                        rpeSection
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Analytics")
        }
        .onAppear {
            viewModel.refresh(from: appState)
        }
        .onChange(of: appState.analyticsSnapshots) { _ in
            viewModel.refresh(from: appState)
        }
        .onChange(of: appState.activeProgram) { _ in
            viewModel.refresh(from: appState)
        }
    }

    private var liftPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Lift")
                .font(.headline)

            Picker("Lift", selection: $viewModel.selectedLiftId) {
                ForEach(viewModel.snapshots, id: \.liftId) { snapshot in
                    Text(viewModel.displayName(for: snapshot.liftId))
                        .tag(Optional(snapshot.liftId))
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var e1rmSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Estimated 1RM")
                .font(.headline)
            Text("Track strength trends for your top competition lifts.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let snapshot = viewModel.selectedSnapshot {
                E1RMChart(history: snapshot.e1RMHistory, blockPhases: snapshot.blockPhaseSegments)

                if let updatedLabel = viewModel.lastUpdatedLabel(for: snapshot) {
                    Text(updatedLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var rpeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RPE Distribution")
                .font(.headline)
            Text("See how often you're training in target effort zones.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let snapshot = viewModel.selectedSnapshot {
                RPEHeatmap(bins: snapshot.rpeDistribution)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var emptyState: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.secondarySystemBackground))
            .frame(maxWidth: .infinity, minHeight: 200)
            .overlay(
                VStack(spacing: 8) {
                    Text("Analytics will appear here")
                        .font(.headline)
                    Text("Complete onboarding and log workouts to unlock strength trends and RPE summaries.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            )
    }
}

@MainActor
final class AnalyticsViewModel: ObservableObject {
    @Published var snapshots: [AnalyticsSnapshot] = []
    @Published var selectedLiftId: String?

    private var liftNames: [String: String] = [:]
    private let exerciseRepository: ExerciseRepositoryProtocol
    private let isoFormatter: ISO8601DateFormatter
    private let displayFormatter: DateFormatter

    init(exerciseRepository: ExerciseRepositoryProtocol = DependencyContainer.shared.resolve()) {
        self.exerciseRepository = exerciseRepository

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.isoFormatter = isoFormatter

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        self.displayFormatter = displayFormatter
    }

    func refresh(from appState: AppState) {
        snapshots = appState.analyticsSnapshots
        if !snapshots.contains(where: { $0.liftId == selectedLiftId }) {
            selectedLiftId = snapshots.first?.liftId
        }
        hydrateLiftNames()
    }

    func displayName(for liftId: String) -> String {
        liftNames[liftId] ?? "Lift"
    }

    var selectedSnapshot: AnalyticsSnapshot? {
        guard let selectedLiftId else { return snapshots.first }
        return snapshots.first(where: { $0.liftId == selectedLiftId })
    }

    func lastUpdatedLabel(for snapshot: AnalyticsSnapshot) -> String? {
        guard let date = isoFormatter.date(from: snapshot.lastUpdatedAt) else { return nil }
        return "Updated \(displayFormatter.string(from: date))"
    }

    private func hydrateLiftNames() {
        liftNames = Dictionary(uniqueKeysWithValues: exerciseRepository
            .getAllExercises()
            .map { ($0.id, $0.name) })
    }
}
