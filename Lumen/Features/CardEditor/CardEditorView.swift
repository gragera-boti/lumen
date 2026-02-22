import SwiftUI
import SwiftData

// MARK: - CardEditorView

/// Sheet for customizing an affirmation card's background, typography, and text.
struct CardEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: CardEditorViewModel

    init(affirmation: Affirmation, existingCustomization: CardCustomization?) {
        _viewModel = State(
            initialValue: CardEditorViewModel(
                affirmation: affirmation,
                existingCustomization: existingCustomization
            )
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: LumenTheme.Spacing.lg) {
                    previewCard
                    backgroundModeSelector
                    backgroundSection
                    typographySection

                    if viewModel.canEditText {
                        textSection
                    }

                    actionBar
                }
                .padding(.horizontal, LumenTheme.Spacing.md)
                .padding(.top, LumenTheme.Spacing.sm)
                .padding(.bottom, 40)
            }
            .ambientBackground()
            .navigationTitle("Customize Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                await viewModel.checkAIModelStatus()
                await viewModel.generatePreview()
            }
            .onChange(of: viewModel.selectedStyle) { _, _ in
                Task { await viewModel.generatePreview() }
            }
            .onChange(of: viewModel.selectedPalette) { _, _ in
                Task { await viewModel.generatePreview() }
            }
            .onChange(of: viewModel.backgroundSeed) { _, _ in
                Task { await viewModel.generatePreview() }
            }
        }
    }

    // MARK: - Preview Card

    private var previewCard: some View {
        ZStack {
            if let image = viewModel.previewImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                LinearGradient(
                    colors: viewModel.selectedPalette.cgColors.map { Color(cgColor: $0) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            ReadabilityOverlay(opacity: 0.2)

            if viewModel.isGeneratingPreview {
                ProgressView()
                    .tint(.white)
            }

            Text(viewModel.customText)
                .font(previewFont)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, LumenTheme.Spacing.xl)
                .shadow(color: .black.opacity(0.4), radius: 8, y: 3)
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: LumenTheme.Radii.card))
        .accessibilityLabel("Card preview")
    }

    private var previewFont: Font {
        if let style = viewModel.selectedFontStyle {
            return style.cardFont(textLength: viewModel.customText.count)
        }
        return Font.custom("PlayfairDisplayRoman-Bold", size: 34)
    }

    // MARK: - Background Mode Selector

    private var backgroundModeSelector: some View {
        Picker("Mode", selection: $viewModel.backgroundMode) {
            ForEach(CardEditorViewModel.BackgroundMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Background generation mode")
    }

    // MARK: - Background Section

    @ViewBuilder
    private var backgroundSection: some View {
        switch viewModel.backgroundMode {
        case .procedural:
            proceduralBackgroundSection
        case .ai:
            aiBackgroundSection
        }
    }

    // MARK: - Procedural Controls

    private var proceduralBackgroundSection: some View {
        VStack(spacing: LumenTheme.Spacing.lg) {
            // Style
            VStack(alignment: .leading, spacing: LumenTheme.Spacing.sm) {
                sectionHeader("Style", icon: "paintpalette")

                StylePickerView(
                    selection: $viewModel.selectedStyle,
                    palette: viewModel.selectedPalette
                )
            }

            // Color palette
            VStack(alignment: .leading, spacing: LumenTheme.Spacing.sm) {
                sectionHeader("Color", icon: "swatchpalette")

                PalettePickerView(selection: $viewModel.selectedPalette)
            }

            shuffleButton
        }
    }

    // MARK: - AI Controls (matching ThemeGeneratorView)

    private var aiBackgroundSection: some View {
        VStack(spacing: LumenTheme.Spacing.lg) {
            // Model status banner
            aiModelBanner

            if viewModel.isModelReady {
                // Category picker
                VStack(alignment: .leading, spacing: LumenTheme.Spacing.sm) {
                    sectionHeader("Style", icon: "sparkles")

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: LumenTheme.Spacing.sm) {
                            ForEach(AIBackgroundPrompt.PromptCategory.allCases) { category in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewModel.selectedPromptCategory = category
                                        viewModel.selectedPrompt = nil
                                    }
                                } label: {
                                    Text("\(category.emoji) \(category.displayName)")
                                        .font(.subheadline.weight(
                                            viewModel.selectedPromptCategory == category ? .semibold : .regular
                                        ))
                                        .foregroundStyle(
                                            viewModel.selectedPromptCategory == category ? .white : .white.opacity(0.7)
                                        )
                                        .padding(.horizontal, LumenTheme.Spacing.md)
                                        .padding(.vertical, LumenTheme.Spacing.sm)
                                        .background(
                                            Capsule().fill(
                                                viewModel.selectedPromptCategory == category
                                                    ? LumenTheme.Colors.primary
                                                    : LumenTheme.Colors.glassBackground
                                            )
                                        )
                                }
                                .accessibilityLabel("\(category.displayName) AI backgrounds")
                                .accessibilityAddTraits(
                                    viewModel.selectedPromptCategory == category ? .isSelected : []
                                )
                            }
                        }
                    }
                }

                // Prompt picker within category
                VStack(alignment: .leading, spacing: LumenTheme.Spacing.sm) {
                    HStack {
                        sectionHeader("Prompt", icon: "text.quote")
                        Spacer()
                        Button("Random") {
                            viewModel.selectedPrompt = .random(category: viewModel.selectedPromptCategory)
                            Task { await viewModel.generatePreview() }
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
                            Button {
                                viewModel.selectedPrompt = prompt
                                Task { await viewModel.generatePreview() }
                            } label: {
                                Text(prompt.displayName)
                                    .font(.subheadline.weight(
                                        viewModel.selectedPrompt?.id == prompt.id ? .semibold : .regular
                                    ))
                                    .foregroundStyle(
                                        viewModel.selectedPrompt?.id == prompt.id ? .white : .white.opacity(0.7)
                                    )
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, LumenTheme.Spacing.sm)
                                    .padding(.horizontal, LumenTheme.Spacing.sm)
                                    .background(
                                        RoundedRectangle(cornerRadius: LumenTheme.Radii.sm)
                                            .fill(
                                                viewModel.selectedPrompt?.id == prompt.id
                                                    ? LumenTheme.Colors.primary
                                                    : LumenTheme.Colors.glassBackground
                                            )
                                    )
                            }
                        }
                    }
                }

                // Generate button
                Button {
                    Task { await viewModel.generatePreview() }
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text(viewModel.isGeneratingPreview ? "Creating…" : "Generate with AI ✨")
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: LumenTheme.Radii.md)
                            .fill(LumenTheme.Colors.primary)
                    )
                }
                .disabled(viewModel.isGeneratingPreview)
                .accessibilityLabel("Generate AI background")

                shuffleButton
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

            if let progress = viewModel.aiLoadState.progress, progress > 0 {
                ProgressView(value: progress)
                    .tint(LumenTheme.Colors.primary)
            } else if viewModel.aiLoadState.isWorking {
                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(LumenTheme.Colors.primary)
            }
        }
        .padding(LumenTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: LumenTheme.Radii.card)
                .fill(LumenTheme.Colors.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: LumenTheme.Radii.card)
                        .strokeBorder(LumenTheme.Colors.glassBorder, lineWidth: 0.5)
                )
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
            EmptyView()
        }
    }

    // MARK: - Shuffle

    private var shuffleButton: some View {
        Button {
            viewModel.randomizeSeed()
        } label: {
            Label("Shuffle", systemImage: "shuffle")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(LumenTheme.Colors.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: LumenTheme.Radii.sm)
                        .fill(LumenTheme.Colors.primary.opacity(0.12))
                )
        }
        .accessibilityLabel("Shuffle background variation")
    }

    // MARK: - Typography Section

    private var typographySection: some View {
        VStack(alignment: .leading, spacing: LumenTheme.Spacing.sm) {
            sectionHeader("Typography", icon: "textformat")

            FontPickerView(selection: $viewModel.selectedFontStyle)
        }
    }

    // MARK: - Text Section

    private var textSection: some View {
        VStack(alignment: .leading, spacing: LumenTheme.Spacing.sm) {
            sectionHeader("Text", icon: "pencil")

            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.customText)
                    .frame(minHeight: 80, maxHeight: 120)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: LumenTheme.Radii.sm)
                            .fill(LumenTheme.Colors.glassBackground)
                    )

                if viewModel.customText.isEmpty {
                    Text("Write your affirmation…")
                        .foregroundStyle(.tertiary)
                        .padding(.top, 20)
                        .padding(.leading, 16)
                        .allowsHitTesting(false)
                }
            }

            HStack {
                Spacer()
                Text("\(viewModel.customText.count)/200")
                    .font(.caption)
                    .foregroundStyle(
                        viewModel.customText.count > 180 ? .orange : .secondary
                    )
            }
        }
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: LumenTheme.Spacing.md) {
            Button {
                try? viewModel.resetToDefaults(modelContext: modelContext)
                dismiss()
            } label: {
                Text("Reset")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: LumenTheme.Radii.md)
                            .fill(LumenTheme.Colors.glassBackground)
                    )
            }
            .accessibilityLabel("Reset to defaults")

            Button {
                try? viewModel.save(modelContext: modelContext)
                dismiss()
            } label: {
                Text("Save")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: LumenTheme.Radii.md)
                            .fill(
                                viewModel.hasChanges
                                    ? LumenTheme.Colors.primary
                                    : LumenTheme.Colors.primary.opacity(0.4)
                            )
                    )
            }
            .disabled(!viewModel.hasChanges)
            .accessibilityLabel("Save customization")
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
    }
}

// MARK: - Preview

#Preview {
    CardEditorView(
        affirmation: Affirmation(
            id: "preview_editor",
            text: "I am worthy of love and kindness",
            tone: .gentle,
            intensity: .low,
            source: .user
        ),
        existingCustomization: nil
    )
    .modelContainer(for: [Affirmation.self, CardCustomization.self], inMemory: true)
}
