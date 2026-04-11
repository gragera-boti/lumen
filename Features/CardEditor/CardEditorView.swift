import SwiftData
import SwiftUI
import PhotosUI

// MARK: - CardEditorView

/// Sheet for customizing an affirmation card's background, typography, and text.
struct CardEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router

    private let isEmbedded: Bool
    private let onSaveComplete: (() -> Void)?
    @State private var viewModel: CardEditorViewModel
    @FocusState private var isInputFocused: Bool
    @State private var photoItem: PhotosPickerItem?

    init(
        affirmation: Affirmation, 
        existingCustomization: CardCustomization?, 
        isCreatingNew: Bool = false,
        isEmbedded: Bool = false,
        onSaveComplete: (() -> Void)? = nil
    ) {
        self.isEmbedded = isEmbedded
        self.onSaveComplete = onSaveComplete
        _viewModel = State(
            initialValue: CardEditorViewModel(
                affirmation: affirmation,
                existingCustomization: existingCustomization,
                isCreatingNew: isCreatingNew
            )
        )
    }

    var body: some View {
        Group {
            if isEmbedded {
                content
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Save") { save() }
                                .fontWeight(.semibold)
                                .disabled(!viewModel.hasChanges)
                        }
                    }
            } else {
                NavigationStack {
                    content
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("Cancel") { dismiss() }
                            }
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Save") { save() }
                                    .fontWeight(.semibold)
                                    .disabled(!viewModel.hasChanges)
                            }
                        }
                }
            }
        }
    }

    private var content: some View {
            VStack(spacing: 0) {
                previewCard
                    .padding(.horizontal, LumenTheme.Spacing.md)
                    .padding(.top, LumenTheme.Spacing.sm)
                    .padding(.bottom, LumenTheme.Spacing.md)

                ScrollView {
                    VStack(spacing: LumenTheme.Spacing.lg) {
                        if viewModel.canEditText {
                            textSection
                        }

                        backgroundModeSelector
                        backgroundSection
                        typographySection
                    }
                    .padding(.horizontal, LumenTheme.Spacing.md)
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .ambientBackground()
            .navigationTitle("Customize Card")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadSavedBackgrounds(modelContext: modelContext)
                await viewModel.checkAIModelStatus()
                await viewModel.generatePreview()
                await viewModel.loadSuggestions(modelContext: modelContext)
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
            .alert(
                "general.error".localized,
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
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
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isInputFocused = false
                    }
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
                    .frame(maxWidth: .infinity, maxHeight: 260)
                    .clipped()
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

            Group {
                if viewModel.textOutlineEnabled {
                    Text(viewModel.customText)
                        .font(previewFont)
                        .foregroundStyle(viewModel.selectedTextColor)
                        .textOutline()
                } else {
                    Text(viewModel.customText)
                        .font(previewFont)
                        .foregroundStyle(viewModel.selectedTextColor)
                        .shadow(color: .black.opacity(0.4), radius: 8, y: 3)
                }
            }
            .multilineTextAlignment(.center)
            .lineSpacing(6)
            .padding(.horizontal, LumenTheme.Spacing.xl)
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
        case .saved:
            savedBackgroundSection
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

    // MARK: - Saved Backgrounds

    private var savedBackgroundSection: some View {
        VStack(alignment: .leading, spacing: LumenTheme.Spacing.sm) {
            sectionHeader("My Backgrounds", icon: "photo.on.rectangle")

            if viewModel.savedBackgrounds.isEmpty {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ],
                    spacing: LumenTheme.Spacing.sm
                ) {
                    addPhotoButton

                    Color.clear
                        .frame(height: 100)
                    Color.clear
                        .frame(height: 100)
                }

                VStack(spacing: LumenTheme.Spacing.md) {
                    Image(systemName: "photo.stack")
                        .font(.title)
                        .foregroundStyle(.secondary)

                    Text("No saved backgrounds yet. Generate some in Themes & Backgrounds!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, LumenTheme.Spacing.xl)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ],
                    spacing: LumenTheme.Spacing.sm
                ) {
                    addPhotoButton
                    ForEach(viewModel.savedBackgrounds) { item in
                        Button {
                            viewModel.selectSavedBackground(item)
                        } label: {
                            Image(uiImage: item.thumbnail)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 100)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: LumenTheme.Radii.sm))
                                .overlay(
                                    RoundedRectangle(cornerRadius: LumenTheme.Radii.sm)
                                        .strokeBorder(
                                            viewModel.selectedSavedBackground?.id == item.id
                                                ? LumenTheme.Colors.primary
                                                : Color.clear,
                                            lineWidth: 3
                                        )
                                )
                                .overlay {
                                    if viewModel.selectedSavedBackground?.id == item.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.white)
                                            .shadow(radius: 4)
                                    }
                                }
                        }
                        .accessibilityLabel("Saved background \(item.id)")
                    }
                }
            }
        }
        .onChange(of: photoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    viewModel.loadCustomPhoto(data: data)
                }
            }
        }
    }

    private var addPhotoButton: some View {
        let isSelected = viewModel.newlySelectedPhoto || viewModel.isCurrentSelectionCustomPhoto
        return PhotosPicker(selection: $photoItem, matching: .images) {
            VStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.title2)
                Text("Add Photo")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(contentMode: .fill)
            .frame(height: 100)
            .background(LumenTheme.Colors.glassBackground)
            .clipShape(RoundedRectangle(cornerRadius: LumenTheme.Radii.sm))
            .overlay(
                RoundedRectangle(cornerRadius: LumenTheme.Radii.sm)
                    .strokeBorder(
                        isSelected ? LumenTheme.Colors.primary : Color.clear,
                        lineWidth: 3
                    )
            )
        }
        .accessibilityLabel("Add custom photo from library")
    }

    // MARK: - AI Controls (matching ThemeGeneratorView)

    private var aiBackgroundSection: some View {
        VStack(spacing: LumenTheme.Spacing.lg) {
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
                                        .font(
                                            .subheadline.weight(
                                                viewModel.selectedPromptCategory == category ? .semibold : .regular
                                            )
                                        )
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

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                        ],
                        spacing: LumenTheme.Spacing.sm
                    ) {
                        ForEach(prompts) { prompt in
                            Button {
                                viewModel.selectedPrompt = prompt
                                Task { await viewModel.generatePreview() }
                            } label: {
                                Text(prompt.displayName)
                                    .font(
                                        .subheadline.weight(
                                            viewModel.selectedPrompt?.id == prompt.id ? .semibold : .regular
                                        )
                                    )
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
        VStack(alignment: .leading, spacing: LumenTheme.Spacing.md) {
            sectionHeader("Typography", icon: "textformat")

            FontPickerView(selection: $viewModel.selectedFontStyle)

            textColorPicker

            Toggle(isOn: $viewModel.textOutlineEnabled) {
                Label("Text Outline", systemImage: "character.cursor.ibeam")
                    .font(.subheadline.weight(.medium))
            }
            .tint(LumenTheme.Colors.primary)
        }
    }

    // MARK: - Text Color Picker

    private static let textColorPresets: [(name: String, color: Color)] = [
        ("White", .white),
        ("Blush", Color(hex: "#F8E0DE")),
        ("Lavender", Color(hex: "#D9C7F2")),
        ("Mauve", Color(hex: "#B896C4")),
        ("Crocus", Color(hex: "#BC6CA7")),
        ("Sage", Color(hex: "#A5D6A7")),
        ("Mocha", Color(hex: "#A47764")),
        ("Terracotta", Color(hex: "#CE7B5B")),
    ]

    private var textColorPicker: some View {
        VStack(alignment: .leading, spacing: LumenTheme.Spacing.sm) {
            Text("Text Color")
                .font(.subheadline.weight(.medium))

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: Self.textColorPresets.count + 1),
                spacing: LumenTheme.Spacing.sm
            ) {
                ForEach(Self.textColorPresets, id: \.name) { preset in
                    let isSelected = viewModel.selectedTextColor.hexString == preset.color.hexString
                    Button {
                        viewModel.selectedTextColor = preset.color
                    } label: {
                        Circle()
                            .fill(preset.color)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        isSelected ? LumenTheme.Colors.primary : Color.white.opacity(0.3),
                                        lineWidth: isSelected ? 2.5 : 1
                                    )
                            )
                            .shadow(color: .black.opacity(0.2), radius: 2)
                            .overlay {
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(preset.color == .white ? Color.black : Color.white)
                                }
                            }
                    }
                    .accessibilityLabel("\(preset.name) text color")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }

                // Custom color picker as last cell
                ColorPicker("", selection: $viewModel.selectedTextColor, supportsOpacity: false)
                    .labelsHidden()
                    .accessibilityLabel("Custom text color")
            }
        }
    }

    // MARK: - Text Section

    private var textSection: some View {
        VStack(alignment: .leading, spacing: LumenTheme.Spacing.sm) {
            sectionHeader("Text", icon: "pencil")

            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.customText)
                    .focused($isInputFocused)
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

            if viewModel.isCreatingNew && !viewModel.suggestions.isEmpty {
                suggestionsSection
            }
        }
    }

    // MARK: - ML Suggestions Section

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: LumenTheme.Spacing.sm) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text("Inspired by your favorites")
                    .font(.headline)
            }

            ForEach(viewModel.suggestions, id: \.self) { suggestion in
                Button {
                    withAnimation {
                        viewModel.customText = suggestion
                    }
                } label: {
                    HStack {
                        Text(suggestion)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                        Spacer()
                        Image(systemName: "arrow.up.left")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: LumenTheme.Radii.sm)
                            .fill(LumenTheme.Colors.glassBackground)
                    )
                }
            }
        }
        .padding(.top, LumenTheme.Spacing.sm)
    }

    private func save() {
        try? viewModel.save(modelContext: modelContext)
        if let onSaveComplete = onSaveComplete {
            onSaveComplete()
        } else {
            dismiss()
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
    .environment(AppRouter())
    .modelContainer(for: [Affirmation.self, CardCustomization.self], inMemory: true)
}
