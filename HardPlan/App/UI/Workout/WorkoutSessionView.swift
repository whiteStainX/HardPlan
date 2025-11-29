import SwiftUI
import Combine

struct WorkoutSessionView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: WorkoutSessionViewModel

    @State private var restTimeRemaining: Int?
    @State private var restTimer: Timer?
    @State private var restEndDate: Date?
    @State private var swapTarget: ExerciseEntry?
    @State private var substitutionOptions: [SubstitutionOption] = []
    @State private var substitutionError: String?
    @State private var toastMessage: String?
    @State private var completedExercises: [CompletedExercise] = []
    @State private var showingSummary = false

    init(session: ScheduledSession) {
        _viewModel = StateObject(wrappedValue: WorkoutSessionViewModel(session: session))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sessionHeader

                ForEach($viewModel.exerciseEntries) { $entry in
                    exerciseCard(for: $entry)
                }
            }
            .padding()
        }
        .navigationTitle(viewModel.session.name)
        .toolbar {
            Toggle(isOn: Binding(get: { viewModel.isShortOnTime }, set: { newValue in
                if newValue != viewModel.isShortOnTime {
                    viewModel.toggleShortOnTime()
                }
            })) {
                Label("Short on Time", systemImage: "bolt.fill")
            }
            .toggleStyle(.switch)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                if let remaining = restTimeRemaining {
                    RestTimerView(remainingSeconds: remaining) {
                        stopRestTimer()
                    }
                    .transition(.move(edge: .bottom))
                }

                Button(action: finishWorkout) {
                    HStack {
                        Image(systemName: "flag.checkered")
                        Text("Finish Workout")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .padding(.bottom, 4)
                .disabled(!viewModel.hasCompletedSets())
            }
            .background(.ultraThinMaterial)
        }
        .onDisappear {
            stopRestTimer()
        }
        .sheet(item: $swapTarget) { entry in
            SubstitutionSheet(
                exerciseName: entry.exerciseName,
                options: substitutionOptions,
                onSelect: { option in
                    viewModel.applySubstitution(option: option, to: entry.id)
                },
                dismiss: {
                    swapTarget = nil
                }
            )
        }
        .alert("Can't Swap Exercise", isPresented: Binding(
            get: { substitutionError != nil },
            set: { newValue in
                if !newValue { substitutionError = nil }
            }
        )) {
            Button("OK", role: .cancel) {
                substitutionError = nil
            }
        } message: {
            Text(substitutionError ?? "")
        }
        .overlay(alignment: .top) {
            if let toastMessage {
                ToastBanner(message: toastMessage)
                    .padding()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: toastMessage)
        .onReceive(viewModel.$toastMessage.compactMap { $0 }) { message in
            toastMessage = message
            viewModel.clearToastMessage()

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                if toastMessage == message {
                    toastMessage = nil
                }
            }
        }
        .onAppear {
            viewModel.updateUserProfile(appState.userProfile)
        }
        .onChange(of: appState.userProfile) { newValue in
            viewModel.updateUserProfile(newValue)
        }
        .onChange(of: scenePhase) { newPhase in
            guard newPhase == .active else { return }
            updateRestTimeRemaining()
        }
        .sheet(isPresented: $showingSummary) {
            NavigationStack {
                WorkoutSummaryView(
                    session: viewModel.session,
                    completedExercises: completedExercises,
                    startedAt: viewModel.startedAt,
                    mode: viewModel.isShortOnTime ? .shortOnTime : .normal,
                    dismissAction: { showingSummary = false }
                )
                .environmentObject(appState)
            }
        }
    }

    private var sessionHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.session.name)
                .font(.title2.weight(.semibold))
            Text(viewModel.isShortOnTime ? "APS mode trims accessories to keep you moving fast." : "Work through each exercise and log your RPE.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func exerciseCard(for entry: Binding<ExerciseEntry>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.wrappedValue.exerciseName)
                        .font(.headline)
                    Text(viewModel.exerciseSubtitle(for: entry.wrappedValue.scheduled))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Button {
                        presentSubstitutionSheet(for: entry.wrappedValue)
                    } label: {
                        Label("Swap", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(.bordered)

                    ProgressView(value: entry.wrappedValue.completionProgress)
                        .progressViewStyle(.linear)
                        .frame(width: 140)
                }
            }

            ForEach(entry.sets) { $set in
                SetRowView(set: $set) {
                    completeSet(exerciseId: entry.id, setId: set.id, exerciseKey: entry.wrappedValue.scheduled.exerciseId)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func completeSet(exerciseId: UUID, setId: UUID, exerciseKey: String) {
        let completed = viewModel.markSetComplete(exerciseId: exerciseId, setId: setId)
        if completed {
            startRestTimer(for: exerciseKey)
        } else {
            stopRestTimer()
        }
    }

    private func startRestTimer(for exerciseId: String) {
        restTimer?.invalidate()
        let duration = viewModel.recommendedRest(for: exerciseId)
        restEndDate = Date().addingTimeInterval(TimeInterval(duration))
        updateRestTimeRemaining()

        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateRestTimeRemaining()
        }
    }

    private func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        restTimeRemaining = nil
        restEndDate = nil
    }

    private func updateRestTimeRemaining() {
        guard let endDate = restEndDate else { return }
        let remaining = Int(endDate.timeIntervalSinceNow.rounded(.down))

        if remaining <= 0 {
            stopRestTimer()
        } else {
            restTimeRemaining = remaining
        }
    }

    private func presentSubstitutionSheet(for entry: ExerciseEntry) {
        guard let options = viewModel.substitutionOptions(for: entry) else {
            substitutionError = "Add your profile to enable smart substitutions."
            return
        }

        substitutionOptions = options
        swapTarget = entry
    }

    private func finishWorkout() {
        let logReadyExercises = viewModel.buildCompletedExercises()
        guard !logReadyExercises.isEmpty else {
            toastMessage = "Log at least one set to finish."
            return
        }

        completedExercises = logReadyExercises
        showingSummary = true
    }
}

