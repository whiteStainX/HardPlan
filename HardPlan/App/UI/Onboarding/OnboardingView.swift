//
//  OnboardingView.swift
//  HardPlan
//
//  Temporary placeholder for the onboarding flow. The full multi-screen
//  wizard will be implemented in Phase 3.4.
//

import SwiftUI

struct OnboardingView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)

                Text("Welcome to HardPlan")
                    .font(.title)
                    .bold()

                Text("Onboarding flow coming soon. We'll collect your goals, experience, and schedule to build your program.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("Get Started")
        }
    }
}

#Preview {
    OnboardingView()
}
