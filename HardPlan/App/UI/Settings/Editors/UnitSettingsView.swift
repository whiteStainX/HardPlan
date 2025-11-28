import SwiftUI

struct UnitSettingsView: View {
    @Binding var unit: UnitSystem
    @Binding var minPlateIncrement: Double

    var body: some View {
        Form {
            Section("Units") {
                Picker("Preferred Unit", selection: $unit) {
                    Text("Pounds (lbs)").tag(UnitSystem.lbs)
                    Text("Kilograms (kg)").tag(UnitSystem.kg)
                }
                .pickerStyle(.segmented)
            }

            Section("Loading Increments") {
                VStack(alignment: .leading, spacing: 8) {
                    Stepper(
                        value: Binding(
                            get: { minPlateIncrement },
                            set: { minPlateIncrement = max(0.25, $0) }
                        ),
                        in: 0.25...10,
                        step: stepValue(for: unit)
                    ) {
                        Text("Minimum Plate Increment: \(minPlateIncrement, specifier: "%.2f")")
                    }

                    Text(recommendationText(for: unit))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Units & Loading")
        .onChange(of: unit) { _, newValue in
            minPlateIncrement = defaultIncrement(for: newValue)
        }
    }

    private func stepValue(for unit: UnitSystem) -> Double {
        switch unit {
        case .lbs:
            return 0.5
        case .kg:
            return 0.25
        }
    }

    private func defaultIncrement(for unit: UnitSystem) -> Double {
        switch unit {
        case .lbs:
            return 2.5
        case .kg:
            return 1.25
        }
    }

    private func recommendationText(for unit: UnitSystem) -> String {
        switch unit {
        case .lbs:
            return "Recommended: 2.5 lb jumps (1.25 per side)."
        case .kg:
            return "Recommended: 1.25 kg jumps (0.625 per side)."
        }
    }
}

#Preview {
    UnitSettingsView(unit: .constant(.lbs), minPlateIncrement: .constant(2.5))
}
