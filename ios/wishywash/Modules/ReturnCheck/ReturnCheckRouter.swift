//
//  ReturnCheckRouter.swift
//  wishywash
//

import UIKit

final class ReturnCheckRouter: ReturnCheckRouterProtocol {
    weak var viewController: UIViewController?

    static func createModule(bookingId: String) -> UIViewController {
        let view = ArrivalCheckViewController()
        let presenter = ReturnCheckPresenter()
        let interactor = ReturnCheckInteractor(bookingId: bookingId)
        let router = ReturnCheckRouter()

        view.wording = ArrivalCheckViewController.Wording(title: "Plan your way back",
                                                          timeRowSubtitle: "When your laundry is done",
                                                          reminderTitle: "Remind me to head back")
        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        interactor.output = presenter
        router.viewController = view

        return view
    }

    /// Shows the check as a sheet on top of `presenter`
    static func present(bookingId: String, from presenter: UIViewController?) {
        let check = createModule(bookingId: bookingId)
        if let sheet = check.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        presenter?.present(check, animated: true)
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
