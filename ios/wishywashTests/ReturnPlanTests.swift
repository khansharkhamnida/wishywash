//
//  ReturnPlanTests.swift
//  wishywashTests
//
//  The way-back plan: leave time, verdicts, saved data, reminder ids and the screen's wording.
//

import Foundation
import Testing
@testable import wishywash

// MARK: - Leave time and verdicts
struct ReturnCalculatorTests {
    private let minute: TimeInterval = 60
    private let now = Date(timeIntervalSinceReferenceDate: 800_000_000)

    @Test func leaveTimeIsCycleEndMinusTravelAndBuffer() {
        let end = now.addingTimeInterval(60 * minute)
        let leave = ReturnCalculator.leaveAt(cycleEnd: end, travelMinutes: 20, bufferMinutes: 5)
        #expect(leave == end.addingTimeInterval(-25 * minute))
    }

    @Test func planUsesTheSameLeaveTime() {
        let end = now.addingTimeInterval(60 * minute)
        let plan = ReturnPlan(bookingId: "b", cycleEnd: end, travelMinutes: 20, bufferMinutes: 5,
                              mode: .driving, isManualEstimate: false, reminderOn: false)
        #expect(plan.leaveAt == end.addingTimeInterval(-25 * minute))
    }

    @Test func comfortableWhenThereIsTimeToSpare() {
        let end = now.addingTimeInterval(60 * minute)
        #expect(ReturnCalculator.verdict(now: now, cycleEnd: end, travelMinutes: 20) == .comfortable)
    }

    @Test func comfortableExactlyAtLeaveTime() {
        let travel = 20
        let end = now.addingTimeInterval(TimeInterval(travel + ReturnCalculator.bufferMinutes) * minute)
        #expect(ReturnCalculator.verdict(now: now, cycleEnd: end, travelMinutes: travel) == .comfortable)
    }

    @Test func tightWhenBufferIsUsedUpButStillBackInTime() {
        // 22 min left, 20 min trip: past the leave time (25 min before) but back 2 min early
        let end = now.addingTimeInterval(22 * minute)
        #expect(ReturnCalculator.verdict(now: now, cycleEnd: end, travelMinutes: 20) == .tight)
    }

    @Test func tightWhenBackExactlyAsCycleEnds() {
        let end = now.addingTimeInterval(20 * minute)
        #expect(ReturnCalculator.verdict(now: now, cycleEnd: end, travelMinutes: 20) == .tight)
    }

    @Test func afterCycleEndsWhenTheTripIsLongerThanTheTimeLeft() {
        let end = now.addingTimeInterval(10 * minute)
        #expect(ReturnCalculator.verdict(now: now, cycleEnd: end, travelMinutes: 25) == .afterCycleEnds)
    }

    @Test func cycleEndedWhenTheEndTimeHasPassed() {
        let end = now.addingTimeInterval(-3 * minute)
        #expect(ReturnCalculator.verdict(now: now, cycleEnd: end, travelMinutes: 5) == .cycleEnded)
    }

    @Test func cycleEndedExactlyAtTheEndTime() {
        #expect(ReturnCalculator.verdict(now: now, cycleEnd: now, travelMinutes: 5) == .cycleEnded)
    }
}

// MARK: - Saved data
final class ReturnPlanStoreTests {
    private let suiteName = "ReturnPlanStoreTests-\(UUID().uuidString)"
    private let defaults: UserDefaults
    private let store: LocalStore
    private let returns: ReturnPlanStore
    private let arrivals: ArrivalPlanStore

    init() {
        defaults = UserDefaults(suiteName: suiteName)!
        store = LocalStore(defaults: defaults)
        returns = ReturnPlanStore(store: store)
        arrivals = ArrivalPlanStore(store: store)
    }

