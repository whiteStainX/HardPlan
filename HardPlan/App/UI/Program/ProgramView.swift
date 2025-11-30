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
