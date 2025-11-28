import SwiftUI

struct WorkoutSessionView: View {
    @StateObject private var viewModel: WorkoutSessionViewModel

    @State private var restTimeRemaining: Int?
    @State private var restTimer: Timer?

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
            if let remaining = restTimeRemaining {
                RestTimerView(remainingSeconds: remaining) {
                    stopRestTimer()
                }
                .transition(.move(edge: .bottom))
            }
        }
        .onDisappear {
            stopRestTimer()
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
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.wrappedValue.exerciseName)
                        .font(.headline)
                    Text(viewModel.exerciseSubtitle(for: entry.wrappedValue.scheduled))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ProgressView(value: entry.wrappedValue.completionProgress)
                    .progressViewStyle(.linear)
                    .frame(width: 120)
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
        }
    }

    private func startRestTimer(for exerciseId: String) {
        restTimer?.invalidate()
        let duration = viewModel.recommendedRest(for: exerciseId)
        restTimeRemaining = duration

        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            guard let remaining = restTimeRemaining else {
                timer.invalidate()
                return
            }

            if remaining <= 0 {
                timer.invalidate()
                restTimeRemaining = nil
                return
            }

            restTimeRemaining = remaining - 1
        }
    }

    private func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        restTimeRemaining = nil
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
