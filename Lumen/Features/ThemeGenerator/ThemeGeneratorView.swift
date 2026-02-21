import SwiftUI
import SwiftData

struct ThemeGeneratorView: View {
    @State private var viewModel = ThemeGeneratorViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router

    var body: some View {
        ScrollView {
            VStack(spacing: LumenTheme.Spacing.lg) {
                // Mode picker
                modePicker

                // Preview
                previewSection

                // Mode-specific controls
                switch viewModel.selectedMode {
                case .procedural:
                    proceduralControls
                case .ai:
                    aiControls
                }

                // Actions
                actionSection
            }
            .padding(.horizontal, LumenTheme.Spacing.md)
            .padding(.top, LumenTheme.Spacing.sm)
            .padding(.bottom, 100)
        }
        .navigationTitle("generator.title".localized)
        .alert("general.error".localized, isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("general.ok".localized) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onChange(of: viewModel.showPaywallPrompt) { _, show in
            if show {
                router.isShowingPaywall = true
                viewModel.showPaywallPrompt = false
            }
        }
        .task { await viewModel.onAppear() }
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        Picker("Mode", selection: $viewModel.selectedMode) {
            ForEach(ThemeGeneratorViewModel.GeneratorMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Preview

    private var previewSection: some View {
        ZStack {
            if let image = viewModel.generatedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: previewColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            ReadabilityOverlay(opacity: 0.2)

            Text("I can take one small step today.")
                .font(.system(.title3, design: .serif, weight: .medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, LumenTheme.Spacing.xl)
                .shadow(color: .black.opacity(0.3), radius: 6, y: 2)

            if viewModel.selectedMode == .procedural && viewModel.isGenerating {
                Color.black.opacity(0.4)

                VStack(spacing: LumenTheme.Spacing.md) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                    Text("generator.generating".localized)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, LumenTheme.Spacing.lg)
            }
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: LumenTheme.Radii.card))
        .clipped()
    }

    // MARK: - Procedural Controls

    private var proceduralControls: some View {
        VStack(spacing: LumenTheme.Spacing.lg) {
            // Style
            VStack(alignment: .leading, spacing: LumenTheme.Spacing.sm) {
                Text("generator.style".localized)
                    .font(.headline)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: LumenTheme.Spacing.sm) {
                        ForEach(GeneratorStyle.allCases) { style in
                            ChipButton(
                                title: style.displayName,
                                isSelected: viewModel.selectedStyle == style
                            ) {
                                viewModel.selectedStyle = style
                            }
                        }
                    }
                }
            }

            // Color palette
            VStack(alignment: .leading, spacing: LumenTheme.Spacing.sm) {
                Text("generator.color".localized)
                    .font(.headline)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: LumenTheme.Spacing.md) {
                    ForEach(ColorPalette.allCases) { palette in
                        PaletteChip(
                            palette: palette,
                            isSelected: viewModel.selectedPalette == palette
                        ) {
                            viewModel.selectedPalette = palette
                        }
                    }
                }
            }

            // Mood
            VStack(alignment: .leading, spacing: LumenTheme.Spacing.sm) {
                Text("generator.mood".localized)
                    .font(.headline)

                Picker("generator.mood".localized, selection: $viewModel.selectedMood) {
                    ForEach(GeneratorMood.allCases) { mood in
                        Text(mood.displayName).tag(mood)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Complexity
            VStack(alignment: .leading, spacing: LumenTheme.Spacing.sm) {
                Text("generator.detail".localized)
                    .font(.headline)

                Slider(value: $viewModel.complexity, in: 0...1)
                HStack {
                    Text("Simple").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text("Rich").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - AI Controls

    private var aiControls: some View {
        VStack(spacing: LumenTheme.Spacing.lg) {
            // Model status banner
            aiModelBanner

            // Category picker
            VStack(alignment: .leading, spacing: LumenTheme.Spacing.sm) {
                Text("Style")
                    .font(.headline)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: LumenTheme.Spacing.sm) {
                        ForEach(AIBackgroundPrompt.PromptCategory.allCases) { category in
                            ChipButton(
                                title: "\(category.emoji) \(category.displayName)",
                                isSelected: viewModel.selectedPromptCategory == category
                            ) {
                                viewModel.selectedPromptCategory = category
                                viewModel.selectedPrompt = nil
                            }
                        }
                    }
                }
            }

            // Prompt picker within category
            VStack(alignment: .leading, spacing: LumenTheme.Spacing.sm) {
                HStack {
                    Text("Prompt")
                        .font(.headline)
                    Spacer()
                    Button("Random") {
                        viewModel.selectedPrompt = .random(category: viewModel.selectedPromptCategory)
                    }
                    .font(.subheadline)
                }

                let prompts = AIBackgroundPrompt.library.filter {
                    $0.category == viewModel.selectedPromptCategory
                }

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: LumenTheme.Spacing.sm) {
                    ForEach(prompts) { prompt in
                        PromptCard(
                            prompt: prompt,
                            isSelected: viewModel.selectedPrompt?.id == prompt.id
                        ) {
                            viewModel.selectedPrompt = prompt
                        }
                    }
                }
            }

            // Cached AI backgrounds
            if !viewModel.cachedAIBackgrounds.isEmpty {
                cachedSection
            }
        }
    }

    // MARK: - AI Model Banner

    private var aiModelBanner: some View {
        VStack(spacing: LumenTheme.Spacing.sm) {
            HStack(spacing: LumenTheme.Spacing.sm) {
                Image(systemName: aiModelIcon)
                    .foregroundStyle(aiModelIconColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Model")
                        .font(.subheadline.weight(.semibold))
                    Text(viewModel.aiLoadState.statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                aiModelAction
            }

            // Progress bar
            if let progress = viewModel.aiLoadState.progress, progress > 0 {
                ProgressView(value: progress)
                    .tint(LumenTheme.Colors.primary)
            } else if viewModel.aiLoadState.isWorking {
                // Indeterminate progress for model loading / early generation
                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(LumenTheme.Colors.primary)
            }
        }
        .padding(LumenTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: LumenTheme.Radii.card)
                .fill(Color(.systemGray6))
        )
    }

    private var aiModelIcon: String {
        switch viewModel.aiLoadState {
        case .ready: "checkmark.circle.fill"
        case .failed: "exclamationmark.triangle.fill"
        default: "cpu"
        }
    }

    private var aiModelIconColor: Color {
        switch viewModel.aiLoadState {
        case .ready: .green
        case .failed: .red
        default: .orange
        }
    }

    @ViewBuilder
    private var aiModelAction: some View {
        switch viewModel.aiLoadState {
        case .idle, .failed:
            Button("Load") {
                Task { await viewModel.loadAIModel() }
            }
            .font(.subheadline.weight(.medium))
            .buttonStyle(.bordered)
        case .ready:
            Image(systemName: "checkmark")
                .foregroundStyle(.green)
                .font(.subheadline.weight(.semibold))
        default:
            EmptyView() // progress bar handles visual feedback
        }
    }

    // MARK: - Cached AI Backgrounds

    private var cachedSection: some View {
        VStack(alignment: .leading, spacing: LumenTheme.Spacing.sm) {
            Text("Your AI Backgrounds")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LumenTheme.Spacing.sm) {
                    ForEach(viewModel.cachedAIBackgrounds, id: \.themeId) { bg in
                        CachedThumbnail(background: bg) {
                            viewModel.loadCachedBackground(bg)
                        } onDelete: {
                            Task { await viewModel.deleteCachedBackground(bg) }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private var actionSection: some View {
        VStack(spacing: LumenTheme.Spacing.md) {
            PrimaryButton(
                title: generateButtonTitle,
                action: { Task { await viewModel.generate() } },
                isDisabled: viewModel.isGenerating || viewModel.aiLoadState.isWorking
            )

            if viewModel.selectedMode == .ai && !viewModel.isGenerating && viewModel.isModelReady {
                SecondaryButton(title: "Pre-generate 6 Backgrounds") {
                    Task { await viewModel.pregenerateAIBatch() }
                }
            }

            if viewModel.generatedImage != nil && viewModel.savedThemeId != nil {
                if viewModel.isSaved {
                    HStack(spacing: LumenTheme.Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Added to rotation!")
                            .font(.subheadline.weight(.medium))
                    }
                } else {
                    SecondaryButton(title: "Save") {
                        viewModel.saveAsTheme(modelContext: modelContext)
                    }
                }
            }

            Text(viewModel.selectedMode == .ai
                 ? "AI backgrounds are generated on-device. Saved backgrounds rotate randomly in your feed."
                 : "Unlimited free backgrounds. Saved themes rotate randomly in your feed.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var generateButtonTitle: String {
        if viewModel.isGenerating {
            return viewModel.selectedMode == .ai ? "Creating…" : "generator.generating".localized
        }
        return viewModel.selectedMode == .ai ? "Generate with AI ✨" : "generator.generate".localized
    }

    // MARK: - Helpers

    private var previewColors: [Color] {
        if viewModel.selectedMode == .ai {
            return [
                Color(red: 0.15, green: 0.12, blue: 0.30),
                Color(red: 0.25, green: 0.15, blue: 0.45),
                Color(red: 0.35, green: 0.20, blue: 0.50),
            ]
        }
        return viewModel.selectedPalette.cgColors.map { Color(cgColor: $0) }
    }
}

// MARK: - Chip Button

private struct ChipButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, LumenTheme.Spacing.md)
                .padding(.vertical, LumenTheme.Spacing.sm)
                .background(
                    Capsule()
                        .fill(isSelected ? LumenTheme.Colors.primary : Color(.systemGray6))
                )
        }
    }
}

// MARK: - Palette Chip

private struct PaletteChip: View {
    let palette: ColorPalette
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { i in
                        Rectangle()
                            .fill(Color(cgColor: palette.cgColors[i]))
                    }
                }
                .frame(height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(isSelected ? LumenTheme.Colors.primary : .clear, lineWidth: 2)
                )

                Text(palette.displayName)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? LumenTheme.Colors.primary : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }
}

// MARK: - Prompt Card

private struct PromptCard: View {
    let prompt: AIBackgroundPrompt
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(prompt.displayName)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, LumenTheme.Spacing.sm)
                .padding(.horizontal, LumenTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: LumenTheme.Radii.sm)
                        .fill(isSelected ? LumenTheme.Colors.primary : Color(.systemGray6))
                )
        }
    }
}

// MARK: - Cached Thumbnail

private struct CachedThumbnail: View {
    let background: GeneratedBackground
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                if let data = try? Data(contentsOf: background.thumbnailPath),
                   let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color(.systemGray5)
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
