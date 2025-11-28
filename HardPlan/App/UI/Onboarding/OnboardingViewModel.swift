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
    @Published var weakPoints: [MuscleGroup] = []
    @Published var unit: UnitSystem = .lbs
    @Published var minPlateIncrement: Double = 2.5
    @Published var isGenerating: Bool = false

    private var onboardingAction: ((UserProfile) -> Void)?
    private var hasConfiguredHandler = false

    func configure(onboardingAction: @escaping (UserProfile) -> Void) {
        guard !hasConfiguredHandler else { return }
        self.onboardingAction = onboardingAction
        hasConfiguredHandler = true
    }

    func advanceFromWelcome() {
        step = .goal
    }

    func selectGoal(_ goal: Goal) {
        selectedGoal = goal
    }

    func advanceFromGoal() {
        step = .focus
    }

    func advanceFromFocus() {
        step = .experience
    }

    func selectTrainingAge(_ trainingAge: TrainingAge) {
        selectedTrainingAge = trainingAge
    }

    func advanceFromExperience() {
        step = .schedule
    }

    func updateAvailableDays(_ days: Int) {
        availableDays = max(2, min(6, days))
    }

    func advanceFromSchedule() {
        step = .units
    }

    func startGeneratingProfile() {
        step = .generating
        isGenerating = true

        let profile = buildProfile()
        let action = onboardingAction

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            action?(profile)
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

    private func buildProfile() -> UserProfile {
        UserProfile(
            name: "Athlete",
            trainingAge: selectedTrainingAge,
            goal: selectedGoal,
            availableDays: Array(1...availableDays),
            weakPoints: weakPoints,
            unit: unit,
            minPlateIncrement: minPlateIncrement,
            onboardingCompleted: false
        )
    }
}
