import SwiftUI
import SwiftData

struct HistoryView: View {
    @State private var viewModel = HistoryViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router

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
        }
    }

    private var historyList: some View {
        List {
            ForEach(viewModel.entries) { entry in
                Button {
                    router.navigate(to: .affirmationDetail(affirmationId: entry.affirmationId), in: .settings)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.text)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .lineLimit(2)

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
}
