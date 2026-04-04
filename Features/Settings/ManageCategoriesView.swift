import SwiftData
import SwiftUI

struct ManageCategoriesView: View {
    let isPremium: Bool
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @State private var viewModel = ManageCategoriesViewModel()
    @State private var preferences: UserPreferences?
    private let preferencesService: PreferencesServiceProtocol = PreferencesService.shared
    
    var body: some View {
        List {
            Section(
                header: Text("Manage Categories"),
                footer: Text("Choose which categories of affirmations you would like to see in your daily feed.")
            ) {
                if let prefs = preferences {
                    ForEach(viewModel.categories) { category in
                        categoryRow(for: category, in: prefs)
                    }
                } else {
                    ProgressView()
                }
            }
        }
        .ambientBackground()
        .navigationTitle("Categories")
        .task {
            preferences = try? preferencesService.getOrCreate(modelContext: modelContext)
            await viewModel.loadCategories(modelContext: modelContext)
        }
        .onChange(of: router.isShowingPaywall) { _, isShowing in
            if !isShowing {
                Task {
                    await viewModel.loadCategories(modelContext: modelContext)
                }
            }
        }
    }
    
    private func categoryRow(for category: Category, in prefs: UserPreferences) -> some View {
        let isSelected = prefs.selectedCategoryIds.contains(category.id)
        return Button {
            if category.isPremium && !viewModel.isPremium {
                router.isShowingPaywall = true
            } else {
                toggleCategory(category.id, in: prefs)
            }
        } label: {
            HStack {
                Image(systemName: category.icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                
                Text(category.name)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if category.isPremium {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.primary)
                        .fontWeight(.bold)
                }
            }
            .contentShape(Rectangle())
        }
    }
    
    private func toggleCategory(_ id: String, in prefs: UserPreferences) {
        var ids = Set(prefs.selectedCategoryIds)
        if ids.contains(id) {
            ids.remove(id)
        } else {
            ids.insert(id)
        }
        prefs.selectedCategoryIds = Array(ids)
        prefs.updatedAt = .now
        try? preferencesService.save(modelContext: modelContext)
    }
}

#Preview {
    NavigationStack {
        ManageCategoriesView(isPremium: true)
    }
    .environment(AppRouter())
    .modelContainer(for: UserPreferences.self, inMemory: true)
}
