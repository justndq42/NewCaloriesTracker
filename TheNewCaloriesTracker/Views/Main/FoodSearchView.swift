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
        let items = customFoods.map {
            FoodItem(
                name: $0.name,
                calories: $0.calories,
                protein: $0.protein,
                carbs: $0.carbs,
                fat: $0.fat,
                unit: $0.unit
            )
        }

        let trimmedQuery = vm.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return items }

        return items.filter {
            $0.name.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if !matchingCustomFoods.isEmpty {
                    Section("Món tự tạo") {
                        ForEach(matchingCustomFoods) { food in
                            Button { selectedFood = food } label: {
                                FoodRow(food: food)
                            }
                        }
                    }
                }

                FoodSearchContent(
                    state: vm.searchState,
                    onSelectFood: { selectedFood = $0 },
                    onRetry: { vm.onSearchQueryChanged() }
                )
            }
            .searchable(text: $vm.searchQuery, prompt: "Tìm món ăn (vd: pho, banh mi...)")
            .onChange(of: vm.searchQuery) { vm.onSearchQueryChanged() }
            .navigationTitle("Tra cứu calo")
            .onAppear { vm.loadRecommended() }
            .sheet(item: $selectedFood) { food in
                FoodDetailSheet(food: food, entryDate: entryDate) {
                    vm.addEntry(food: food, date: entryDate, context: context)
                    selectedFood = nil
                }
            }
        }
    }
}
