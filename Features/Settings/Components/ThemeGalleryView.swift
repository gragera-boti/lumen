import SwiftData
import SwiftUI
import Dependencies

struct ThemeGalleryView: View {
    enum GalleryTab {
        case active
        case aiHistory
    }

    @Query(sort: \AppTheme.createdAt, order: .reverse)
    private var themes: [AppTheme]

    @Environment(\.modelContext) private var modelContext
    @State private var themeToDelete: AppTheme?
    
    @State private var selectedTab: GalleryTab = .active
    @State private var aiHistory: [GeneratedBackground] = []
    @State private var isLoadingAI = true
    
    @Dependency(\.aiBackgroundService) private var aiBackgroundService: any AIBackgroundServiceProtocol

    private var activeCount: Int {
        themes.filter(\.isInRotation).count
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Gallery View", selection: $selectedTab) {
                Text("Saved").tag(GalleryTab.active)
                Text("AI History").tag(GalleryTab.aiHistory)
            }
            .pickerStyle(.segmented)
            .padding(LumenTheme.Spacing.md)

            Group {
                switch selectedTab {
                case .active:
                    if themes.isEmpty {
                        ContentUnavailableView(
                            "No Backgrounds Yet",
                            systemImage: "photo.on.rectangle.angled",
                            description: Text(
                                "Generate backgrounds in the Theme Generator and save them to build your collection."
                            )
                        )
                    } else {
                        themeList
                    }
                case .aiHistory:
                    if isLoadingAI {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if aiHistory.isEmpty {
                        ContentUnavailableView(
                            "No AI History",
                            systemImage: "sparkles",
                            description: Text("Generate AI backgrounds to see them here.")
                        )
                    } else {
                        aiHistoryList
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ambientBackground()
        .navigationTitle("My Backgrounds")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Delete this background?",
            isPresented: Binding(
                get: { themeToDelete != nil },
                set: { if !$0 { themeToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let theme = themeToDelete {
                    delete(theme)
                }
                themeToDelete = nil
            }
        } message: {
            Text("This can't be undone.")
        }
        .task {
            // Load AI history asynchronously
            aiHistory = await aiBackgroundService.cachedBackgrounds()
            isLoadingAI = false
        }
    }

    // MARK: - List

    private var themeList: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header summary
                HStack {
                    Label("\(activeCount) in rotation", systemImage: "arrow.triangle.2.circlepath")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(themes.count) total")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, LumenTheme.Spacing.md)
                .padding(.vertical, LumenTheme.Spacing.sm)

                // 2-column grid — portrait aspect ratio cards
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                    ],
                    spacing: 12
                ) {
                    ForEach(themes) { theme in
                        ThemeCard(
                            theme: theme,
                            onToggle: { toggleActive(theme) },
                            onDelete: { themeToDelete = theme }
                        )
                    }
                }
                .padding(.horizontal, LumenTheme.Spacing.md)
                .padding(.bottom, 100)
            }
        }
    }

    private var aiHistoryList: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                ],
                spacing: 12
            ) {
                ForEach(aiHistory, id: \.themeId) { bg in
                    VStack(spacing: 0) {
                        ZStack(alignment: .topTrailing) {
                            if let image = UIImage(contentsOfFile: bg.thumbnailPath.path) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .aspectRatio(9 / 16, contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: LumenTheme.Radii.md))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: LumenTheme.Radii.md)
                                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, LumenTheme.Spacing.md)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Actions

    private func toggleActive(_ theme: AppTheme) {
        withAnimation(.easeInOut(duration: 0.2)) {
            theme.isInRotation.toggle()
            theme.updatedAt = .now
            try? modelContext.save()
        }
    }

    private func delete(_ theme: AppTheme) {
        withAnimation {
            removeImageFiles(themeId: theme.id)
            modelContext.delete(theme)
            try? modelContext.save()
        }
    }

    private func removeImageFiles(themeId: String) {
        let dirs: [URL] = [
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen")?
                .appendingPathComponent("themes/generated"),
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen")?
                .appendingPathComponent("themes/ai"),
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
                .appendingPathComponent("themes/generated"),
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
                .appendingPathComponent("themes/ai"),
        ].compactMap { $0 }

        let fm = FileManager.default
        for dir in dirs {
            for ext in ["png", "jpg"] {
                try? fm.removeItem(at: dir.appendingPathComponent("\(themeId).\(ext)"))
                try? fm.removeItem(at: dir.appendingPathComponent("\(themeId)_thumb.\(ext)"))
            }
        }
    }
}

// MARK: - Card

private struct ThemeCard: View {
    let theme: AppTheme
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Image preview — 9:16 aspect (phone-shaped)
            ZStack(alignment: .topTrailing) {
                GeometryReader { geo in
                    if let image = loadThumbnail() {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    } else {
                        LinearGradient(
                            colors: parseGradient(),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
                .aspectRatio(9 / 16, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            theme.isInRotation ? Color.green : Color.white.opacity(0.1),
                            lineWidth: theme.isInRotation ? 2.5 : 1
                        )
                )
                .opacity(theme.isInRotation ? 1.0 : 0.4)

                // Status badge
                if theme.isInRotation {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .green)
                        .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
                        .padding(8)
                }
            }

            // Info + controls
            VStack(spacing: 8) {
                Text(theme.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    // Toggle rotation button
                    Button(action: onToggle) {
                        HStack(spacing: 4) {
                            Image(systemName: theme.isInRotation ? "eye.fill" : "eye.slash")
                                .font(.caption)
                            Text(theme.isInRotation ? "Active" : "Hidden")
                                .font(.caption)
                        }
                        .foregroundStyle(theme.isInRotation ? .green : .secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(theme.isInRotation ? Color.green.opacity(0.15) : Color(.systemGray5))
                        )
                    }
                    .accessibilityLabel(theme.isInRotation ? "Hide from rotation" : "Add to rotation")

                    Spacer()

                    // Delete button
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.red.opacity(0.8))
                            .padding(8)
                            .background(Circle().fill(Color(.systemGray5)))
                    }
                    .accessibilityLabel("Delete background")
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 4)
        }
    }

    // MARK: - Image Loading

    private func loadThumbnail() -> UIImage? {
        let dirs: [URL] = [
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen")?
                .appendingPathComponent("themes/ai"),
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.gragera.lumen")?
                .appendingPathComponent("themes/generated"),
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
                .appendingPathComponent("themes/ai"),
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
                .appendingPathComponent("themes/generated"),
        ].compactMap { $0 }

        for dir in dirs {
            for filename in ["\(theme.id).jpg", "\(theme.id).png", "\(theme.id)_thumb.jpg"] {
                let path = dir.appendingPathComponent(filename)
                if let data = try? Data(contentsOf: path), let img = UIImage(data: data) {
                    return img
                }
            }
        }
        
        // Fallback for bundled curated backgrounds like 'ai_bg_morning_veil'
        if let bundled = UIImage(named: theme.id) {
            return bundled
        }
        
        return nil
    }

    private func parseGradient() -> [Color] {
        guard let data = theme.dataJSON.data(using: .utf8),
            let gradient = try? JSONDecoder().decode(GradientData.self, from: data)
        else {
            return [.purple.opacity(0.6), .blue.opacity(0.6)]
        }
        return gradient.swiftUIColors
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ThemeGalleryView()
    }
    .modelContainer(for: AppTheme.self, inMemory: true)
}
