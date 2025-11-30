//
//  Analytics.swift
//  HardPlan
//
//  Implemented during Phase 1.2 to match DATA_SCHEMA specifications.

import Foundation

struct E1RMPoint: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var date: String
    var e1rm: Double

    init(id: UUID = UUID(), date: String, e1rm: Double) {
        self.id = id
        self.date = date
        self.e1rm = e1rm
    }
}

struct RPERangeBin: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var rangeLabel: String
    var count: Int
    var periodWeeks: Int

    init(id: UUID = UUID(), rangeLabel: String, count: Int, periodWeeks: Int) {
        self.id = id
        self.rangeLabel = rangeLabel
        self.count = count
        self.periodWeeks = periodWeeks
    }
}

struct BlockPhaseSegment: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var startDate: String
    var endDate: String
    var phase: String

    init(id: UUID = UUID(), startDate: String, endDate: String, phase: String) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.phase = phase
    }
}

struct ProjectionSummary: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var baseline: Double
    var projectedToday: Double
    var variance: Double
    var targetDate: String?
    var targetValue: Double?

    init(
        id: UUID = UUID(),
        baseline: Double,
        projectedToday: Double,
        variance: Double,
        targetDate: String? = nil,
        targetValue: Double? = nil
    ) {
        self.id = id
        self.baseline = baseline
        self.projectedToday = projectedToday
        self.variance = variance
        self.targetDate = targetDate
        self.targetValue = targetValue
    }
}

struct AnalyticsSnapshot: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var liftId: String
    var e1RMHistory: [E1RMPoint]
    var projectedE1RMHistory: [E1RMPoint]
    var rpeDistribution: [RPERangeBin]
    var blockPhaseSegments: [BlockPhaseSegment]
    var projectionSummary: ProjectionSummary?
    var lastUpdatedAt: String

    init(
        id: UUID = UUID(),
        liftId: String,
        e1RMHistory: [E1RMPoint] = [],
        projectedE1RMHistory: [E1RMPoint] = [],
        rpeDistribution: [RPERangeBin] = [],
        blockPhaseSegments: [BlockPhaseSegment] = [],
        projectionSummary: ProjectionSummary? = nil,
        lastUpdatedAt: String
    ) {
        self.id = id
        self.liftId = liftId
        self.e1RMHistory = e1RMHistory
        self.projectedE1RMHistory = projectedE1RMHistory
        self.rpeDistribution = rpeDistribution
        self.blockPhaseSegments = blockPhaseSegments
        self.projectionSummary = projectionSummary
        self.lastUpdatedAt = lastUpdatedAt
    }
}

struct TempoWarning: Identifiable, Codable, Equatable {
    enum Level: String, Codable {
        case info
        case warning
    }

    var id: UUID = UUID()
    var level: Level
    var message: String

    init(id: UUID = UUID(), level: Level, message: String) {
        self.id = id
        self.level = level
        self.message = message
    }
}
