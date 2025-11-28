import Foundation

enum PostBlockDecision: String, Codable, CaseIterable, Identifiable {
    case deload
    case nextBlock

    var id: String { rawValue }
    var title: String {
        switch self {
        case .deload:
            return "Start Deload"
        case .nextBlock:
            return "Advance Block"
        }
    }

    var subtitle: String {
        switch self {
        case .deload:
            return "Reduce volume and RPE for recovery."
        case .nextBlock:
            return "Carry momentum into the next phase."
        }
    }
}

struct PostBlockResponses: Codable, Equatable {
    var sleepQuality: Double
    var stressLevel: Double
    var acheLevel: Double

    init(sleepQuality: Double = 7, stressLevel: Double = 5, acheLevel: Double = 4) {
        self.sleepQuality = sleepQuality
        self.stressLevel = stressLevel
        self.acheLevel = acheLevel
    }

    var recoveryRiskScore: Int {
        var score = 0
        if sleepQuality < 6 { score += 1 }
        if stressLevel > 7 { score += 1 }
        if acheLevel > 6 { score += 1 }
        return score
    }

    var readinessLabel: String {
        if recoveryRiskScore == 0 {
            return "Ready to push"
        }
        if recoveryRiskScore == 1 {
            return "Monitor fatigue"
        }
        return "High fatigue risk"
    }
}
