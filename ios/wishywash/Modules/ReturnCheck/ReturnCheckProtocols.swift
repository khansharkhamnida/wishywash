//
//  ReturnCheckProtocols.swift
//  wishywash
//
//  The way-back check shows the same sheet as ArrivalCheck, so the view, its actions and the
//  presenter-to-interactor and router calls are the ones ArrivalCheck already defines.
//

import Foundation

typealias ReturnCheckPresenterProtocol = ArrivalCheckPresenterProtocol
typealias ReturnCheckInteractorInputProtocol = ArrivalCheckInteractorInputProtocol
typealias ReturnCheckRouterProtocol = ArrivalCheckRouterProtocol

struct ReturnBookingInfo {
    let detail: BookingDetail
    let plan: ReturnPlan?
    let notificationPermission: PermissionState
    let remindersAllowed: Bool
}

struct ReturnUpdate {
    let plan: ReturnPlan
    let notificationPermission: PermissionState
    let remindersAllowed: Bool
}

// Interactor -> Presenter
protocol ReturnCheckInteractorOutputProtocol: AnyObject {
    func didLoadBooking(_ info: ReturnBookingInfo)
    func didNeedManualInput(message: String)
    func didUpdate(_ update: ReturnUpdate)
    func didFail(message: String)
}
