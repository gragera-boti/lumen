import SwiftUI
import SwiftData

struct ExploreView: View {
    @State private var viewModel = ExploreViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: LumenTheme.Spacing.md) {
                ForEach(viewModel.categories, id: \.id) { category in
                    CategoryCardView(category: category) {
                        if category.isPremium && !viewModel.isPremium {
                            router.isShowingPaywall = true
                        } else {
                            router.navigate(to: .categoryFeed(categoryId: category.id), in: .explore)
                        }
                    }
                }
            }
            .padding(LumenTheme.Spacing.md)
        }
        .navigationTitle("explore.title".localized)
        .task {
            await viewModel.loadData(modelContext: modelContext)
        }
    }
}
