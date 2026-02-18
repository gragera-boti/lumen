import SwiftUI
import SwiftData

struct ThemeGeneratorView: View {
    @State private var viewModel = ThemeGeneratorViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(spacing: LumenTheme.Spacing.lg) {
                previewSection
                    .padding(.horizontal, LumenTheme.Spacing.md)

                if let message = viewModel.capabilityMessage {
                    unsupportedBanner(message: message)
                } else {
                    controlsSection
                    actionSection
                }

                modelManagementSection
            }
            .padding(.vertical, LumenTheme.Spacing.md)
        }
        .navigationTitle("Generate Background")
        .task {
            await viewModel.checkDeviceCapability()
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Preview

    private var previewSection: some View {
        ZStack {
            if let image = viewModel.generatedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: LumenTheme.Radii.card))
            } else {
                RoundedRectangle(cornerRadius: LumenTheme.Radii.card)
                    .fill(
                        LinearGradient(
                            colors: previewColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fill)
            }

            ReadabilityOverlay(opacity: 0.25)
                .clipShape(RoundedRectangle(cornerRadius: LumenTheme.Radii.card))

            VStack {
                Spacer()
                Text("I can take one small step today.")
                    .font(LumenTheme.Typography.affirmationFont)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(LumenTheme.Spacing.lg)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                Spacer()
            }

            if viewModel.isGenerating {
                Color.black.opacity(0.4)
                    .clipShape(RoundedRectangle(cornerRadius: LumenTheme.Radii.card))

                VStack(spacing: LumenTheme.Spacing.md) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)

                    Text("Generating…")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Button("Cancel") {
                        viewModel.cancelGeneration()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .frame(height: 300)
    }

    // MARK: - Controls

    private var controlsSection: some View {
        VStack(spacing: LumenTheme.Spacing.lg) {
            pickerSection(title: "Style") {
                Picker("Style", selection: $viewModel.selectedStyle) {
                    ForEach(GeneratorStyle.allCases, id: \.self) { style in
                        Text(style.rawValue.capitalized).tag(style)
                    }
                }
                .pickerStyle(.segmented)
            }

            pickerSection(title: "Color") {
                Picker("Color", selection: $viewModel.selectedColor) {
                    ForEach(ColorFamily.allCases, id: \.self) { color in
                        Text(color.rawValue.capitalized).tag(color)
                    }
                }
                .pickerStyle(.segmented)
            }

            pickerSection(title: "Mood") {
                Picker("Mood", selection: $viewModel.selectedMood) {
                    ForEach(GeneratorMood.allCases, id: \.self) { mood in
                        Text(mood.rawValue.capitalized).tag(mood)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Detail slider
            pickerSection(title: "Detail level") {
                Slider(value: $viewModel.detailLevel, in: 0...1)
                HStack {
                    Text("Minimal").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text("High detail").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, LumenTheme.Spacing.md)
    }

    // MARK: - Actions

    private var actionSection: some View {
        VStack(spacing: LumenTheme.Spacing.md) {
            PrimaryButton(
                title: viewModel.isGenerating ? "Generating…" : "Generate",
                action: {
                    Task { await viewModel.generate() }
                },
                isDisabled: viewModel.isGenerating || !viewModel.canGenerate
            )

            if viewModel.generatedImage != nil && viewModel.savedThemeId != nil {
                SecondaryButton(title: "Save to My Themes") {
                    viewModel.saveAsTheme(modelContext: modelContext)
                }
            }

            Text("Images are generated on your device.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, LumenTheme.Spacing.md)
    }

    // MARK: - Model Management

    private var modelManagementSection: some View {
        Group {
            if viewModel.canGenerate {
                VStack(spacing: LumenTheme.Spacing.sm) {
                    Divider()
                        .padding(.horizontal, LumenTheme.Spacing.md)

                    if viewModel.isModelReady {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("ML Model")
                                    .font(.subheadline.weight(.semibold))
                                if let size = viewModel.modelSizeText {
                                    Text("Downloaded • \(size)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Button("Remove", role: .destructive) {
                                Task { await viewModel.deleteModel() }
                            }
                            .font(.caption)
                        }
                        .padding(.horizontal, LumenTheme.Spacing.md)
                    } else if viewModel.isDownloadingModel {
                        VStack(spacing: LumenTheme.Spacing.sm) {
                            Text("Downloading ML model…")
                                .font(.subheadline)
                            ProgressView(value: viewModel.downloadProgress)
                        }
                        .padding(.horizontal, LumenTheme.Spacing.md)
                    } else {
                        Button {
                            Task { await viewModel.downloadModel() }
                        } label: {
                            Label("Download ML model for higher quality", systemImage: "arrow.down.circle")
                                .font(.subheadline)
                        }
                        .padding(.horizontal, LumenTheme.Spacing.md)
                    }
                }
                .padding(.bottom, LumenTheme.Spacing.xxl)
            }
        }
    }

    // MARK: - Helpers

    private func pickerSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: LumenTheme.Spacing.sm) {
            Text(title)
                .font(.headline)
            content()
        }
    }

    private func unsupportedBanner(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(LumenTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: LumenTheme.Radii.md)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, LumenTheme.Spacing.md)
    }

    private var previewColors: [Color] {
        switch viewModel.selectedColor {
        case .warm: [Color(hex: "#E8A87C"), Color(hex: "#C38D9E")]
        case .cool: [Color(hex: "#7FBBCA"), Color(hex: "#3B5998")]
        case .mono: [Color(hex: "#4A4A4A"), Color(hex: "#2C2C2C")]
        }
    }
}
