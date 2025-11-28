import SwiftUI

struct TrainingFocusView: View {
    @Binding var goal: Goal
    @Binding var weakPoints: [MuscleGroup]

    var body: some View {
        Form {
            Section("Goal") {
                Picker("Primary Focus", selection: $goal) {
                    Text("Strength").tag(Goal.strength)
                    Text("Hypertrophy").tag(Goal.hypertrophy)
                }
                .pickerStyle(.segmented)
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
    }

    private func toggle(_ group: MuscleGroup) {
        if let index = weakPoints.firstIndex(of: group) {
            weakPoints.remove(at: index)
        } else {
            weakPoints.append(group)
        }
    }

    private func displayName(for group: MuscleGroup) -> String {
        group.rawValue.replacingOccurrences(of: "_", with: " ")
    }
}

#Preview {
    TrainingFocusView(goal: .constant(.hypertrophy), weakPoints: .constant([.chest, .backLats]))
}
