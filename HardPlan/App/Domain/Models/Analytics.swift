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

struct AnalyticsSnapshot: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var liftId: String
    var e1RMHistory: [E1RMPoint]
    var rpeDistribution: [RPERangeBin]
    var blockPhaseSegments: [BlockPhaseSegment]
    var lastUpdatedAt: String

    init(
        id: UUID = UUID(),
        liftId: String,
        e1RMHistory: [E1RMPoint] = [],
        rpeDistribution: [RPERangeBin] = [],
        blockPhaseSegments: [BlockPhaseSegment] = [],
        lastUpdatedAt: String
    ) {
        self.id = id
        self.liftId = liftId
        self.e1RMHistory = e1RMHistory
        self.rpeDistribution = rpeDistribution
        self.blockPhaseSegments = blockPhaseSegments
        self.lastUpdatedAt = lastUpdatedAt
    }
}
