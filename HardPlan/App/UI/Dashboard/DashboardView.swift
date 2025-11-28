import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = DashboardViewModel()
    @State private var activeSession: ScheduledSession?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    adherenceSection
                    volumeSection
                    nextSessionSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .navigationDestination(item: $activeSession) { session in
                WorkoutSessionView(session: session)
                    .environmentObject(appState)
            }
        }
        .onAppear {
            viewModel.refresh(from: appState)
        }
        .onChange(of: appState.activeProgram) { _ in
            viewModel.refresh(from: appState)
        }
        .onChange(of: appState.workoutLogs) { _ in
            viewModel.refresh(from: appState)
        }
    }

    private var adherenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Adherence")
                .font(.headline)

            if let adherence = viewModel.weeklyAdherence {
                AdherenceRingView(completed: adherence.completed, scheduled: adherence.scheduled)
            } else {
                placeholderCard(text: "Complete onboarding to view adherence.")
            }
        }
    }

    private var volumeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Volume Equator")
                .font(.headline)
            Text("Sets completed this week vs. 10-20 set target range.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if viewModel.volumeSummaries.isEmpty {
                placeholderCard(text: "Log workouts to see weekly volume.")
            } else {
                VolumeEquatorView(volumes: viewModel.volumeSummaries)
            }
        }
    }

    private var nextSessionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Workout")
                .font(.headline)

            NextSessionCard(
                label: viewModel.nextSessionLabel,
                session: viewModel.nextSession,
                startAction: {
                    activeSession = viewModel.nextSession
                }
            )
        }
    }

    private func placeholderCard(text: String) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.secondarySystemBackground))
            .frame(maxWidth: .infinity, minHeight: 120)
            .overlay(
                Text(text)
                    .foregroundStyle(.secondary)
                    .padding()
            )
    }
}

struct AdherenceRingView: View {
    let completed: Int
    let scheduled: Int

    private var progress: Double {
        guard scheduled > 0 else { return 0 }
        return min(Double(completed) / Double(scheduled), 1.0)
    }

    private var progressColor: Color {
        if progress >= 0.9 {
            return .green
        }

        if progress >= 0.6 {
            return .yellow
        }

        return .orange
    }

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 14)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: progress)

                VStack {
                    Text("\(Int(progress * 100))%")
                        .font(.title2.weight(.bold))
                    Text("Adherence")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 140, height: 140)

            VStack(alignment: .leading, spacing: 6) {
                Text("\(completed) of \(scheduled) sessions")
                    .font(.title3.weight(.semibold))
                Text("Completed this week")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct VolumeEquatorView: View {
    let volumes: [VolumeSummary]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Chart(volumes) { item in
                BarMark(
                    x: .value("Sets", item.sets),
                    y: .value("Muscle", displayName(for: item.muscleGroup))
                )
                .foregroundStyle(color(for: item.status))
                .annotation(position: .trailing, alignment: .leading) {
                    Text("\(Int(item.sets)) sets")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxisLabel("Sets")
            .frame(minHeight: 220)

            HStack(spacing: 12) {
                legendDot(color: color(for: .under))
                Text("Under 10")
                    .foregroundStyle(.secondary)
                legendDot(color: color(for: .optimal))
                Text("10-20")
                    .foregroundStyle(.secondary)
                legendDot(color: color(for: .over))
                Text(">20")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func color(for status: VolumeSummary.Status) -> Color {
        switch status {
        case .under:
            return .orange
        case .optimal:
            return .blue
        case .over:
            return .red
        }
    }

    private func legendDot(color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
    }

    private func displayName(for muscle: MuscleGroup) -> String {
        muscle.rawValue.replacingOccurrences(of: "_", with: " ")
    }
}

struct NextSessionCard: View {
    let label: String
    let session: ScheduledSession?
    var startAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Text(session?.name ?? "No session scheduled")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: startAction) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Session")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(session == nil)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    let sampleSession = ScheduledSession(dayOfWeek: 2, name: "Upper Body Power")
    let appState = AppState()
    appState.activeProgram = ActiveProgram(startDate: "2024-01-01", currentBlockPhase: .introductory, weeklySchedule: [sampleSession])
    appState.workoutLogs = []

    return DashboardView()
        .environmentObject(appState)
}