    deinit {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    private func returnPlan(_ id: String) -> ReturnPlan {
        ReturnPlan(bookingId: id, cycleEnd: Date().addingTimeInterval(1800), travelMinutes: 10, bufferMinutes: 5,
                   mode: .walking, isManualEstimate: true, reminderOn: false)
    }

    private func arrivalPlan(_ id: String) -> ArrivalPlan {
        ArrivalPlan(bookingId: id, arriveBy: Date().addingTimeInterval(1800), travelMinutes: 10, bufferMinutes: 10,
                    mode: .driving, isManualEstimate: false, reminderOn: false)
    }

    @Test func savesAndLoadsAPlan() throws {
        returns.save(returnPlan("b1"))
        let loaded = try #require(returns.plan(for: "b1"))
        #expect(loaded.travelMinutes == 10)
        #expect(loaded.mode == .walking)
        #expect(loaded.isManualEstimate)
    }

    @Test func removeDeletesThePlan() {
        returns.save(returnPlan("b1"))
        returns.remove(bookingId: "b1")
        #expect(returns.plan(for: "b1") == nil)
    }

    @Test func pruneKeepsOnlyListedBookings() {
        returns.save(returnPlan("keep"))
        returns.save(returnPlan("drop"))
        returns.prune(keeping: ["keep"])
        #expect(returns.plan(for: "keep") != nil)
        #expect(returns.plan(for: "drop") == nil)
    }

    @Test func notificationIdDiffersFromTheArrivalOne() {
        for id in ["b1", "return-b1", "leave-b1", ""] {
            #expect(ReturnPlanStore.notificationId(for: id) != ArrivalPlanStore.notificationId(for: id))
        }
        // An arrival id for one booking can never equal a return id for another
        #expect(ReturnPlanStore.notificationId(for: "leave-x") != ArrivalPlanStore.notificationId(for: "return-x"))
        #expect(!ReturnPlanStore.notificationId(for: "b1").hasPrefix("leave-"))
    }

    @Test func plansAreKeptApartFromArrivalPlans() {
        arrivals.save(arrivalPlan("same"))
        returns.save(returnPlan("same"))

        returns.remove(bookingId: "same")

        #expect(arrivals.plan(for: "same") != nil)
        #expect(returns.plan(for: "same") == nil)
        #expect(StoreKey.returnPlans != StoreKey.arrivalPlans)
    }

    @Test func oldSavedArrivalPlansStillDecode() throws {
        // Written by an earlier version of the app, before way-back plans existed
        let old = """
        {"b1":{"bookingId":"b1","arriveBy":800000000,"travelMinutes":15,"bufferMinutes":10,\
        "mode":"transit","isManualEstimate":false,"reminderOn":true}}
        """
        defaults.set(Data(old.utf8), forKey: StoreKey.arrivalPlans)

        let plan = try #require(arrivals.plan(for: "b1"))
        #expect(plan.travelMinutes == 15)
        #expect(plan.mode == .transit)
        #expect(plan.reminderOn)
        #expect(returns.plans.isEmpty)
    }

    @Test func nothingSavedMeansNoReturnPlans() {
        #expect(returns.plans.isEmpty)
        #expect(returns.plan(for: "anything") == nil)
    }
}

// MARK: - The booking service tidies way-back plans
final class ReturnPlanPruningTests {
    private let suiteName = "ReturnPlanPruningTests-\(UUID().uuidString)"
    private let minute: TimeInterval = 60
    private let store: LocalStore
    private let returns: ReturnPlanStore

    init() {
        store = LocalStore(defaults: UserDefaults(suiteName: suiteName)!)
        returns = ReturnPlanStore(store: store)
    }

    deinit {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    private func machine(_ id: String, status: MachineStatus, availableAt: Date?) -> Machine {
        Machine(id: id, laundromatId: "l1", type: .washer, label: id.uppercased(),
                capacityKg: 10, status: status, pricePerCycle: 5, cycleMinutes: 30, availableAt: availableAt)
    }

    private func booking(_ id: String, machine: String, start: Date, status: BookingStatus) -> Booking {
        Booking(id: id, userId: "u", laundromatId: "l1", machineId: machine,
                startTime: start, endTime: start.addingTimeInterval(30 * minute),
                status: status, totalPrice: 5, paymentId: "p", createdAt: start, holdExpiresAt: nil)
    }

    private func plan(_ id: String) -> ReturnPlan {
        ReturnPlan(bookingId: id, cycleEnd: Date(), travelMinutes: 10, bufferMinutes: 5,
                   mode: .walking, isManualEstimate: false, reminderOn: false)
    }

    @Test func finishedCycleRemovesItsPlanAndRunningKeepsIt() {
        let now = Date()
        let service = LocalBookingService(
            machines: [machine("m1", status: .inUse, availableAt: now.addingTimeInterval(-minute)),
                       machine("m2", status: .inUse, availableAt: now.addingTimeInterval(10 * minute))],
            bookings: [booking("done", machine: "m1", start: now.addingTimeInterval(-31 * minute), status: .inProgress),
                       booking("running", machine: "m2", start: now.addingTimeInterval(-20 * minute), status: .inProgress)],
            store: store,
            plans: ArrivalPlanStore(store: store),
            returnPlans: returns)
        returns.save(plan("done"))
        returns.save(plan("running"))

        _ = service.bookings

        #expect(returns.plan(for: "done") == nil)
        #expect(returns.plan(for: "running") != nil)
    }

    @Test func planForABookingThatIsNotRunningIsRemoved() {
        let now = Date()
        let service = LocalBookingService(
            machines: [machine("m1", status: .available, availableAt: nil)],
            bookings: [],
            store: store,
            plans: ArrivalPlanStore(store: store),
            returnPlans: returns)
        returns.save(plan("ghost"))

        _ = service.bookings

        #expect(returns.plan(for: "ghost") == nil)
        _ = now
    }
}

// MARK: - What the screen says
private final class FakeCheckView: ArrivalCheckViewProtocol {
    var model: ArrivalCheckViewModel?
    func render(_ model: ArrivalCheckViewModel) { self.model = model }
}

final class ReturnCheckPresenterTests {
    private let minute: TimeInterval = 60
    private let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
    private let view = FakeCheckView()
    private let presenter = ReturnCheckPresenter()

