import SwiftUI

struct PaywallView: View {
    @State private var viewModel = PaywallViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground(colors: [
                    LumenTheme.Colors.warmAccent,
                    LumenTheme.Colors.softPurple,
                ])

                ScrollView {
                    VStack(spacing: LumenTheme.Spacing.lg) {
                        Spacer(minLength: LumenTheme.Spacing.xxl)

                        // Header
                        VStack(spacing: LumenTheme.Spacing.md) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.yellow)

                            Text("Unlock Lumen Premium")
                                .font(LumenTheme.Typography.headlineFont)
                                .foregroundStyle(.white)

                            VStack(alignment: .leading, spacing: 8) {
                                featureRow("All categories and content")
                                featureRow("Unlimited background generation")
                                featureRow("Remove watermarks")
                                featureRow("Premium themes")
                            }
                            .padding(.horizontal, LumenTheme.Spacing.lg)
                        }

                        // Products
                        VStack(spacing: LumenTheme.Spacing.md) {
                            ForEach(viewModel.products) { product in
                                ProductCard(product: product) {
                                    Task { await viewModel.purchase(product) }
                                }
                            }
                        }
                        .padding(.horizontal, LumenTheme.Spacing.lg)

                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        }

                        // Restore
                        Button("Restore Purchases") {
                            Task { await viewModel.restore() }
                        }
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))

                        // Legal
                        VStack(spacing: 4) {
                            Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless it is cancelled at least 24 hours before the end of the current period.")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.5))
                                .multilineTextAlignment(.center)

                            HStack(spacing: LumenTheme.Spacing.md) {
                                Link("Terms", destination: URL(string: "https://example.com/terms")!)
                                Link("Privacy", destination: URL(string: "https://example.com/privacy")!)
                            }
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                        }
                        .padding(.horizontal, LumenTheme.Spacing.lg)
                        .padding(.bottom, LumenTheme.Spacing.xxl)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .task { await viewModel.loadProducts() }
        .onChange(of: viewModel.purchaseSuccess) { _, success in
            if success { dismiss() }
        }
    }

    private func featureRow(_ text: String) -> some View {
        HStack(spacing: LumenTheme.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Product Card

private struct ProductCard: View {
    let product: ProductInfo
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)

                    if let trial = product.trialDuration {
                        Text("Free trial: \(trial)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .padding(LumenTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: LumenTheme.Radii.md)
                    .fill(.white.opacity(0.2))
                    .strokeBorder(.white.opacity(0.4), lineWidth: 1)
            )
        }
    }
}
