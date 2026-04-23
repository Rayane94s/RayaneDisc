import SwiftUI
import LinkKit   // Plaid Link iOS SDK

/// Thin SwiftUI wrapper around Plaid's UIKit-based PLKPlaidLinkViewController.
struct PlaidLinkView: UIViewControllerRepresentable {
    let linkToken: String
    let onSuccess: (String) -> Void   // delivers the public_token
    let onExit: (Error?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onSuccess: onSuccess, onExit: onExit) }

    func makeUIViewController(context: Context) -> UIViewController {
        var config = LinkTokenConfiguration(token: linkToken) { success in
            context.coordinator.onSuccess(success.publicToken)
        }
        config.onExit = { exit in
            context.coordinator.onExit(exit.error)
        }

        let result = Plaid.create(config)
        switch result {
        case .success(let handler):
            context.coordinator.handler = handler
            let vc = UIViewController()
            DispatchQueue.main.async {
                handler.open(presentUsing: .viewController(vc))
            }
            return vc
        case .failure(let error):
            context.coordinator.onExit(error)
            return UIViewController()
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    class Coordinator: NSObject {
        var handler: Handler?
        let onSuccess: (String) -> Void
        let onExit: (Error?) -> Void

        init(onSuccess: @escaping (String) -> Void, onExit: @escaping (Error?) -> Void) {
            self.onSuccess = onSuccess
            self.onExit = onExit
        }
    }
}
