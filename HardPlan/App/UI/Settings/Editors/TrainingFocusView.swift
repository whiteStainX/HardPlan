import SwiftUI

struct TrainingFocusView: View {
    @Binding var goal: Goal
    @Binding var weakPoints: [MuscleGroup]
    @Binding var goalSetting: GoalSetting?

    @State private var exercises: [Exercise] = []

    private let exerciseRepository: ExerciseRepositoryProtocol
    private let isoFormatter: ISO8601DateFormatter

    init(
        goal: Binding<Goal>,
        weakPoints: Binding<[MuscleGroup]>,
        goalSetting: Binding<GoalSetting?>,
        exerciseRepository: ExerciseRepositoryProtocol = DependencyContainer.shared.resolve()
    ) {
        _goal = goal
        _weakPoints = weakPoints
        _goalSetting = goalSetting
        self.exerciseRepository = exerciseRepository

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        self.isoFormatter = formatter
    }

    var body: some View {
        Form {
            Section("Goal") {
                Picker("Primary Focus", selection: $goal) {
                    Text("Strength").tag(Goal.strength)
                    Text("Hypertrophy").tag(Goal.hypertrophy)
                }
                .pickerStyle(.segmented)
            }

            Section("Goal target") {
                Picker("Primary lift", selection: Binding(
                    get: { goalSetting?.liftId ?? exercises.first?.id ?? "" },
                    set: { newValue in ensureGoal(); goalSetting?.liftId = newValue }
                )) {
                    ForEach(exercises.filter { $0.tier == .tier1 }, id: \.id) { exercise in
                        Text(exercise.shortName ?? exercise.name).tag(exercise.id)
                    }
                }

                HStack {
                    Text("Target e1RM")
                    Spacer()
                    TextField("200", value: Binding(
                        get: { goalSetting?.targetValue ?? 0 },
                        set: { newValue in ensureGoal(); goalSetting?.targetValue = newValue }
                    ), format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                }

                DatePicker(
                    "Target date",
                    selection: Binding(
                        get: { targetDate },
                        set: { newDate in ensureGoal(); goalSetting?.targetDate = isoFormatter.string(from: newDate) }
                    ),
                    displayedComponents: .date
                )

                HStack {
                    Text("Weekly progression")
                    Spacer()
                    TextField("2.5", value: Binding(
                        get: { goalSetting?.weeklyProgressRate ?? 0 },
                        set: { newValue in ensureGoal(); goalSetting?.weeklyProgressRate = newValue }
                    ), format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    Text("per week")
                        .foregroundStyle(.secondary)
                }
            }

            Section(
                content: {
                    ForEach(MuscleGroup.allCases, id: \.self) { group in
                        Button {
                            toggle(group)
                        } label: {
                            HStack {
                                Text(displayName(for: group))
                                    .foregroundStyle(.primary)
                                Spacer()
                                if weakPoints.contains(group) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                },
                header: {
                    Text("Weak Points")
                },
                footer: {
                    Text("Select any muscle groups you want extra focus on. Leave blank if none.")
                }
            )
        }
        .navigationTitle("Training Focus")
        .onAppear(perform: hydrate)
    }

    private var targetDate: Date {
        if let raw = goalSetting?.targetDate, let date = isoFormatter.date(from: raw) {
            return date
        }
        return Date()
    }

    private func toggle(_ group: MuscleGroup) {
        if let index = weakPoints.firstIndex(of: group) {
            weakPoints.remove(at: index)
        } else {
            weakPoints.append(group)
        }
    }

    private func ensureGoal() {
        if goalSetting == nil {
            let defaultLift = exercises.first?.id ?? ""
            goalSetting = GoalSetting(
                liftId: defaultLift,
                targetValue: 0,
                targetDate: isoFormatter.string(from: Date())
            )
        }
    }

    private func hydrate() {
        exercises = exerciseRepository.getAllExercises()
    }

    private func displayName(for group: MuscleGroup) -> String {
        group.rawValue.replacingOccurrences(of: "_", with: " ")
    }
}

#Preview {
    TrainingFocusView(
        goal: .constant(.hypertrophy),
        weakPoints: .constant([.chest, .backLats]),
        goalSetting: .constant(nil)
    )
}
