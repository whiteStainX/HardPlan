import Foundation
import SwiftUI
import Combine

final class OnboardingViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case welcome
        case goal
        case focus
        case experience
        case schedule
        case units
        case generating

        var progress: Double {
            Double(rawValue) / Double(Step.generating.rawValue)
        }
    }

    @Published var step: Step = .welcome
    @Published var selectedGoal: Goal = .hypertrophy
    @Published var selectedTrainingAge: TrainingAge = .novice
    @Published var availableDays: Int = 3
    @Published var weakPoints: [MuscleGroup] = [] {
        didSet { regenerateBlocks() }
    }
    @Published var weeklyBlocks: [WorkoutBlock] = []
    @Published var dayAssignments: [Int: WorkoutBlock] = [:]
    @Published var unit: UnitSystem = .lbs
    @Published var minPlateIncrement: Double = 2.5
    @Published var isGenerating: Bool = false
    @Published var preferredFirstDayOfWeek: Int = Calendar.current.firstWeekday

    private var onboardingAction: ((UserProfile, [Int: WorkoutBlock]?) -> Void)?
    private let programGenerator: ProgramGeneratorProtocol
    private var hasConfiguredHandler = false

    init(programGenerator: ProgramGeneratorProtocol = DependencyContainer.shared.resolve()) {
        self.programGenerator = programGenerator
    }

    func configure(onboardingAction: @escaping (UserProfile, [Int: WorkoutBlock]?) -> Void) {
        guard !hasConfiguredHandler else { return }
        self.onboardingAction = onboardingAction
        hasConfiguredHandler = true
    }

    func advanceFromWelcome() {
        step = .goal
    }

    func selectGoal(_ goal: Goal) {
        selectedGoal = goal
        regenerateBlocks()
    }

    func advanceFromGoal() {
        step = .focus
    }

    func advanceFromFocus() {
        step = .experience
    }

    func selectTrainingAge(_ trainingAge: TrainingAge) {
        selectedTrainingAge = trainingAge
        regenerateBlocks()
    }

    func advanceFromExperience() {
        regenerateBlocks()
        step = .schedule
    }

    func updateAvailableDays(_ days: Int) {
        availableDays = max(2, min(6, days))
        regenerateBlocks()
    }

    func advanceFromSchedule() {
        step = .units
    }

    func startGeneratingProfile() {
        step = .generating
        isGenerating = true

        let profile = buildProfile()
        let assignments = dayAssignments.isEmpty ? nil : dayAssignments
        let action = onboardingAction

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            action?(profile, assignments)
        }
    }

    func adherenceWarning() -> String? {
        if selectedTrainingAge == .advanced && availableDays < 3 {
            return "Advanced lifters typically need 3+ days per week to hit quality volume."
        }

        if selectedTrainingAge == .novice && availableDays > 5 {
            return "Novice lifters usually progress best with 3-5 focused sessions per week."
        }

        return nil
    }

    func assign(block: WorkoutBlock, to day: Int) {
        dayAssignments[day] = block
    }

    func removeAssignment(for day: Int) {
        dayAssignments.removeValue(forKey: day)
    }

    func regenerateBlocks() {
        let profile = UserProfile(
            name: "Athlete",
            trainingAge: selectedTrainingAge,
            goal: selectedGoal,
            availableDays: Array(1...availableDays),
            weakPoints: weakPoints,
            unit: unit,
            minPlateIncrement: minPlateIncrement,
            onboardingCompleted: false,
            firstDayOfWeek: preferredFirstDayOfWeek
        )

        weeklyBlocks = programGenerator.generateWeeklyBlocks(for: profile)
        dayAssignments = [:]
    }

    private func buildProfile() -> UserProfile {
        let assignedDays = dayAssignments.keys.sorted()
        let scheduleDays = assignedDays.isEmpty ? Array(1...availableDays) : assignedDays

        return UserProfile(
            name: "Athlete",
            trainingAge: selectedTrainingAge,
            goal: selectedGoal,
            availableDays: scheduleDays,
            weakPoints: weakPoints,
            unit: unit,
            minPlateIncrement: minPlateIncrement,
            onboardingCompleted: false,
            firstDayOfWeek: preferredFirstDayOfWeek
        )
    }
}
