//
//  GoalSetting.swift
//  HardPlan
//
//  Captures structured goal details for projections and analytics overlays.

import Foundation

struct GoalSetting: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var liftId: String
    var metric: GoalMetric
    var targetValue: Double
    var targetDate: String
    /// Expected weekly rate of progress for the chosen metric.
    var weeklyProgressRate: Double?
    /// Optional baseline value to anchor projections.
    var baselineValue: Double?

    init(
        id: UUID = UUID(),
        liftId: String,
        metric: GoalMetric = .estimated1RM,
        targetValue: Double,
        targetDate: String,
        weeklyProgressRate: Double? = nil,
        baselineValue: Double? = nil
    ) {
        self.id = id
        self.liftId = liftId
        self.metric = metric
        self.targetValue = targetValue
        self.targetDate = targetDate
        self.weeklyProgressRate = weeklyProgressRate
        self.baselineValue = baselineValue
    }
}
