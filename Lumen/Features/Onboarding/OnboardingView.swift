import SwiftUI
import SwiftData

struct OnboardingView: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(\.modelContext) private var modelContext
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            AnimatedGradientBackground(colors: [
                LumenTheme.Colors.gentleAccent,
                LumenTheme.Colors.softPurple,
            ])

            VStack {
                // Progress indicator
                if viewModel.currentStep != .welcome {
                    ProgressView(value: Double(viewModel.currentStep.rawValue), total: Double(OnboardingStep.allCases.count - 1))
                        .tint(.white)
                        .padding(.horizontal, LumenTheme.Spacing.lg)
                        .padding(.top, LumenTheme.Spacing.md)
                }

                TabView(selection: Binding(
                    get: { viewModel.currentStep },
                    set: { _ in }
                )) {
                    WelcomeStepView(viewModel: viewModel)
                        .tag(OnboardingStep.welcome)

                    CategoryStepView(viewModel: viewModel)
                        .tag(OnboardingStep.categories)

                    ToneStepView(viewModel: viewModel)
                        .tag(OnboardingStep.tone)

                    RemindersStepView(viewModel: viewModel, onComplete: onComplete)
                        .tag(OnboardingStep.reminders)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentStep)
            }
        }
        .task {
            viewModel.loadCategories(modelContext: modelContext)
        }
    }

    // MARK: - Welcome

    struct WelcomeStepView: View {
        let viewModel: OnboardingViewModel

        var body: some View {
            VStack(spacing: LumenTheme.Spacing.lg) {
                Spacer()

                Image(systemName: "sparkle")
                    .font(.system(size: 60))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse)

                Text("Lumen")
                    .font(.system(.largeTitle, design: .serif, weight: .bold))
                    .foregroundStyle(.white)

                Text("Daily affirmations that feel kind —\nnot forced.")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)

                Spacer()

                VStack(spacing: LumenTheme.Spacing.sm) {
                    Text("This app is for wellness, not medical care.\nIf you feel unsafe or in crisis, tap below.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)

                    Button("Get help now") {
                        // Show crisis sheet
                    }
                    .font(.footnote.bold())
                    .foregroundStyle(.white)
                }

                PrimaryButton(title: "Continue") {
                    viewModel.advance()
                }
                .padding(.horizontal, LumenTheme.Spacing.lg)
                .padding(.bottom, LumenTheme.Spacing.xxl)
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
                    Text("Choose what you want\nmore of")
                        .font(LumenTheme.Typography.headlineFont)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.top, LumenTheme.Spacing.lg)

                    Text("Pick at least one")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: LumenTheme.Spacing.md) {
                        ForEach(coreCategories, id: \.id) { category in
                            CategoryChip(
                                category: category,
                                isSelected: viewModel.selectedCategoryIds.contains(category.id)
                            ) {
                                viewModel.toggleCategory(category.id)
                            }
                        }
                    }
                    .padding(.horizontal, LumenTheme.Spacing.md)

                    if !sensitiveCategories.isEmpty {
                        Divider()
                            .background(.white.opacity(0.3))
                            .padding(.horizontal, LumenTheme.Spacing.lg)

                        Text("Sensitive topics (opt-in)")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                        ], spacing: LumenTheme.Spacing.md) {
                            ForEach(sensitiveCategories, id: \.id) { category in
                                CategoryChip(
                                    category: category,
                                    isSelected: viewModel.selectedCategoryIds.contains(category.id)
                                ) {
                                    viewModel.toggleCategory(category.id)
                                }
                            }
                        }
                        .padding(.horizontal, LumenTheme.Spacing.md)
                    }

                    PrimaryButton(title: "Continue", action: { viewModel.advance() },
                                  isDisabled: !viewModel.canContinueFromCategories)
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

                Text("Choose your tone")
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

                PrimaryButton(title: "Continue") {
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
                    .font(.system(size: 48))
                    .foregroundStyle(.white)

                Text("Set your reminders")
                    .font(LumenTheme.Typography.headlineFont)
                    .foregroundStyle(.white)

                VStack(spacing: LumenTheme.Spacing.md) {
                    Stepper(
                        "Reminders per day: \(viewModel.remindersPerDay)",
                        value: $viewModel.remindersPerDay,
                        in: 0...12
                    )
                    .foregroundStyle(.white)
                    .padding()
                    .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: LumenTheme.Radii.md))
                }
                .padding(.horizontal, LumenTheme.Spacing.lg)

                Spacer()

                VStack(spacing: LumenTheme.Spacing.md) {
                    PrimaryButton(title: "Enable reminders") {
                        Task {
                            await viewModel.requestNotificationPermission()
                            viewModel.completeOnboarding(modelContext: modelContext)
                            onComplete()
                        }
                    }

                    SecondaryButton(title: "Not now") {
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
