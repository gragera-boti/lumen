import SwiftUI
import RevenueCatUI

struct LumenPaywallView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        RevenueCatUI.PaywallView()
            .onPurchaseCompleted { _ in
                dismiss()
            }
            .onRestoreCompleted { _ in
                dismiss()
            }
    }
}
