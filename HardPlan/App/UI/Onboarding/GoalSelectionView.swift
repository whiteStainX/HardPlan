import SwiftUI

struct GoalSelectionView: View {
    let selectedGoal: Goal
    let onSelect: (Goal) -> Void
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What's your primary focus?")
                    .font(.title2)
                    .bold()
                Text("Choose the path that best matches your current priorities.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                goalCard(
                    title: "Hypertrophy",
                    subtitle: "Build muscle and aesthetics",
                    icon: "figure.arms.open",
                    goal: .hypertrophy
                )

                goalCard(
                    title: "Strength",
                    subtitle: "Train for powerlifting performance",
                    icon: "bolt.fill",
                    goal: .strength
                )
            }

            Spacer()

            HStack {
                Button("Back", action: onBack)
                Spacer()
                Button("Continue", action: onNext)
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    @ViewBuilder
    private func goalCard(title: String, subtitle: String, icon: String, goal: Goal) -> some View {
        Button {
            onSelect(goal)
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                Spacer()
                if selectedGoal == goal {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedGoal == goal ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GoalSelectionView(selectedGoal: .strength, onSelect: { _ in }, onNext: {}, onBack: {})
        .padding()
}
