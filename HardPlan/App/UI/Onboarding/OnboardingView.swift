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
                case .focus:
                    TrainingFocusView(
                        goal: $viewModel.selectedGoal,
                        weakPoints: $viewModel.weakPoints
                    )
                    .toolbar(.hidden, for: .navigationBar)
                    .safeAreaInset(edge: .bottom) {
                        HStack {
                            Button("Back") { viewModel.step = .goal }
                            Spacer()
                            Button("Continue", action: viewModel.advanceFromFocus)
                                .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                    }
                case .experience:
                    ExperienceView(
                        selectedTrainingAge: $viewModel.selectedTrainingAge,
                        onNext: viewModel.advanceFromExperience,
                        onBack: { viewModel.step = .focus }
                    )
                case .schedule:
                    ScheduleView(
                        trainingAge: viewModel.selectedTrainingAge,
                        goal: viewModel.selectedGoal,
                        weakPoints: viewModel.weakPoints,
                        availableDays: Binding(
                            get: { viewModel.availableDays },
                            set: { viewModel.updateAvailableDays($0) }
                        ),
                        assignments: $viewModel.dayAssignments,
                        blocks: viewModel.weeklyBlocks,
                        warningText: viewModel.adherenceWarning(),
                        onNext: viewModel.advanceFromSchedule,
                        onBack: { viewModel.step = .experience }
                    )
                case .units:
                    UnitSettingsView(
                        unit: $viewModel.unit,
                        minPlateIncrement: $viewModel.minPlateIncrement
                    )
                    .toolbar(.hidden, for: .navigationBar)
                    .safeAreaInset(edge: .bottom) {
                        HStack {
                            Button("Back") { viewModel.step = .schedule }
                            Spacer()
                            Button("Generate Plan", action: viewModel.startGeneratingProfile)
                                .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                    }
                case .generating:
                    GeneratingView()
                }
            }
            .padding()
            .navigationTitle("Get Started")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            viewModel.configure { profile, assignments in
                appState.onboardUser(profile: profile, assignedBlocks: assignments)
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
            return "Step 1 of 6: Welcome"
        case .goal:
            return "Step 2 of 6: Goal"
        case .focus:
            return "Step 3 of 6: Focus"
        case .experience:
            return "Step 4 of 6: Training Age"
        case .schedule:
            return "Step 5 of 6: Schedule"
        case .units:
            return "Step 6 of 6: Units"
        case .generating:
            return "Generating your program"
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
