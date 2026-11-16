//
//  ReturnCalculator.swift
//  wishywash
//

import Foundation

enum ReturnVerdict {
    /// There is still time to leave at the recommended time
    case comfortable
    /// The recommended time has passed, but leaving now still gets back by the time the cycle ends
    case tight
    /// Leaving now gets back after the cycle has ended, so the laundry waits
    case afterCycleEnds
    /// The cycle has already finished and the laundry is waiting
    case cycleEnded
}

/// Works out when to leave to be back as the cycle ends. Kept free of UI and system services.
enum ReturnCalculator {
    /// Smaller than the arrival buffer: arriving a little early only means waiting, and a wash needs no check-in
    static let bufferMinutes = 5

    static func leaveAt(cycleEnd: Date, travelMinutes: Int, bufferMinutes: Int) -> Date {
        cycleEnd.addingTimeInterval(-TimeInterval((travelMinutes + bufferMinutes) * 60))
    }

    static func verdict(now: Date, cycleEnd: Date, travelMinutes: Int) -> ReturnVerdict {
        if now >= cycleEnd { return .cycleEnded }
        let leave = leaveAt(cycleEnd: cycleEnd, travelMinutes: travelMinutes, bufferMinutes: bufferMinutes)
        if now <= leave { return .comfortable }
        let backIfLeavingNow = now.addingTimeInterval(TimeInterval(travelMinutes * 60))
        return backIfLeavingNow <= cycleEnd ? .tight : .afterCycleEnds
    }
}
