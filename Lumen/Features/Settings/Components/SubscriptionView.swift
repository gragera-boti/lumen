import SwiftUI
import RevenueCatUI

struct SubscriptionView: View {
    @Environment(AppRouter.self) private var router
    @State private var isPremium = false
    @State private var showPaywall = false

    var body: some View {
        List {
            if !isPremium {
                Section {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("subscription.upgrade.title".localized)
                                    .font(.headline)
                                Text("subscription.upgrade.subtitle".localized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .accessibilityLabel("Upgrade to Premium")
                    .accessibilityIdentifier("subscription_upgrade_button")
                }
            }

            Section {
                HStack {
                    Text("subscription.current_plan".localized)
                    Spacer()
                    Text(isPremium ? "subscription.plan.premium".localized : "subscription.plan.free".localized)
                        .foregroundStyle(isPremium ? .orange : .secondary)
                }
            }

            Section {
                if isPremium {
                    Button("subscription.manage".localized) {
                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                            UIApplication.shared.open(url)
                        }
                    }
                }

                Button("subscription.restore".localized) {
                    Task {
                        try? await EntitlementService.shared.restorePurchases()
                        isPremium = await EntitlementService.shared.isPremium()
                    }
                }
            }

            Section {
                Link("subscription.contact_support".localized, destination: URL(string: "mailto:alberto.gragera@gmail.com")!)
            }
        }
        .ambientBackground()
        .navigationTitle("settings.subscription".localized)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .onDisappear {
                    Task {
                        isPremium = await EntitlementService.shared.isPremium()
                    }
                }
        }
        .task {
            isPremium = await EntitlementService.shared.isPremium()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SubscriptionView()
    }
    .environment(AppRouter())
}
