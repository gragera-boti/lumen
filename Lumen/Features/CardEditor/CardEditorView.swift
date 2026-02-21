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
            .background(Color(.systemGroupedBackground))
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
            .onChange(of: viewModel.backgroundMode) { _, _ in
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
        return Font.system(size: 26, weight: .medium, design: .serif)
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

    private var proceduralBackgroundSection: some View {
        VStack(alignment: .leading, spacing: LumenTheme.Spacing.sm) {
            sectionHeader("Background", icon: "paintpalette")

            Text("Style")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.leading, LumenTheme.Spacing.md)

            StylePickerView(
                selection: $viewModel.selectedStyle,
                palette: viewModel.selectedPalette
            )

            Text("Color")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.leading, LumenTheme.Spacing.md)

            PalettePickerView(selection: $viewModel.selectedPalette)

            shuffleButton
        }
    }

    private var aiBackgroundSection: some View {
        VStack(alignment: .leading, spacing: LumenTheme.Spacing.sm) {
            sectionHeader("AI Background", icon: "sparkles")

            if !viewModel.aiModelReady && !viewModel.isLoadingAIModel {
                aiModelDownloadPrompt
            } else if viewModel.isLoadingAIModel {
                aiModelLoadingView
            } else {
                aiPromptPicker
                shuffleButton
            }
        }
    }

    private var aiModelDownloadPrompt: some View {
        VStack(spacing: LumenTheme.Spacing.md) {
            Image(systemName: "cpu")
                .font(.title)
                .foregroundStyle(.secondary)

            Text("AI model needs to be loaded before generating backgrounds.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await viewModel.loadAIModel() }
            } label: {
                Label("Load AI Model", systemImage: "arrow.down.circle")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: LumenTheme.Radii.sm)
                            .fill(LumenTheme.Colors.primary)
                    )
            }
            .accessibilityLabel("Download and load AI background model")
        }
        .padding(LumenTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: LumenTheme.Radii.md)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal, LumenTheme.Spacing.md)
    }

    private var aiModelLoadingView: some View {
        VStack(spacing: LumenTheme.Spacing.sm) {
            ProgressView(value: viewModel.aiLoadProgress, total: 1.0)
                .tint(LumenTheme.Colors.primary)

            Text(viewModel.aiLoadingPhase)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(LumenTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: LumenTheme.Radii.md)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal, LumenTheme.Spacing.md)
    }

    private var aiPromptPicker: some View {
        VStack(alignment: .leading, spacing: LumenTheme.Spacing.sm) {
            Text("Category")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.leading, LumenTheme.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LumenTheme.Spacing.sm) {
                    ForEach(AIBackgroundPrompt.PromptCategory.allCases) { category in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectedPromptCategory = category
                                viewModel.selectedPrompt = AIBackgroundPrompt.random(category: category)
                            }
                            Task { await viewModel.generatePreview() }
                        } label: {
                            HStack(spacing: 4) {
                                Text(category.emoji)
                                Text(category.displayName)
                                    .font(.subheadline.weight(.medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(
                                    viewModel.selectedPromptCategory == category
                                        ? LumenTheme.Colors.primary.opacity(0.2)
                                        : Color(.tertiarySystemGroupedBackground)
                                )
                            )
                            .foregroundStyle(
                                viewModel.selectedPromptCategory == category
                                    ? LumenTheme.Colors.primary
                                    : .secondary
                            )
                        }
                        .accessibilityLabel("\(category.displayName) AI backgrounds")
                        .accessibilityAddTraits(
                            viewModel.selectedPromptCategory == category ? .isSelected : []
                        )
                    }
                }
                .padding(.horizontal, LumenTheme.Spacing.md)
            }

            if let prompt = viewModel.selectedPrompt {
                Text(prompt.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, LumenTheme.Spacing.md)
            }
        }
    }

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
        .padding(.horizontal, LumenTheme.Spacing.md)
        .accessibilityLabel("Shuffle background variation")
    }

    // MARK: - Typography Section

    private var typographySection: some View {
        VStack(alignment: .leading, spacing: LumenTheme.Spacing.sm) {
            sectionHeader("Typography", icon: "textformat")

            FontPickerView(selection: $viewModel.selectedFontStyle)
                .padding(.horizontal, LumenTheme.Spacing.md)
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
                            .fill(Color(.systemBackground))
                    )

                if viewModel.customText.isEmpty {
                    Text("Write your affirmation…")
                        .foregroundStyle(.tertiary)
                        .padding(.top, 20)
                        .padding(.leading, 16)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, LumenTheme.Spacing.md)

            HStack {
                Spacer()
                Text("\(viewModel.customText.count)/200")
                    .font(.caption)
                    .foregroundStyle(
                        viewModel.customText.count > 180 ? .orange : .secondary
                    )
            }
            .padding(.horizontal, LumenTheme.Spacing.md)
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
                            .fill(Color(.systemBackground))
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
            .padding(.leading, LumenTheme.Spacing.md)
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
