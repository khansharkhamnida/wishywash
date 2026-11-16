//
//  ReturnPlan.swift
//  wishywash
//

import Foundation

/// When the user should leave to be back at the laundromat as their cycle finishes
struct ReturnPlan: Codable {
    let bookingId: String
    let cycleEnd: Date
    let travelMinutes: Int
    let bufferMinutes: Int
    let mode: TravelMode
    /// True when the user typed the travel time instead of it coming from Apple Maps
    let isManualEstimate: Bool
    var reminderOn: Bool

    var leaveAt: Date {
        ReturnCalculator.leaveAt(cycleEnd: cycleEnd, travelMinutes: travelMinutes, bufferMinutes: bufferMinutes)
    }
}
