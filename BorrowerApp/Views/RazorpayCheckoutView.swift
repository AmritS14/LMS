import SwiftUI
import UIKit
import Razorpay

// Helper that presents the Razorpay checkout directly from the app's topmost
// view controller, avoiding double-modal issues with SwiftUI's fullScreenCover.
//
// Usage from SwiftUI:
//     RazorpayCheckoutManager.shared.startPayment(order: order,
//         onSuccess: { pid, oid, sig in … },
//         onError: { desc in … })
final class RazorpayCheckoutManager: NSObject, RazorpayPaymentCompletionProtocolWithData {
    nonisolated(unsafe) static let shared = RazorpayCheckoutManager()

    private var razorpay: RazorpayCheckout?
    private var onSuccess: (@MainActor (String, String, String) -> Void)?
    private var onError: (@MainActor (String) -> Void)?
    private var currentOrder: EMIOrder?

    private override init() { super.init() }

    func startPayment(
        order: EMIOrder,
        onSuccess: @escaping @MainActor (String, String, String) -> Void,
        onError: @escaping @MainActor (String) -> Void
    ) {
        self.currentOrder = order
        self.onSuccess = onSuccess
        self.onError = onError

        razorpay = RazorpayCheckout.initWithKey(order.keyId, andDelegateWithData: self)

        let options: [AnyHashable: Any] = [
            "amount": order.amount,
            "currency": order.currency,
            "order_id": order.orderId,
            "name": "LMS — Loan Repayment",
            "description": "EMI Payment",
            "theme": ["color": "#2563EB"]
        ]

        guard let topVC = Self.topViewController() else {
            let cb = onError
            Task { @MainActor in cb("Unable to present payment screen") }
            return
        }
        razorpay?.open(options, displayController: topVC)
    }

    // MARK: - RazorpayPaymentCompletionProtocolWithData

    func onPaymentSuccess(_ payment_id: String, andData response: [AnyHashable: Any]?) {
        let orderId = response?["razorpay_order_id"] as? String ?? currentOrder?.orderId ?? ""
        let signature = response?["razorpay_signature"] as? String ?? ""
        let cb = onSuccess
        Task { @MainActor in cb?(payment_id, orderId, signature) }
        cleanup()
    }

    func onPaymentError(_ code: Int32, description str: String, andData response: [AnyHashable: Any]?) {
        let cb = onError
        Task { @MainActor in cb?(str) }
        cleanup()
    }

    // MARK: - Helpers

    private func cleanup() {
        razorpay = nil
        onSuccess = nil
        onError = nil
        currentOrder = nil
    }

    private static func topViewController(
        from root: UIViewController? = nil
    ) -> UIViewController? {
        let root = root ?? UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
            .first
        if let nav = root as? UINavigationController {
            return topViewController(from: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController {
            return topViewController(from: tab.selectedViewController)
        }
        if let presented = root?.presentedViewController {
            return topViewController(from: presented)
        }
        return root
    }
}
