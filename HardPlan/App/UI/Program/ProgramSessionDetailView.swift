import SwiftUI

struct ProgramSessionDetailView: View {
    let session: ProgramSessionDisplay

    var body: some View {
        List {
            if session.exercises.isEmpty {
                Section {
                    Text("No exercises scheduled for this session.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }
            } else {
                Section("Exercises") {
                    ForEach(session.exercises) { exercise in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(exercise.name)
                                .font(.headline)
                            Text(exercise.prescription)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if let note = exercise.note {
                                Text(note)
                                    .font(.footnote)
                                    .foregroundStyle(Color(.tertiaryLabel))
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .navigationTitle("\(session.dayLabel) - \(session.sessionName)")
    }
}
