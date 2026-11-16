//
//  ReturnCheckPresenter.swift
//  wishywash
//

import Foundation

final class ReturnCheckPresenter: ReturnCheckPresenterProtocol, ReturnCheckInteractorOutputProtocol {
    weak var view: ArrivalCheckViewProtocol?
    var interactor: ReturnCheckInteractorInputProtocol?
    var router: ReturnCheckRouterProtocol?

    /// Tests replace this to control the time
    var now: () -> Date = { Date() }

    private enum LastCheck {
        case location
        case manual(place: String, minutes: Int)
    }

    private var info: ReturnBookingInfo?
    private var plan: ReturnPlan?
    private var notificationPermission: PermissionState = .notDetermined
    private var remindersAllowed = true
    private var mode: TravelMode = .driving
    private var lastCheck: LastCheck?
    private var isLoading = false
    private var manualMessage: String?
    private var manualMinutes = 20
    private var errorMessage: String?

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    // MARK: - View actions
    func viewDidLoad() {
        interactor?.loadBooking()
    }

    func didSelectMode(at index: Int) {
        guard TravelMode.allCases.indices.contains(index) else { return }
        mode = TravelMode.allCases[index]
        // A different way of travelling means a different time, so work it out again
        guard let lastCheck else { render(); return }
        start(lastCheck)
    }

    func didTapCheck() {
        start(.location)
    }

    func didTapCalculateManually(place: String, minutes: Int) {
        manualMinutes = minutes
        start(.manual(place: place, minutes: minutes))
    }

    func didToggleReminder(_ isOn: Bool) {
        errorMessage = nil
        interactor?.setReminder(enabled: isOn)
    }

    func didTapOpenSettings() { router?.openSettings() }
    func didRequestRefresh() { render() }
    func didTapClose() { router?.close() }

    private func start(_ check: LastCheck) {
        lastCheck = check
        isLoading = true
        errorMessage = nil
        render()
        switch check {
        case .location:
            manualMessage = nil
            interactor?.checkWithCurrentLocation(mode: mode)
        case .manual(let place, let minutes):
            interactor?.checkManually(place: place, minutes: minutes, mode: mode)
        }
    }

    // MARK: - ReturnCheckInteractorOutputProtocol
    func didLoadBooking(_ info: ReturnBookingInfo) {
        self.info = info
        plan = info.plan
        notificationPermission = info.notificationPermission
        remindersAllowed = info.remindersAllowed
        if let plan {
            mode = plan.mode
            manualMinutes = plan.travelMinutes
        }
        render()
    }

    func didNeedManualInput(message: String) {
        isLoading = false
        manualMessage = message
        render()
    }

    func didUpdate(_ update: ReturnUpdate) {
        isLoading = false
        manualMessage = nil
        plan = update.plan
        notificationPermission = update.notificationPermission
        remindersAllowed = update.remindersAllowed
        render()
    }

    func didFail(message: String) {
        isLoading = false
        errorMessage = message
        render()
    }

    // MARK: - View model
    private func render() {
        guard let info else {
            // The cycle could not be loaded, so there is nothing to check
            if let errorMessage {
                view?.render(ArrivalCheckViewModel(icon: "washer", machineTitle: "Cycle unavailable", placeText: "",
                                                   arriveByText: "", privacyNote: "", modeTitles: [], modeIndex: 0,
                                                   isLoading: false, manualMessage: nil, manualMinutes: manualMinutes,
                                                   result: nil, errorMessage: errorMessage, checkButtonTitle: "Close"))
            }
            return
        }
        let machine = info.detail.machine
        view?.render(ArrivalCheckViewModel(
            icon: machine?.type.rawValue ?? "washer",
            machineTitle: machine.map { "\($0.type.rawValue.capitalized) \($0.label)" } ?? "Your cycle",
            placeText: info.detail.laundromat?.name ?? "Laundromat",
            arriveByText: "Cycle ends at \(timeFormatter.string(from: info.detail.booking.endTime))",
            privacyNote: "We use your location once to work out the trip back. It isn't saved or tracked.",
            modeTitles: TravelMode.allCases.map(\.title),
            modeIndex: TravelMode.allCases.firstIndex(of: mode) ?? 0,
            isLoading: isLoading,
            manualMessage: manualMessage,
            manualMinutes: manualMinutes,
            result: plan.map(makeResult(from:)),
            errorMessage: errorMessage,
            checkButtonTitle: plan == nil ? "Work out when to head back" : "Recalculate"))
    }

