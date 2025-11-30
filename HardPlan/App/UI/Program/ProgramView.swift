import SwiftUI
import Combine
import Charts

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
                        if let overview = viewModel.overview, !overview.weeks.isEmpty {
                            Section("Projected program overview") {
                                ProgramOverviewCard(overview: overview)
                            }
                        }

                        if !viewModel.ruleSummary.isEmpty {
                            Section("Planning summary") {
                                ForEach(viewModel.ruleSummary) { item in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: item.statusIcon)
                                            .foregroundStyle(item.status == .met ? .green : .orange)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.title)
                                                .font(.subheadline.weight(.semibold))
                                            Text(item.detail)
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 4)
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
            viewModel.refresh(program: appState.activeProgram, user: appState.userProfile, analytics: appState.analyticsSnapshots)
            viewModel.evaluate(program: appState.activeProgram, user: appState.userProfile)
        }
        .onChange(of: appState.activeProgram) { newValue in
            viewModel.refresh(program: newValue, user: appState.userProfile, analytics: appState.analyticsSnapshots)
            viewModel.evaluate(program: newValue, user: appState.userProfile)
        }
        .onChange(of: appState.userProfile) { profile in
            viewModel.refresh(program: appState.activeProgram, user: profile, analytics: appState.analyticsSnapshots)
            viewModel.evaluate(program: appState.activeProgram, user: profile)
        }
        .onChange(of: appState.analyticsSnapshots) { snapshots in
            viewModel.refresh(program: appState.activeProgram, user: appState.userProfile, analytics: snapshots)
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

struct ProgramOverviewCard: View {
    let overview: ProgramOverview

    private func intensity(for phase: BlockPhase) -> Double {
        switch phase {
        case .introductory: return 0.5
        case .accumulation: return 0.7
        case .intensification: return 0.85
        case .realization: return 1.0
        case .deload: return 0.4
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Periodization preview")
                .font(.headline)
            if let metricLabel = overview.metricLabel {
                Text(metricLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Chart {
                ForEach(overview.weeks) { week in
                    BarMark(
                        x: .value("Week", "W\(week.weekIndex)"),
                        y: .value("Phase", intensity(for: week.phase))
                    )
                    .foregroundStyle(by: .value("Phase", week.phase.rawValue))

                    if let projected = week.projectedMetric {
                        LineMark(
                            x: .value("Week", "W\(week.weekIndex)"),
                            y: .value("Projected", projected)
                        )
                        .interpolationMethod(.monotone)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .foregroundStyle(.green)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4))
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 5))
            }
            .chartXAxis {
                AxisMarks(values: overview.weeks.map { "W\($0.weekIndex)" }) { _ in
                    AxisValueLabel()
                }
            }
            .frame(minHeight: 220)

            if let firstDate = overview.weeks.first?.startDate {
                Text("Starting \(dateFormatter.string(from: firstDate)) • Tracks upcoming 8 weeks")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private extension ProgramRuleSummaryItem {
    var statusIcon: String {
        switch status {
        case .met:
            return "checkmark.seal.fill"
        case .needsAttention:
            return "exclamationmark.triangle.fill"
        }
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

struct ProgramWeekProjection: Identifiable, Hashable {
    let id: UUID = UUID()
    let weekIndex: Int
    let startDate: Date
    let phase: BlockPhase
    let projectedMetric: Double?
}

struct ProgramOverview {
    let weeks: [ProgramWeekProjection]
    let metricLabel: String?
    let goalLiftId: String?
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
    @Published var ruleSummary: [ProgramRuleSummaryItem] = []
    @Published var overview: ProgramOverview?

    let calendar: Calendar
    let exerciseOptions: [Exercise]

    private let exerciseRepository: ExerciseRepositoryProtocol
    private let validationService: ProgramValidationServiceProtocol
    private var activeProgram: ActiveProgram?
    private var user: UserProfile?
    private let isoFormatter: ISO8601DateFormatter
    private let dateOnlyFormatter: ISO8601DateFormatter

    init(
        exerciseRepository: ExerciseRepositoryProtocol = DependencyContainer.shared.resolve(),
        validationService: ProgramValidationServiceProtocol = DependencyContainer.shared.resolve(),
        calendar: Calendar = .current
    ) {
        self.exerciseRepository = exerciseRepository
        self.validationService = validationService
        self.calendar = calendar
        self.exerciseOptions = exerciseRepository.getAllExercises().sorted { $0.name < $1.name }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.isoFormatter = formatter
        let dateOnly = ISO8601DateFormatter()
        dateOnly.formatOptions = [.withFullDate]
        self.dateOnlyFormatter = dateOnly
    }

    func refresh(program: ActiveProgram?, user: UserProfile?, analytics: [AnalyticsSnapshot]) {
        activeProgram = program
        self.user = user
        guard let program else {
            sessions = []
            overview = nil
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

        overview = buildOverview(program: program, user: user, analytics: analytics)
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
        refresh(program: appState.activeProgram, user: appState.userProfile, analytics: appState.analyticsSnapshots)
        evaluate(program: appState.activeProgram, user: appState.userProfile)
        return result
    }

    private func buildOverview(program: ActiveProgram, user: UserProfile?, analytics: [AnalyticsSnapshot]) -> ProgramOverview? {
        guard let startDate = parseDate(program.startDate) else { return nil }
        let goal = user?.goalSetting
        let projectionPoints = projectionPoints(for: goal, analytics: analytics)

        let weeks = (0..<8).compactMap { offset -> ProgramWeekProjection? in
            guard let date = calendar.date(byAdding: .weekOfYear, value: offset, to: startDate) else { return nil }
            let projectedValue = projectedValue(on: date, projection: projectionPoints)
            return ProgramWeekProjection(
                weekIndex: program.currentWeek + offset,
                startDate: date,
                phase: phase(for: program, offset: offset),
                projectedMetric: projectedValue
            )
        }

        return ProgramOverview(
            weeks: weeks,
            metricLabel: goal?.metric == .estimated1RM ? "Projected e1RM" : "Projected volume",
            goalLiftId: goal?.liftId
        )
    }

    private func phase(for program: ActiveProgram, offset: Int) -> BlockPhase {
        let ordered: [BlockPhase] = [.introductory, .accumulation, .intensification, .realization, .deload]
        guard let currentIndex = ordered.firstIndex(of: program.currentBlockPhase) else { return program.currentBlockPhase }
        let index = (currentIndex + offset) % ordered.count
        return ordered[index]
    }

    private func projectionPoints(for goal: GoalSetting?, analytics: [AnalyticsSnapshot]) -> [E1RMPoint] {
        guard let goal, goal.metric == .estimated1RM else { return [] }
        return analytics.first(where: { $0.liftId == goal.liftId })?.projectedE1RMHistory ?? []
    }

    private func projectedValue(on date: Date, projection: [E1RMPoint]) -> Double? {
        guard !projection.isEmpty else { return nil }
        let sorted = projection.compactMap { point -> (Date, Double)? in
            guard let date = parseDate(point.date) else { return nil }
            return (date, point.e1rm)
        }.sorted { $0.0 < $1.0 }

        guard let first = sorted.first else { return nil }
        if date <= first.0 { return first.1 }
        for index in 0..<(sorted.count - 1) {
            let current = sorted[index]
            let next = sorted[index + 1]
            if date >= current.0 && date <= next.0 {
                let totalDays = Double(calendar.dateComponents([.day], from: current.0, to: next.0).day ?? 1)
                let elapsed = Double(calendar.dateComponents([.day], from: current.0, to: date).day ?? 0)
                let ratio = max(0, min(1, elapsed / totalDays))
                return current.1 + (next.1 - current.1) * ratio
            }
        }

        return sorted.last?.1
    }

    private func parseDate(_ string: String) -> Date? {
        isoFormatter.date(from: string) ?? dateOnlyFormatter.date(from: string)
    }

    func evaluate(program: ActiveProgram?, user: UserProfile?) {
        guard let program else {
            validationIssues = []
            ruleSummary = []
            return
        }

        let result = validationService.validate(program: program, user: user)
        validationIssues = result.issues
        ruleSummary = result.ruleSummary
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
