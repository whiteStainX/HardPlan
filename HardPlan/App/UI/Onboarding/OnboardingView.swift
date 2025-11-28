//
//  OnboardingView.swift
//  HardPlan
//
//  Multi-step onboarding wizard implemented in Phase 3.4. Collects
//  training goal, experience, and schedule before generating an
//  ActiveProgram via AppState.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                progressHeader

                switch viewModel.step {
                case .welcome:
                    WelcomeView(onContinue: viewModel.advanceFromWelcome)
                case .goal:
                    GoalSelectionView(
                        selectedGoal: viewModel.selectedGoal,
                        onSelect: viewModel.selectGoal,
                        onNext: viewModel.advanceFromGoal,
                        onBack: { viewModel.step = .welcome }
                    )
                case .experience:
                    ExperienceView(
                        selectedTrainingAge: viewModel.selectedTrainingAge,
                        onSelect: viewModel.selectTrainingAge,
                        onNext: viewModel.advanceFromExperience,
                        onBack: { viewModel.step = .goal }
                    )
                case .schedule:
                    ScheduleView(
                        trainingAge: viewModel.selectedTrainingAge,
                        availableDays: viewModel.availableDays,
                        warningText: viewModel.adherenceWarning(),
                        onDaysChanged: viewModel.updateAvailableDays,
                        onNext: viewModel.startGeneratingProfile,
                        onBack: { viewModel.step = .experience }
                    )
                case .generating:
                    GeneratingView()
                }
            }
            .padding()
            .navigationTitle("Get Started")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            viewModel.configure { profile in
                appState.onboardUser(profile: profile)
            }
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProgressView(value: viewModel.step.progress)
                .progressViewStyle(.linear)
            Text(stepLabel(for: viewModel.step))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func stepLabel(for step: OnboardingViewModel.Step) -> String {
        switch step {
        case .welcome:
            return "Step 1 of 4: Welcome"
        case .goal:
            return "Step 2 of 4: Goal"
        case .experience:
            return "Step 3 of 4: Training Age"
        case .schedule:
            return "Step 4 of 4: Schedule"
        case .generating:
            return "Generating your program"
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