private struct SetRowView: View {
    @Binding var set: EditableSet
    var completeAction: () -> Void

    private var targetDescription: String {
        "Target: \(Int(set.targetReps)) reps @ \(Int(set.targetLoad))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Set \(set.setNumber)")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(targetDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text("Load")
                        .font(.caption)
                    TextField("Load", text: $set.load)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading) {
                    Text("Reps")
                        .font(.caption)
                    TextField("Reps", text: $set.reps)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading) {
                    Text("RPE")
                        .font(.caption)
                    Slider(value: $set.rpe, in: 5...10, step: 0.5)
                    Text(String(format: "%.1f", set.rpe))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Button(action: completeAction) {
                HStack {
                    Image(systemName: set.isComplete ? "checkmark.circle.fill" : "play.circle")
                    Text(set.isComplete ? "Completed" : "Complete Set")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(set.isComplete ? .green : .blue)
            .disabled(!set.isValid)
        }
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct RestTimerView: View {
    let remainingSeconds: Int
    var cancelAction: () -> Void

    private var minutes: Int { remainingSeconds / 60 }
    private var seconds: Int { remainingSeconds % 60 }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Rest Timer")
                    .font(.headline)
                Text(String(format: "%02d:%02d remaining", minutes, seconds))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("I'm Ready", action: cancelAction)
                .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
    }
}

#Preview {
    let squat = ScheduledExercise(exerciseId: "squat", order: 1, targetSets: 3, targetReps: 5, targetLoad: 225, targetRPE: 8)
    let bench = ScheduledExercise(exerciseId: "bench_press", order: 2, targetSets: 3, targetReps: 8, targetLoad: 155, targetRPE: 7.5)
    let session = ScheduledSession(dayOfWeek: 2, name: "Upper / Lower Mix", exercises: [squat, bench])
    return NavigationStack {
        WorkoutSessionView(session: session)
            .environmentObject(AppState())
    }
}

private struct SubstitutionSheet: View {
    let exerciseName: String
    let options: [SubstitutionOption]
    var onSelect: (SubstitutionOption) -> Void
    var dismiss: () -> Void

    var body: some View {
        NavigationStack {
            List {
                if options.isEmpty {
                    Section {
                        Text("No compatible substitutions available right now.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section("Recommended Swaps") {
                        ForEach(options) { option in
                            Button {
                                onSelect(option)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(option.exerciseName)
                                            .font(.headline)
                                        Spacer()
                                        Text(String(format: "%.0f%% match", option.specificityScore * 100))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    if let warning = option.warning {
                                        HStack(spacing: 6) {
                                            Image(systemName: warning.level == .warning ? "exclamationmark.triangle.fill" : "info.circle")
                                                .foregroundStyle(warning.level == .warning ? .orange : .blue)
                                                .font(.caption)
                                            Text(warning.message)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Swap \(exerciseName)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: dismiss)
                }
            }
        }
    }
}

private struct ToastBanner: View {
    let message: String

    var body: some View {
        HStack {
            Image(systemName: "bolt.fill")
            Text(message)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 4, y: 2)
    }
}
