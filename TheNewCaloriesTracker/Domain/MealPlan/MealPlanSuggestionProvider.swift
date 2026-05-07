import Foundation

struct MealPlanSuggestedFood: Identifiable {
    let id: String
    let food: FoodItem
    let reason: String
    let category: MealPlanSuggestionCategory
}

enum MealPlanSuggestionCategory {
    case energyDense
    case proteinFocused
    case carbFocused
    case fiberFocused
    case healthyFat
    case balanced
}

struct MealPlanSuggestionProvider {
    func suggestions(for goal: NutritionGoal, limit: Int = 10) -> [MealPlanSuggestedFood] {
        switch goal {
        case .gain:
            return suggestedFoods(from: [
                SuggestionSeed(name: "Cơm tấm sườn bì", reason: "Món Việt nhiều năng lượng", category: .energyDense),
                SuggestionSeed(name: "Bún chả", reason: "Món Việt nhiều năng lượng", category: .energyDense),
                SuggestionSeed(name: "Bánh mì thịt", reason: "Món Việt nhiều năng lượng", category: .energyDense),
                SuggestionSeed(name: "Phở bò", reason: "Món Việt truyền thống", category: .energyDense),
                SuggestionSeed(name: "Bún bò Huế", reason: "Món Việt truyền thống", category: .energyDense),
                SuggestionSeed(name: "Cơm gà xối mỡ", reason: "Calo cao", category: .energyDense),
                SuggestionSeed(name: "Mì Quảng", reason: "Món Việt truyền thống", category: .energyDense),
                SuggestionSeed(name: "Xôi gà", reason: "Calo cao", category: .energyDense),
                SuggestionSeed(name: "Bánh xèo", reason: "Món Việt truyền thống", category: .energyDense),
                SuggestionSeed(name: "Bò lúc lắc", reason: "Món Việt nhiều năng lượng", category: .energyDense),
            ], limit: limit)
        case .lose:
            return suggestedFoods(from: [
                SuggestionSeed(name: "Ức gà", reason: "Giàu protein", category: .proteinFocused),
                SuggestionSeed(name: "Tôm luộc", reason: "Giàu protein", category: .proteinFocused),
                SuggestionSeed(name: "Cá basa", reason: "Giàu protein", category: .proteinFocused),
                SuggestionSeed(name: "Đậu phụ", reason: "Protein thực vật", category: .proteinFocused),
                SuggestionSeed(name: "Khoai lang", reason: "Carb tốt", category: .carbFocused),
                SuggestionSeed(name: "Cơm gạo lứt", reason: "Carb tốt", category: .carbFocused),
                SuggestionSeed(name: "Yến mạch", reason: "Carb tốt", category: .carbFocused),
                SuggestionSeed(name: "Bông cải xanh", reason: "Nhiều chất xơ", category: .fiberFocused),
                SuggestionSeed(name: "Cải bó xôi", reason: "Nhiều chất xơ", category: .fiberFocused),
                SuggestionSeed(name: "Táo", reason: "Nhiều chất xơ", category: .fiberFocused),
                SuggestionSeed(name: "Cam", reason: "Nhiều chất xơ", category: .fiberFocused),
                SuggestionSeed(name: "Bơ", reason: "Fat tốt", category: .healthyFat),
            ], limit: limit)
        case .maintain:
            return suggestedFoods(from: [
                SuggestionSeed(name: "Ức gà", reason: "Lean cân bằng", category: .balanced),
                SuggestionSeed(name: "Cơm gạo lứt", reason: "Carb vừa đủ", category: .carbFocused),
                SuggestionSeed(name: "Cá hồi", reason: "Fat tốt", category: .healthyFat),
                SuggestionSeed(name: "Tôm luộc", reason: "Lean cân bằng", category: .balanced),
                SuggestionSeed(name: "Đậu phụ", reason: "Lean cân bằng", category: .balanced),
                SuggestionSeed(name: "Phở gà", reason: "Món Việt vừa phải", category: .balanced),
                SuggestionSeed(name: "Gỏi cuốn tôm thịt", reason: "Món Việt vừa phải", category: .balanced),
                SuggestionSeed(name: "Bún cá", reason: "Món Việt vừa phải", category: .balanced),
                SuggestionSeed(name: "Canh chua cá", reason: "Món Việt vừa phải", category: .balanced),
                SuggestionSeed(name: "Sữa chua không đường", reason: "Lean cân bằng", category: .balanced),
            ], limit: limit)
        }
    }

    private func suggestedFoods(from seeds: [SuggestionSeed], limit: Int) -> [MealPlanSuggestedFood] {
        seeds
            .compactMap { seed -> MealPlanSuggestedFood? in
                guard let food = food(named: seed.name) else { return nil }
                return MealPlanSuggestedFood(
                    id: food.name,
                    food: food,
                    reason: seed.reason,
                    category: seed.category
                )
            }
            .prefix(limit)
            .map { $0 }
    }

    private func food(named name: String) -> FoodItem? {
        VietnameseFoodCatalog.entries
            .first { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }?
            .foodItem
    }
}

private struct SuggestionSeed {
    let name: String
    let reason: String
    let category: MealPlanSuggestionCategory
}
