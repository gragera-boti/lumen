import SwiftUI
import SwiftData

struct HistoryView: View {
    @State private var viewModel = HistoryViewModel()
    @Environment(\.modelContext) private var modelContext

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
        .navigationTitle("History")
        .task {
            viewModel.loadHistory(modelContext: modelContext)
        }
    }

    private var historyList: some View {
        List(viewModel.entries) { entry in
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.text)
                    .font(.subheadline)
                    .lineLimit(2)

                HStack {
                    Text(entry.seenAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(entry.source.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, LumenTheme.Spacing.xs)
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No history yet",
            systemImage: "clock",
            description: Text("Affirmations you view will appear here.")
        )
    }
}
