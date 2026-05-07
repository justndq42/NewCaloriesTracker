import SwiftUI
import SwiftData

struct FoodSearchView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CustomFoodModel.createdAt, order: .reverse) private var customFoods: [CustomFoodModel]
    @StateObject private var vm = FoodSearchViewModel()
    @State private var selectedFood: FoodItem?
    let entryDate: Date

    init(entryDate: Date = Date()) {
        self.entryDate = entryDate
    }

    private var matchingCustomFoods: [FoodItem] {
        let items = customFoods.map(\.foodItem)

        let trimmedQuery = vm.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return items }

        return items.filter {
            SearchQueryNormalizer.localMatches(text: $0.name, query: trimmedQuery)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
                    if !matchingCustomFoods.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
                            FoodSectionTitle("Món tự tạo")

                            ForEach(matchingCustomFoods) { food in
                                Button { selectedFood = food } label: {
                                    FoodRow(food: food)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    FoodSearchContent(
                        state: vm.searchState,
                        onSelectFood: { selectedFood = $0 },
                        onRetry: { vm.onSearchQueryChanged() }
                    )
                }
                .padding(AppTheme.Spacing.screen)
            }
            .appScreenBackground()
            .searchable(text: $vm.searchQuery, prompt: "Tìm món ăn (vd: pho, banh mi...)")
            .onChange(of: vm.searchQuery) { vm.onSearchQueryChanged() }
            .navigationTitle("Tra cứu calo")
            .onAppear { vm.loadRecommended() }
            .sheet(item: $selectedFood) { food in
                FoodDetailSheet(food: food, entryDate: entryDate) { portionedFood in
                    vm.addEntry(food: portionedFood, date: entryDate, context: context)
                    selectedFood = nil
                }
            }
        }
    }
}
