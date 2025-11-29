import SwiftUI
import Combine

struct ProgramView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ProgramViewModel()
    @State private var isEditing = false
    @State private var editingDraft: ProgramSessionDraft?
    @State private var showEditor = false

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
                        if !viewModel.validationIssues.isEmpty {
                            Section("Alerts") {
                                ForEach(viewModel.validationIssues) { issue in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(issue.message)
                                            .font(.subheadline)
                                            .foregroundStyle(issue.severity == .error ? .red : .orange)
                                        Text("Days: " + issue.affectedDays.map(viewModel.shortDayLabel).joined(separator: ", "))
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }

                        if !viewModel.corrections.isEmpty {
                            Section("Suggestions") {
                                ForEach(viewModel.corrections) { correction in
                                    Button {
                                        viewModel.apply(correction: correction, appState: appState)
                                    } label: {
                                        HStack(alignment: .top) {
                                            Image(systemName: "lightbulb")
                                                .foregroundStyle(.yellow)
                                            Text(correction.description)
                                                .multilineTextAlignment(.leading)
                                                .foregroundStyle(.primary)
                                        }
                                    }
                                }
                            }
                        }

                        ForEach(orderedWeekdays, id: \.self) { weekday in
                            dayRow(for: weekday)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Program")
            .toolbar {
                if !viewModel.sessions.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(isEditing ? "Done" : "Edit") {
                            withAnimation {
                                isEditing.toggle()
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.refresh(program: appState.activeProgram)
            viewModel.evaluate(program: appState.activeProgram)
        }
        .onChange(of: appState.activeProgram) { newValue in
            viewModel.refresh(program: newValue)
            viewModel.evaluate(program: newValue)
        }
        .sheet(isPresented: $showEditor) {
            if let _ = editingDraft {
                ProgramSessionEditor(
                    draft: Binding(
                        get: { editingDraft ?? ProgramSessionDraft(dayOfWeek: startWeekday, name: "Session", exercises: []) },
                        set: { editingDraft = $0 }
                    ),
                    exerciseOptions: viewModel.exerciseOptions,
                    calendar: viewModel.calendar
                ) {
                    if let draft = editingDraft, let result = viewModel.save(draft: draft, appState: appState) {
                        viewModel.validationIssues = result.issues
                        editingDraft = nil
                        showEditor = false
                    }
                }
            }
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
            let row = {
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

                    if isEditing {
                        Button {
                            editingDraft = viewModel.makeDraft(for: weekday)
                            showEditor = true
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Color(.tertiaryLabel))
                            .font(.footnote)
                    }
                }
                .padding(.vertical, 6)
            }

            if isEditing {
                row()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingDraft = viewModel.makeDraft(for: weekday)
                        showEditor = true
                    }
            } else {
                NavigationLink {
                    ProgramSessionDetailView(session: session)
                } label: {
                    row()
                }
            }
        } else {
            HStack(spacing: 12) {
                dayBadge(text: label)
                Text("Rest")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if isEditing {
                    Button {
                        editingDraft = viewModel.makeDraft(for: weekday)
                        showEditor = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(Color.accentColor)
                    }
                }
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

struct ProgramExerciseDraft: Identifiable, Hashable {
    var id: UUID = UUID()
    var exerciseId: String
    var name: String
    var targetSets: Int
    var targetReps: Int
    var targetLoad: Double
    var targetRPE: Double
    var note: String
    var order: Int

    init(from scheduled: ScheduledExercise, exerciseLookup: [Exercise]) {
        self.id = scheduled.id
        self.exerciseId = scheduled.exerciseId
        self.name = exerciseLookup.first(where: { $0.id == scheduled.exerciseId })?.name ?? "Exercise"
        self.targetSets = scheduled.targetSets
        self.targetReps = scheduled.targetReps
        self.targetLoad = scheduled.targetLoad
        self.targetRPE = scheduled.targetRPE
        self.note = scheduled.note
        self.order = scheduled.order
    }

    init(exercise: Exercise, order: Int) {
        self.exerciseId = exercise.id
        self.name = exercise.name
        self.targetSets = 3
        self.targetReps = 8
        self.targetLoad = 0
        self.targetRPE = 7.5
        self.note = ""
        self.order = order
    }

    func asScheduledExercise() -> ScheduledExercise {
        ScheduledExercise(
            id: id,
            exerciseId: exerciseId,
            order: order,
            targetSets: targetSets,
            targetReps: targetReps,
            targetLoad: targetLoad,
            targetRPE: targetRPE,
            note: note
        )
    }
}

struct ProgramSessionDraft: Identifiable, Hashable {
    var id: UUID
    var dayOfWeek: Int
    var name: String
    var exercises: [ProgramExerciseDraft]

    init(session: ScheduledSession, exerciseLookup: [Exercise]) {
        self.id = session.id
        self.dayOfWeek = session.dayOfWeek
        self.name = session.name
        self.exercises = session.exercises
            .sorted { $0.order < $1.order }
            .map { ProgramExerciseDraft(from: $0, exerciseLookup: exerciseLookup) }
    }

    init(dayOfWeek: Int, name: String, exercises: [ProgramExerciseDraft]) {
        self.id = UUID()
        self.dayOfWeek = dayOfWeek
        self.name = name
        self.exercises = exercises
    }

    mutating func reorder(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
        for index in exercises.indices {
            exercises[index].order = index
        }
    }

    func asScheduledSession() -> ScheduledSession {
        let scheduledExercises = exercises.enumerated().map { index, draft in
            var updated = draft
            updated.order = index
            return updated.asScheduledExercise()
        }

        return ScheduledSession(id: id, dayOfWeek: dayOfWeek, name: name, exercises: scheduledExercises)
    }
}

@MainActor
final class ProgramViewModel: ObservableObject {
    @Published var sessions: [ProgramSessionDisplay] = []
    @Published var validationIssues: [ProgramValidationIssue] = []
    @Published var corrections: [ProgramCorrection] = []

    let calendar: Calendar
    let exerciseOptions: [Exercise]

    private let exerciseRepository: ExerciseRepositoryProtocol
    private let validationService: ProgramValidationServiceProtocol
    private var activeProgram: ActiveProgram?

    init(
        exerciseRepository: ExerciseRepositoryProtocol = DependencyContainer.shared.resolve(),
        validationService: ProgramValidationServiceProtocol = DependencyContainer.shared.resolve(),
        calendar: Calendar = .current
    ) {
        self.exerciseRepository = exerciseRepository
        self.validationService = validationService
        self.calendar = calendar
        self.exerciseOptions = exerciseRepository.getAllExercises().sorted { $0.name < $1.name }
    }

    func refresh(program: ActiveProgram?) {
        activeProgram = program
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

    func makeDraft(for weekday: Int) -> ProgramSessionDraft {
        guard let program = activeProgram else {
            return ProgramSessionDraft(dayOfWeek: weekday, name: "Session", exercises: [])
        }

        if let existing = program.weeklySchedule.first(where: { $0.dayOfWeek == weekday }) {
            return ProgramSessionDraft(session: existing, exerciseLookup: exerciseOptions)
        }

        return ProgramSessionDraft(dayOfWeek: weekday, name: "New Session", exercises: [])
    }

    func save(draft: ProgramSessionDraft, appState: AppState) -> ProgramValidationResult? {
        guard var program = activeProgram else { return nil }
        var updatedSessions = program.weeklySchedule

        let session = draft.asScheduledSession()
        if let index = updatedSessions.firstIndex(where: { $0.id == session.id }) {
            updatedSessions[index] = session
        } else if let indexForDay = updatedSessions.firstIndex(where: { $0.dayOfWeek == session.dayOfWeek }) {
            updatedSessions[indexForDay] = session
        } else {
            updatedSessions.append(session)
        }

        let result = appState.updateProgramSchedule(updatedSessions)
        refresh(program: appState.activeProgram)
        evaluate(program: appState.activeProgram)
        return result
    }

    func apply(correction: ProgramCorrection, appState: AppState) {
        if let result = appState.applyProgramCorrection(correction) {
            validationIssues = result.issues
        }

        refresh(program: appState.activeProgram)
        evaluate(program: appState.activeProgram)
    }

    func evaluate(program: ActiveProgram?) {
        guard let program else {
            validationIssues = []
            corrections = []
            return
        }

        let result = validationService.validate(program: program)
        validationIssues = result.issues
        corrections = validationService.suggestedCorrections(for: program)
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
