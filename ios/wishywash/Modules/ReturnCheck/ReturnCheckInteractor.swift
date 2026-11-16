//
//  ReturnCheckInteractor.swift
//  wishywash
//

import CoreLocation
import Foundation

final class ReturnCheckInteractor: ReturnCheckInteractorInputProtocol {
    weak var output: ReturnCheckInteractorOutputProtocol?

    private let bookingId: String
    private let store: ReturnPlanStore
    private let bookings: BookingService
    private var task: Task<Void, Never>?

    init(bookingId: String, store: ReturnPlanStore = .shared, bookings: BookingService = Services.bookings) {
        self.bookingId = bookingId
        self.store = store
        self.bookings = bookings
    }

    // MARK: - Input
    func loadBooking() {
        task?.cancel()
        task = Task { [weak self] in
            guard let self else { return }
            guard let detail = trackedBooking() else {
                output?.didFail(message: "This cycle is no longer running.")
                return
            }
            output?.didLoadBooking(ReturnBookingInfo(detail: detail,
                                                     plan: store.plan(for: bookingId),
                                                     notificationPermission: await NotificationService.shared.permission(),
                                                     remindersAllowed: remindersAllowed))
        }
    }

    func checkWithCurrentLocation(mode: TravelMode) {
        task?.cancel()
        task = Task { [weak self] in
            guard let self, let detail = trackedBooking() else { return }

            if LocationService.shared.permission == .denied {
                output?.didNeedManualInput(message: "Location is off, so we can't work out the trip for you. Tell us where you'll be, or how long it takes to get back.")
                return
            }
            // One-off request: the location is used once and not kept
            guard let origin = await LocationService.shared.currentLocation() else {
                if !Task.isCancelled {
                    output?.didNeedManualInput(message: "We couldn't get your location. Tell us where you'll be, or how long it takes to get back.")
                }
                return
            }
            await estimate(from: origin, mode: mode, detail: detail)
        }
    }

    func checkManually(place: String, minutes: Int, mode: TravelMode) {
        task?.cancel()
        task = Task { [weak self] in
            guard let self, let detail = trackedBooking() else { return }

            let trimmed = place.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                await publish(minutes: minutes, mode: mode, isManual: true, detail: detail)
                return
            }
            guard let origin = await LaundromatSearchService.locate(trimmed) else {
                if !Task.isCancelled {
                    output?.didFail(message: "Couldn't find \u{201C}\(trimmed)\u{201D}. Try another place, or just enter the travel time.")
                }
                return
            }
            await estimate(from: origin, mode: mode, detail: detail)
        }
    }

    func setReminder(enabled: Bool) {
        task?.cancel()
        task = Task { [weak self] in
            guard let self, let detail = trackedBooking(), var plan = store.plan(for: bookingId) else { return }

            if enabled, remindersAllowed {
                var permission = await NotificationService.shared.permission()
                if permission == .notDetermined {
                    permission = await NotificationService.shared.requestPermission() ? .granted : .denied
                }
                plan.reminderOn = permission == .granted ? await schedule(plan, detail: detail) : false
            } else {
                NotificationService.shared.cancel(id: ReturnPlanStore.notificationId(for: bookingId))
                plan.reminderOn = false
            }
            store.save(plan)
            await publish(plan)
        }
    }

    // MARK: - Work
    private func estimate(from origin: CLLocation, mode: TravelMode, detail: BookingDetail) async {
        guard let laundromat = detail.laundromat else {
            output?.didFail(message: "We don't know where this laundromat is.")
            return
        }
        let destination = CLLocation(latitude: laundromat.latitude, longitude: laundromat.longitude)
        do {
            let minutes = try await TravelTimeService.minutes(from: origin, to: destination, mode: mode)
            if Task.isCancelled { return }
            await publish(minutes: minutes, mode: mode, isManual: false, detail: detail)
        } catch {
            if Task.isCancelled { return }
            output?.didNeedManualInput(message: "Apple Maps couldn't find a route from there. Enter roughly how long it takes instead.")
        }
    }

    private func publish(minutes: Int, mode: TravelMode, isManual: Bool, detail: BookingDetail) async {
        // A finished cycle has nothing left to remind about, so its plan is shown but not kept
        let isRunning = detail.booking.status == .inProgress
        var plan = ReturnPlan(bookingId: bookingId,
                              cycleEnd: detail.booking.endTime,
                              travelMinutes: minutes,
                              bufferMinutes: ReturnCalculator.bufferMinutes,
                              mode: mode,
                              isManualEstimate: isManual,
                              reminderOn: isRunning && (store.plan(for: bookingId)?.reminderOn ?? false))
        // A new estimate moves the leave time, so any earlier reminder is replaced, never left behind
        if plan.reminderOn {
            plan.reminderOn = await schedule(plan, detail: detail)
        } else {
            NotificationService.shared.cancel(id: ReturnPlanStore.notificationId(for: bookingId))
        }
        if isRunning { store.save(plan) }
        await publish(plan)
    }

    private func publish(_ plan: ReturnPlan) async {
        output?.didUpdate(ReturnUpdate(plan: plan,
                                       notificationPermission: await NotificationService.shared.permission(),
                                       remindersAllowed: remindersAllowed))
    }

    private func schedule(_ plan: ReturnPlan, detail: BookingDetail) async -> Bool {
        guard remindersAllowed, await NotificationService.shared.permission() == .granted else { return false }
        let machine = detail.machine.map { "\($0.type.rawValue.capitalized) \($0.label)" } ?? "your laundry"
        let place = detail.laundromat?.name ?? "the laundromat"
        let time = plan.cycleEnd.formatted(date: .omitted, time: .shortened)
        return await NotificationService.shared.schedule(
            id: ReturnPlanStore.notificationId(for: bookingId),
            title: "Time to head back for your laundry",
            body: "Leave now to be at \(place) when \(machine) finishes at \(time). About \(plan.travelMinutes) min \(plan.mode.phrase).",
            at: plan.leaveAt)
    }

    // MARK: - Helpers
    /// The cycle for this booking: running, or just finished while the sheet was open
    private func trackedBooking() -> BookingDetail? {
        bookings.details.first { $0.booking.id == bookingId && [.inProgress, .completed].contains($0.booking.status) }
    }

    // The same switch as the arrival reminder, in Profile > Notifications
    private var remindersAllowed: Bool {
        NotificationPreferences.shared.isOn(.departureReminders)
    }
}