    init() {
        presenter.view = view
        presenter.now = { [now] in now }
    }

    private func show(minutesLeft: Int, travelMinutes: Int, remindersAllowed: Bool = true,
                      permission: PermissionState = .granted) -> ArrivalResultViewModel? {
        let end = now.addingTimeInterval(TimeInterval(minutesLeft) * minute)
        let booking = Booking(id: "b", userId: "u", laundromatId: "l1", machineId: "m1",
                              startTime: end.addingTimeInterval(-30 * minute), endTime: end,
                              status: .inProgress, totalPrice: 5, paymentId: "p",
                              createdAt: end, holdExpiresAt: nil)
        let plan = ReturnPlan(bookingId: "b", cycleEnd: end, travelMinutes: travelMinutes,
                              bufferMinutes: ReturnCalculator.bufferMinutes, mode: .driving,
                              isManualEstimate: false, reminderOn: false)
        presenter.didLoadBooking(ReturnBookingInfo(detail: BookingDetail(booking: booking, machine: nil, laundromat: nil),
                                                   plan: plan, notificationPermission: permission,
                                                   remindersAllowed: remindersAllowed))
        return view.model?.result
    }

    @Test func comfortableShowsLeaveTimeAndCountdown() throws {
        let result = try #require(show(minutesLeft: 60, travelMinutes: 20))
        #expect(result.verdictText == "You'll be back as it finishes")
        #expect(result.countdownText == "Leave in 35 min")
        #expect(result.leaveByText.hasPrefix("Leave by"))
        #expect(result.reminder.isEnabled)
        #expect(result.detailText.contains("About 20 min by car + 5 min buffer"))
    }

    @Test func tightSaysLeaveNow() throws {
        let result = try #require(show(minutesLeft: 22, travelMinutes: 20))
        #expect(result.verdictText == "Leave now to be back in time")
        #expect(result.leaveByText == "Leave now")
        #expect(!result.reminder.isEnabled)
    }

    @Test func lateSaysHowManyMinutesAfterTheCycleEnds() throws {
        let result = try #require(show(minutesLeft: 10, travelMinutes: 25))
        #expect(result.verdictText == "You'd be about 15 min after the cycle ends")
        #expect(result.leaveByText == "Leave now")
        #expect(!result.reminder.isEnabled)
    }

    @Test func finishedCycleSaysTheLaundryIsWaiting() throws {
        let result = try #require(show(minutesLeft: -4, travelMinutes: 12))
        #expect(result.verdictText == "Your laundry is ready")
        #expect(result.leaveByText == "Leave now")
        #expect(result.detailText.contains("You could be there in about 12 min"))
        #expect(!result.detailText.contains("buffer"))
        #expect(!result.reminder.isEnabled)
        #expect(result.reminder.statusText.hasPrefix("Your laundry is already ready"))
    }

    @Test func remindersSwitchedOffInProfileDisableTheToggle() throws {
        let result = try #require(show(minutesLeft: 60, travelMinutes: 20, remindersAllowed: false))
        #expect(!result.reminder.isEnabled)
        #expect(result.reminder.statusText.contains("Profile > Notifications"))
    }

    @Test func deniedPermissionDisablesTheToggleAndOffersSettings() throws {
        let result = try #require(show(minutesLeft: 60, travelMinutes: 20, permission: .denied))
        #expect(!result.reminder.isEnabled)
        #expect(result.reminder.showsSettingsButton)
    }

    @Test func headerShowsWhenTheCycleEnds() throws {
        _ = show(minutesLeft: 30, travelMinutes: 10)
        let model = try #require(view.model)
        #expect(model.arriveByText.hasPrefix("Cycle ends at"))
        #expect(model.checkButtonTitle == "Recalculate")
    }
}
