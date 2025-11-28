import SwiftUI

struct ExperienceView: View {
    let selectedTrainingAge: TrainingAge
    let onSelect: (TrainingAge) -> Void
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("How fast do you progress on main lifts?")
                    .font(.title2)
                    .bold()
                Text("We'll adjust progression targets based on your training age.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                trainingAgeCard(
                    title: "Novice",
                    subtitle: "Add weight every session",
                    trainingAge: .novice
                )

                trainingAgeCard(
                    title: "Intermediate",
                    subtitle: "Progress weekly or monthly",
                    trainingAge: .intermediate
                )

                trainingAgeCard(
                    title: "Advanced",
                    subtitle: "Progress over multiple months",
                    trainingAge: .advanced
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
    private func trainingAgeCard(title: String, subtitle: String, trainingAge: TrainingAge) -> some View {
        Button {
            onSelect(trainingAge)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                Spacer()
                if selectedTrainingAge == trainingAge {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedTrainingAge == trainingAge ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ExperienceView(selectedTrainingAge: .novice, onSelect: { _ in }, onNext: {}, onBack: {})
        .padding()
}
