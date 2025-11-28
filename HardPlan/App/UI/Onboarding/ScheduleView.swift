import SwiftUI

struct ScheduleView: View {
    let trainingAge: TrainingAge
    @Binding var availableDays: Int
    let warningText: String?
    var onNext: () -> Void = {}
    var onBack: () -> Void = {}

    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("How many days per week can you train?")
                    .font(.title2)
                    .bold()
                Text("Set a realistic schedule so we can generate the right split for you.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 16) {
                HStack {
                    Text("Days per week")
                    Spacer()
                    Text("\(availableDays) days")
                        .bold()
                }

                Slider(
                    value: Binding(
                        get: { Double(availableDays) },
                        set: { availableDays = clampDays(Int($0.rounded())) }
                    ),
                    in: 2...6,
                    step: 1
                )

                if let warningText {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                        Text(warningText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.yellow.opacity(0.1))
                    )
                }
            }

            Spacer()

            HStack {
                Button("Back", action: onBack)
                Spacer()
                Button("Generate Program", action: onNext)
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private func clampDays(_ days: Int) -> Int {
        max(2, min(6, days))
    }
}

#Preview {
    ScheduleView(trainingAge: .novice, availableDays: .constant(4), warningText: "Sample warning")
        .padding()
}
