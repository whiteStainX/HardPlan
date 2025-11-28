import Foundation
import Combine
struct VolumeSummary: Identifiable {
    enum Status {
        case under
        case optimal
        case over

        var label: String {
            switch self {
            case .under:
                return "Under"
            case .optimal:
                return "On Track"
            case .over:
                return "High"
            }
        }
    }

    let id = UUID()
    let muscleGroup: MuscleGroup
    let sets: Double
    let status: Status
}

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var weeklyAdherence: (completed: Int, scheduled: Int)?
    @Published var volumeSummaries: [VolumeSummary] = []
    @Published var nextSession: ScheduledSession?
    @Published var nextSessionLabel: String = ""

    private let volumeService: VolumeServiceProtocol
    private let calendar: Calendar
    private let isoFormatter: ISO8601DateFormatter
    private let dayFormatter: DateFormatter

    init(
        volumeService: VolumeServiceProtocol = DependencyContainer.shared.resolve(),
        calendar: Calendar = .current
    ) {
        self.volumeService = volumeService
        self.calendar = calendar

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        self.isoFormatter = isoFormatter

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        self.dayFormatter = dayFormatter
    }

    func refresh(from appState: AppState) {
        let logsThisWeek = filterLogsForCurrentWeek(appState.workoutLogs)
        weeklyAdherence = computeWeeklyAdherence(program: appState.activeProgram, logs: logsThisWeek)
        volumeSummaries = computeVolumes(logs: logsThisWeek)
        configureNextSession(program: appState.activeProgram)
    }

    private func computeWeeklyAdherence(program: ActiveProgram?, logs: [WorkoutLog]) -> (Int, Int)? {
        guard let program else { return nil }

        let completed = logs.filter { $0.status == .completed }.count
        let scheduled = program.weeklySchedule.count
        return (completed, scheduled)
    }

    private func computeVolumes(logs: [WorkoutLog]) -> [VolumeSummary] {
        let totals = volumeService.calculateWeeklyVolume(logs: logs)

        return totals
            .map { muscle, sets in
                VolumeSummary(
                    muscleGroup: muscle,
                    sets: sets,
                    status: classifyVolume(sets)
                )
            }
            .sorted { $0.sets > $1.sets }
    }

    private func classifyVolume(_ sets: Double) -> VolumeSummary.Status {
        if sets < 10 {
            return .under
        }

        if sets > 20 {
            return .over
        }

        return .optimal
    }

    private func configureNextSession(program: ActiveProgram?) {
        guard let program else {
            nextSession = nil
            nextSessionLabel = "No program"
            return
        }

        let today = calendar.component(.weekday, from: Date())
        let sortedSessions = program.weeklySchedule.sorted { first, second in
            let firstDelta = (first.dayOfWeek - today + 7) % 7
            let secondDelta = (second.dayOfWeek - today + 7) % 7
            return firstDelta < secondDelta
        }

        guard let upcoming = sortedSessions.first else {
            nextSession = nil
            nextSessionLabel = "No sessions scheduled"
            return
        }

        nextSession = upcoming
        nextSessionLabel = label(for: upcoming, todayWeekday: today)
    }

    private func label(for session: ScheduledSession, todayWeekday: Int) -> String {
        if session.dayOfWeek == todayWeekday {
            return "Today's Workout"
        }

        let components = DateComponents(weekday: session.dayOfWeek)
        if let date = calendar.nextDate(after: Date(), matching: components, matchingPolicy: .nextTimePreservingSmallerComponents) {
            return dayFormatter.string(from: date)
        }

        return "Upcoming"
    }

    private func filterLogsForCurrentWeek(_ logs: [WorkoutLog]) -> [WorkoutLog] {
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
            return []
        }

        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? Date()

        return logs.compactMap { log in
            guard let date = parseDate(log.dateCompleted) else { return nil }
            return (date >= startOfWeek && date < endOfWeek) ? log : nil
        }
    }

    private func parseDate(_ string: String) -> Date? {
        if let date = isoFormatter.date(from: string) {
            return date
        }

        let fallbackFormatter = DateFormatter()
        fallbackFormatter.dateFormat = "yyyy-MM-dd"
        fallbackFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return fallbackFormatter.date(from: string)
    }
}
