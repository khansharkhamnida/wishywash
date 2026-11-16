//
//  ReturnPlanStore.swift
//  wishywash
//

import Foundation

/// The "head back" plan for each running cycle, kept on the device.
/// It is saved apart from the arrival plans, and its notification ids differ, so the two never touch.
/// Removing a plan also cancels its notification.
final class ReturnPlanStore {
    static let shared = ReturnPlanStore()

    private let store: LocalStore

    init(store: LocalStore = .shared) {
        self.store = store
    }

    var plans: [String: ReturnPlan] {
        store.load([String: ReturnPlan].self, key: StoreKey.returnPlans) ?? [:]
    }

    func plan(for bookingId: String) -> ReturnPlan? {
        plans[bookingId]
    }

    func save(_ plan: ReturnPlan) {
        var current = plans
        current[plan.bookingId] = plan
        store.save(current, key: StoreKey.returnPlans)
    }

    func remove(bookingId: String) {
        var current = plans
        guard current.removeValue(forKey: bookingId) != nil else { return }
        store.save(current, key: StoreKey.returnPlans)
        NotificationService.shared.cancel(id: Self.notificationId(for: bookingId))
    }

    /// Removes every plan, and its reminder, whose booking is not in `bookingIds`
    func prune(keeping bookingIds: Set<String>) {
        for id in plans.keys where !bookingIds.contains(id) {
            remove(bookingId: id)
        }
    }

    static func notificationId(for bookingId: String) -> String {
        "return-\(bookingId)"
    }
}
