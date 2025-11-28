//
//  AdherenceStatus.swift
//  HardPlan
//
//  Defines the status of a user's adherence to their training schedule.

import Foundation

enum AdherenceStatus: Equatable {
    case onTrack
    case returningFromBreak(daysSinceLastLog: Int, loadModifier: Double)

    var loadModifier: Double {
        switch self {
        case .onTrack:
            return 1.0 // No load modification
        case .returningFromBreak(_, let modifier):
            return modifier
        }
    }
}