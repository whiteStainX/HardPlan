import SwiftUI
import Combine

struct ProgramView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ProgramViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.sessions.isEmpty {
                    ScrollView {
                        placeholderCard
                            .padding()
                    }
                    .background(Color(.systemGroupedBackground))
                } else {
                    List {
                        ForEach(orderedWeekdays, id: \.self) { weekday in
                            dayRow(for: weekday)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Program")
        }
        .onAppear {
            viewModel.refresh(program: appState.activeProgram)
        }
        .onChange(of: appState.activeProgram) { newValue in
            viewModel.refresh(program: newValue)
        }
    }

    private var startWeekday: Int {
        appState.userProfile?.firstDayOfWeek ?? Calendar.current.firstWeekday
    }

    private var orderedWeekdays: [Int] {
        (0..<7).map { ((startWeekday + $0 - 1) % 7) + 1 }
    }

    private var placeholderCard: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.secondarySystemBackground))
            .frame(maxWidth: .infinity, minHeight: 160)
            .overlay(
                VStack(spacing: 8) {
                    Text("No active program")
                        .font(.headline)
                    Text("Complete onboarding to view your weekly schedule.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .padding(),
                alignment: .center
            )
    }

    @ViewBuilder
    private func dayRow(for weekday: Int) -> some View {
        let label = viewModel.shortDayLabel(for: weekday)

        if let session = viewModel.session(for: weekday) {
            NavigationLink {
                ProgramSessionDetailView(session: session)
            } label: {
                HStack(spacing: 12) {
                    dayBadge(text: label)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.sessionName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("\(session.exercises.count) exercise\(session.exercises.count == 1 ? "" : "s")")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color(.tertiaryLabel))
                        .font(.footnote)
                }
                .padding(.vertical, 6)
            }
        } else {
            HStack(spacing: 12) {
                dayBadge(text: label)
                Text("Rest")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.vertical, 6)
        }
    }

    private func dayBadge(text: String) -> some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ProgramSessionDetailView: View {
    let session: ProgramSessionDisplay

    var body: some View {
        List {
            if session.exercises.isEmpty {
                Section {
                    Text("No exercises scheduled for this session.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }
            } else {
                Section("Exercises") {
                    ForEach(session.exercises) { exercise in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(exercise.name)
                                .font(.headline)
                            Text(exercise.prescription)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if let note = exercise.note {
                                Text(note)
                                    .font(.footnote)
                                    .foregroundStyle(Color(.tertiaryLabel))
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .navigationTitle("\(session.dayLabel) - \(session.sessionName)")
    }
}

struct ProgramSessionDisplay: Identifiable, Hashable {
    let id: UUID
    let dayOfWeek: Int
    let dayLabel: String
    let sessionName: String
    let exercises: [ProgramExerciseDisplay]
}

struct ProgramExerciseDisplay: Identifiable, Hashable {
    let id: UUID
    let name: String
    let prescription: String
    let note: String?
}

@MainActor
final class ProgramViewModel: ObservableObject {
    @Published var sessions: [ProgramSessionDisplay] = []

    private let exerciseRepository: ExerciseRepositoryProtocol
    private let calendar: Calendar

    init(
        exerciseRepository: ExerciseRepositoryProtocol = DependencyContainer.shared.resolve(),
        calendar: Calendar = .current
    ) {
        self.exerciseRepository = exerciseRepository
        self.calendar = calendar
    }

    func refresh(program: ActiveProgram?) {
        guard let program else {
            sessions = []
            return
        }

        let exerciseLookup = Dictionary(uniqueKeysWithValues: exerciseRepository
            .getAllExercises()
            .map { ($0.id, $0.name) })

        sessions = program.weeklySchedule
            .sorted { $0.dayOfWeek < $1.dayOfWeek }
            .map { session in
                let exercises = session.exercises
                    .sorted { $0.order < $1.order }
                    .map { scheduled in
                        ProgramExerciseDisplay(
                            id: scheduled.id,
                            name: exerciseLookup[scheduled.exerciseId] ?? "Exercise",
                            prescription: prescription(for: scheduled),
                            note: scheduled.note.isEmpty ? nil : scheduled.note
                        )
                    }

                return ProgramSessionDisplay(
                    id: session.id,
                    dayOfWeek: session.dayOfWeek,
                    dayLabel: dayLabel(for: session.dayOfWeek),
                    sessionName: session.name,
                    exercises: exercises
                )
            }
    }

    func session(for weekday: Int) -> ProgramSessionDisplay? {
        sessions.first { $0.dayOfWeek == weekday }
    }

    func shortDayLabel(for weekday: Int) -> String {
        let symbols = calendar.shortWeekdaySymbols
        if weekday >= 1 && weekday <= symbols.count {
            return symbols[weekday - 1]
        }

        return "Day \(weekday)"
    }

    private func dayLabel(for weekday: Int) -> String {
        let symbols = calendar.weekdaySymbols
        if weekday >= 1 && weekday <= symbols.count {
            return symbols[weekday - 1]
        }

        return "Day \(weekday)"
    }

    private func prescription(for exercise: ScheduledExercise) -> String {
        var parts: [String] = []
        parts.append("\(exercise.targetSets)x\(exercise.targetReps)")

        if exercise.targetRPE > 0 {
            parts.append("RPE \(String(format: "%.1f", exercise.targetRPE))")
        }

        if let loadString = loadLabel(for: exercise.targetLoad) {
            parts.append(loadString)
        }

        if let tempoLabel = tempoLabel(for: exercise.targetTempoOverride) {
            parts.append(tempoLabel)
        }

        return parts.joined(separator: " • ")
    }

    private func loadLabel(for load: Double) -> String? {
        guard load > 0 else { return nil }

        if load.rounded() == load {
            return "\(Int(load)) lb"
        }

        return String(format: "%.1f lb", load)
    }

    private func tempoLabel(for tempo: Tempo?) -> String? {
        guard let tempo else { return nil }
        if let topPause = tempo.topPause {
            return "Tempo \(tempo.eccentric)-\(tempo.pause)-\(tempo.concentric)-\(topPause)"
        }

        return "Tempo \(tempo.eccentric)-\(tempo.pause)-\(tempo.concentric)"
    }
}

#Preview {
    let squat = ScheduledExercise(
        exerciseId: "squat",
        order: 0,
        targetSets: 3,
        targetReps: 5,
        targetLoad: 225,
        targetRPE: 8.0,
        note: "Competition focus"
    )

    let bench = ScheduledExercise(
        exerciseId: "bench",
        order: 1,
        targetSets: 4,
        targetReps: 6,
        targetLoad: 185,
        targetRPE: 7.5
    )

    let session = ScheduledSession(dayOfWeek: 2, name: "Upper A", exercises: [squat, bench])
    let appState = AppState()
    appState.activeProgram = ActiveProgram(startDate: "2024-01-01", currentBlockPhase: .introductory, weeklySchedule: [session])

    return ProgramView()
        .environmentObject(appState)
}
