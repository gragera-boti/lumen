import SwiftData
import SwiftUI

struct OnboardingView: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(\.modelContext) private var modelContext
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            VStack {
                // Progress indicator
                if viewModel.currentStep != .welcome {
                    ProgressView(
                        value: Double(viewModel.currentStep.rawValue),
                        total: Double(OnboardingStep.allCases.count - 1)
                    )
                    .tint(.white)
                    .padding(.horizontal, LumenTheme.Spacing.lg)
                    .padding(.top, LumenTheme.Spacing.md)
                }

                ZStack {
                    switch viewModel.currentStep {
                    case .welcome:
                        WelcomeStepView(viewModel: viewModel)
                            .transition(.opacity)
                    case .categories:
                        CategoryStepView(viewModel: viewModel)
                            .transition(.opacity)
                    case .tone:
                        ToneStepView(viewModel: viewModel)
                            .transition(.opacity)
                    case .reminders:
                        RemindersStepView(viewModel: viewModel, onComplete: onComplete)
                            .transition(.opacity)
                    case .done:
                        EmptyView()
                    }
                }
                .animation(.easeInOut, value: viewModel.currentStep)
            }
        }
        .ambientBackground()
        .task {
            viewModel.loadCategories(modelContext: modelContext)
        }
    }

    // MARK: - Welcome

    struct WelcomeStepView: View {
        let viewModel: OnboardingViewModel

        var body: some View {
            ZStack {
                BackgroundVideoView(videoName: "onboarding_background", videoExtension: "mp4")
                    .ignoresSafeArea()

                // Dark gradient overlay to ensure text legibility
                LinearGradient(
                    colors: [.black.opacity(0.1), .black.opacity(0.6), .black.opacity(0.9)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: LumenTheme.Spacing.lg) {
                    Spacer()

                    Image(systemName: "sparkle")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: LumenTheme.Colors.gradients[0],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: LumenTheme.Colors.gradients[0].first?.opacity(0.5) ?? .clear, radius: 12)
                        .symbolEffect(.pulse)

                    Text("onboarding.welcome.headline".localized)
                        .font(.system(size: 48, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("onboarding.welcome.subtitle".localized)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, LumenTheme.Spacing.lg)

                    Spacer()

                    PrimaryButton(title: "onboarding.welcome.continueButton".localized) {
                        viewModel.advance()
                    }
                    .padding(.horizontal, LumenTheme.Spacing.lg)
                    .padding(.bottom, LumenTheme.Spacing.xxl)
                }
            }
        }
    }

    // MARK: - Categories

    struct CategoryStepView: View {
        @Bindable var viewModel: OnboardingViewModel

        private var coreCategories: [Category] {
            viewModel.categories.filter { !$0.isSensitive }
        }

        private var sensitiveCategories: [Category] {
            viewModel.categories.filter { $0.isSensitive }
        }

        var body: some View {
            ScrollView {
                VStack(spacing: LumenTheme.Spacing.lg) {
                    Text("onboarding.categories.title".localized)
                        .font(LumenTheme.Typography.headlineFont)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.top, LumenTheme.Spacing.lg)

                    Text("onboarding.categories.subtitle".localized)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))

                    VStack(spacing: LumenTheme.Spacing.md) {
                        ForEach(coreCategories, id: \.id) { category in
                            CategoryChip(
                                category: category,
                                isSelected: viewModel.selectedCategoryIds.contains(category.id)
                            ) {
                                viewModel.toggleCategory(category.id)
                            }
                        }
                    }
                    .padding(.horizontal, LumenTheme.Spacing.lg)

                    if !sensitiveCategories.isEmpty {
                        Divider()
                            .background(.white.opacity(0.3))
                            .padding(.horizontal, LumenTheme.Spacing.lg)

                        Text("onboarding.categories.sensitive".localized)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))

                        VStack(spacing: LumenTheme.Spacing.md) {
                            ForEach(sensitiveCategories, id: \.id) { category in
                                CategoryChip(
                                    category: category,
                                    isSelected: viewModel.selectedCategoryIds.contains(category.id)
                                ) {
                                    viewModel.toggleCategory(category.id)
                                }
                            }
                        }
                        .padding(.horizontal, LumenTheme.Spacing.lg)
                    }

                    PrimaryButton(
                        title: "onboarding.welcome.continueButton".localized,
                        action: { viewModel.advance() },
                        isDisabled: !viewModel.canContinueFromCategories
                    )
                    .padding(.horizontal, LumenTheme.Spacing.lg)
                    .padding(.bottom, LumenTheme.Spacing.xxl)
                }
            }
        }
    }

    // MARK: - Tone

    struct ToneStepView: View {
        @Bindable var viewModel: OnboardingViewModel

        var body: some View {
            VStack(spacing: LumenTheme.Spacing.lg) {
                Spacer()

                Text("onboarding.tone.title".localized)
                    .font(LumenTheme.Typography.headlineFont)
                    .foregroundStyle(.white)

                VStack(spacing: LumenTheme.Spacing.md) {
                    ForEach(Tone.allCases) { tone in
                        ToneOptionCard(
                            tone: tone,
                            isSelected: viewModel.selectedTone == tone
                        ) {
                            viewModel.selectedTone = tone
                        }
                    }
                }
                .padding(.horizontal, LumenTheme.Spacing.lg)

                Spacer()

                PrimaryButton(title: "onboarding.welcome.continueButton".localized) {
                    viewModel.advance()
                }
                .padding(.horizontal, LumenTheme.Spacing.lg)
                .padding(.bottom, LumenTheme.Spacing.xxl)
            }
        }
    }

    // MARK: - Reminders

    struct RemindersStepView: View {
        @Bindable var viewModel: OnboardingViewModel
        let onComplete: () -> Void

        @Environment(\.modelContext) private var modelContext

        var body: some View {
            VStack(spacing: LumenTheme.Spacing.lg) {
                Spacer()

                Image(systemName: "bell.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: LumenTheme.Colors.gradients[2],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: LumenTheme.Colors.gradients[2].first?.opacity(0.5) ?? .clear, radius: 12)
                    .symbolEffect(.bounce, value: viewModel.remindersPerDay)

                VStack(spacing: LumenTheme.Spacing.xs) {
                    Text("onboarding.reminders.title".localized)
                        .font(LumenTheme.Typography.headlineFont)
                        .foregroundStyle(.white)
                    
                    Text("onboarding.reminders.subtitle".localized)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, LumenTheme.Spacing.md)
                }

                VStack(spacing: LumenTheme.Spacing.md) {
                    Stepper(
                        value: $viewModel.remindersPerDay,
                        in: 0...12
                    ) {
                        Text("onboarding.reminders.perDay".localized(with: viewModel.remindersPerDay))
                            .font(.title3)
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: LumenTheme.Radii.md))
                }
                .padding(.horizontal, LumenTheme.Spacing.lg)

                Spacer()

                VStack(spacing: LumenTheme.Spacing.md) {
                    PrimaryButton(title: "onboarding.reminders.enable".localized) {
                        Task {
                            await viewModel.requestNotificationPermission()
                            viewModel.completeOnboarding(modelContext: modelContext)
                            onComplete()
                        }
                    }

                    SecondaryButton(title: "onboarding.reminders.notNow".localized) {
                        viewModel.remindersPerDay = 0
                        viewModel.completeOnboarding(modelContext: modelContext)
                        onComplete()
                    }
                }
                .padding(.horizontal, LumenTheme.Spacing.lg)
                .padding(.bottom, LumenTheme.Spacing.xxl)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
        .modelContainer(for: [UserPreferences.self, Category.self], inMemory: true)
}