    private func makeResult(from plan: ReturnPlan) -> ArrivalResultViewModel {
        let current = now()
        let verdict = ReturnCalculator.verdict(now: current, cycleEnd: plan.cycleEnd, travelMinutes: plan.travelMinutes)
        let backNow = current.addingTimeInterval(TimeInterval(plan.travelMinutes * 60))
        let backText = timeFormatter.string(from: backNow)
        let buffer = plan.bufferMinutes

        let verdictText: String
        let tone: Theme.Tone
        var extra: String?
        var leaveBy = "Leave by \(timeFormatter.string(from: plan.leaveAt))"
        var countdown: String?
        var showsBuffer = true

        switch verdict {
        case .comfortable:
            verdictText = "You'll be back as it finishes"
            tone = .mint
            let minutesLeft = Int(ceil(plan.leaveAt.timeIntervalSince(current) / 60))
            countdown = minutesLeft <= 1 ? "Leave in about a minute" : "Leave in \(minutesLeft) min"
        case .tight:
            verdictText = "Leave now to be back in time"
            tone = .peach
            leaveBy = "Leave now"
            extra = "You'd be back around \(backText), with less than your \(buffer) min buffer."
        case .afterCycleEnds:
            let late = Int(ceil(backNow.timeIntervalSince(plan.cycleEnd) / 60))
            verdictText = "You'd be about \(late) min after the cycle ends"
            tone = .peach
            leaveBy = "Leave now"
            extra = "You'd be back around \(backText). Your laundry will be waiting."
        case .cycleEnded:
            verdictText = "Your laundry is ready"
            tone = .mint
            leaveBy = "Leave now"
            showsBuffer = false
            extra = "You could be there in about \(plan.travelMinutes) min, around \(backText)."
        }

        let travel = plan.isManualEstimate
            ? "\(plan.travelMinutes) min (your estimate)"
            : "About \(plan.travelMinutes) min \(plan.mode.phrase)"
        let detail = [showsBuffer ? "\(travel) + \(buffer) min buffer" : travel, extra]
            .compactMap { $0 }.joined(separator: "\n")

        return ArrivalResultViewModel(
            verdictText: verdictText,
            verdictTone: tone,
            detailText: detail,
            leaveByText: leaveBy,
            countdownText: countdown,
            estimateNote: plan.isManualEstimate
                ? "Based on the time you entered. Recalculate if your plans change."
                : "Travel time is an estimate from Apple Maps and can change with traffic. Recalculate any time.",
            reminder: makeReminder(plan: plan, verdict: verdict))
    }

    private func makeReminder(plan: ReturnPlan, verdict: ReturnVerdict) -> ReminderViewModel {
        let time = timeFormatter.string(from: plan.leaveAt)
        if !remindersAllowed {
            return ReminderViewModel(isOn: false, isEnabled: false,
                                     statusText: "Departure reminders are off in Profile > Notifications. You'll see a countdown here and on My Laundry instead.",
                                     showsSettingsButton: false)
        }
        if notificationPermission == .denied {
            return ReminderViewModel(isOn: false, isEnabled: false,
                                     statusText: "Notifications are off for this app. You'll see a countdown here and on My Laundry instead.",
                                     showsSettingsButton: true)
        }
        if verdict != .comfortable {
            let reason = verdict == .cycleEnded ? "Your laundry is already ready" : "It's already time to head back"
            return ReminderViewModel(isOn: false, isEnabled: false,
                                     statusText: "\(reason), so there is no reminder to set.",
                                     showsSettingsButton: false)
        }
        return ReminderViewModel(isOn: plan.reminderOn, isEnabled: true,
                                 statusText: plan.reminderOn ? "We'll notify you at \(time)." : "Get a notification at \(time).",
                                 showsSettingsButton: false)
    }
}
