import SwiftUI
import SwiftData

struct HistoryView: View {
    @State private var viewModel = HistoryViewModel()
    @State private var customizations: [String: CardCustomization] = [:]
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router

    private let customizationService: CardCustomizationServiceProtocol = CardCustomizationService.shared

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.entries.isEmpty {
                emptyState
            } else {
                historyList
            }
        }
        .navigationTitle("history.title".localized)
        .task {
            viewModel.loadHistory(modelContext: modelContext)
            loadCustomizations()
        }
    }

    private var historyList: some View {
        List {
            ForEach(viewModel.entries) { entry in
                let custom = customizations[entry.affirmationId]
                let displayText = (custom?.customText?.isEmpty == false)
                    ? custom!.customText!
                    : entry.text
                Button {
                    router.navigate(to: .affirmationDetail(affirmationId: entry.affirmationId), in: .settings)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(displayText)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .lineLimit(2)

                            if custom != nil {
                                Image(systemName: "paintbrush.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        HStack {
                            Text(entry.seenAt, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()

                            if !entry.categoryNames.isEmpty {
                                Text(entry.categoryNames)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .padding(.vertical, LumenTheme.Spacing.xs)
                }
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "history.empty.title".localized,
            systemImage: "clock",
            description: Text("history.empty.description".localized)
        )
    }

    private func loadCustomizations() {
        do {
            let all = try customizationService.allCustomizations(modelContext: modelContext)
            let ids = Set(viewModel.entries.map(\.affirmationId))
            var map: [String: CardCustomization] = [:]
            for c in all where ids.contains(c.affirmationId) {
                map[c.affirmationId] = c
            }
            customizations = map
        } catch {
            // Non-critical — history still works without customizations
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HistoryView()
    }
    .environment(AppRouter())
    .modelContainer(for: [SeenEvent.self, Affirmation.self], inMemory: true)
}
