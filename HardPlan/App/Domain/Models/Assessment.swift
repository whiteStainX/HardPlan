//
//  Assessment.swift
//  HardPlan
//
//  Defines models for the post-block assessment flow.

import Foundation

enum PostBlockDecision: String, Codable, CaseIterable {
    case deload
    case nextBlock

    var title: String {
        switch self {
        case .deload:
            return "Start a Deload"
        case .nextBlock:
            return "Start Next Block"
        }
    }

    var subtitle: String {
        switch self {
        case .deload:
            return "Reduce volume to recover and prepare for the next phase."
        case .nextBlock:
            return "Continue with a new block, increasing load targets."
        }
    }
}

struct PostBlockResponses: Codable, Equatable {
    var sleepQuality: Double = 5
    var stressLevel: Double = 5
    var acheLevel: Double = 5

    var recoveryRiskScore: Int {
        var score = 0
        if sleepQuality < 5 { score += 1 }
        if stressLevel > 6 { score += 1 }
        if acheLevel > 6 { score += 1 }
        return score
    }

    var readinessLabel: String {
        let totalScore = (sleepQuality - stressLevel - acheLevel).clamped(to: -10...10)
        
        if totalScore >= 4 {
            return "Feeling Great"
        } else if totalScore >= -2 {
            return "Feeling OK"
        } else if totalScore >= -6 {
            return "Feeling Fatigued"
        } else {
            return "Feeling Worn Down"
        }
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
