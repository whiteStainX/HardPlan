import SwiftUI

struct LocaleSettingsView: View {
    @Binding var firstDayOfWeek: Int

    private var weekdayOptions: [(label: String, value: Int)] {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.weekdaySymbols.enumerated().map { index, symbol in
            (label: symbol, value: index + 1)
        }
    }

    var body: some View {
        Form {
            Section {
                Picker("First Day of Week", selection: $firstDayOfWeek) {
                    ForEach(weekdayOptions, id: \.value) { option in
                        Text(option.label).tag(option.value)
                    }
                }
            } footer: {
                Text("Choose the day your weeks begin. This is used for calendars, analytics, and weekly summaries.")
            }
        }
        .navigationTitle("Locale")
    }
}

#Preview {
    LocaleSettingsView(firstDayOfWeek: .constant(2))
}
