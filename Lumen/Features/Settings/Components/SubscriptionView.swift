import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @State private var isPremium = false

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Current plan")
                    Spacer()
                    Text(isPremium ? "Premium" : "Free")
                        .foregroundStyle(isPremium ? .orange : .secondary)
                }
            }

            Section {
                Button("Manage Subscription") {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                }

                Button("Restore Purchases") {
                    Task {
                        try? await EntitlementService.shared.restorePurchases()
                        isPremium = await EntitlementService.shared.isPremium()
                    }
                }
            }

            Section {
                Link("Contact Support", destination: URL(string: "mailto:support@example.com")!)
            }
        }
        .navigationTitle("Subscription")
        .task {
            isPremium = await EntitlementService.shared.isPremium()
        }
    }
}
