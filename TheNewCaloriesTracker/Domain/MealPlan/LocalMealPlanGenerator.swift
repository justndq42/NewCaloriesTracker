import Foundation

struct LocalMealPlanGenerator {
    private let catalog: [FoodItem]

    init(catalog: [FoodItem] = VietnameseFoodCatalog.recommended) {
        self.catalog = catalog
    }

    func generate(profile: UserProfileModel) -> DayMealPlan {
        let nutrition = NutritionProfile(profile: profile)
        let slots = MealPlanSlotKind.allCases.map {
            makeSlot(kind: $0, nutrition: nutrition, goal: profile.nutritionGoal)
        }

        return makeDayPlan(slots: slots, nutrition: nutrition, goal: profile.goal)
    }

    func replacingSlot(
        _ kind: MealPlanSlotKind,
        in plan: DayMealPlan,
        profile: UserProfileModel,
        variationOffset: Int
    ) -> DayMealPlan {
        let nutrition = NutritionProfile(profile: profile)
        let currentSignature = plan.slots.first { $0.kind == kind }.map { signature(for: $0.foods) }
        let slots = plan.slots.map { slot in
            slot.kind == kind
                ? makeSlot(
                    kind: kind,
                    nutrition: nutrition,
                    goal: profile.nutritionGoal,
                    excluding: currentSignature,
                    variationOffset: variationOffset
                )
                : slot
        }

        return makeDayPlan(slots: slots, nutrition: nutrition, goal: profile.goal)
    }

    func addingFood(_ food: FoodItem, to kind: MealPlanSlotKind, in plan: DayMealPlan, profile: UserProfileModel) -> DayMealPlan {
        let nutrition = NutritionProfile(profile: profile)
        let slots = plan.slots.map { slot in
            guard slot.kind == kind else { return slot }

            return MealPlanSlot(
                kind: slot.kind,
                targetCalories: slot.targetCalories,
                targetProtein: slot.targetProtein,
                targetCarbs: slot.targetCarbs,
                targetFat: slot.targetFat,
                foods: slot.foods + [MealPlanFood(food: food)]
            )
        }

        return makeDayPlan(slots: slots, nutrition: nutrition, goal: profile.goal)
    }

    private func makeDayPlan(slots: [MealPlanSlot], nutrition: NutritionProfile, goal: String) -> DayMealPlan {
        DayMealPlan(
            slots: slots,
            totalCalories: Double(slots.reduce(0) { $0 + $1.totalCalories }),
            totalProtein: slots.reduce(0) { $0 + $1.totalProtein },
            totalCarbs: slots.reduce(0) { $0 + $1.totalCarbs },
            totalFat: slots.reduce(0) { $0 + $1.totalFat },
            goal: goal,
            targetCalories: Int(nutrition.targetCalories),
            targetProtein: nutrition.proteinGrams,
            targetCarbs: nutrition.carbsGrams,
            targetFat: nutrition.fatGrams
        )
    }

    private func makeSlot(
        kind: MealPlanSlotKind,
        nutrition: NutritionProfile,
        goal: NutritionGoal,
        excluding currentSignature: String? = nil,
        variationOffset: Int = 0
    ) -> MealPlanSlot {
        let target = slotTarget(kind: kind, nutrition: nutrition)
        let candidates = templates(for: kind, goal: goal)
            .flatMap { makeFoodVariants(from: $0, targetCalories: target.calories) }
            .sorted { score($0, target: target) < score($1, target: target) }
            .filter { signature(for: $0) != currentSignature }
        let selectedFoods = candidate(from: candidates, offset: variationOffset)
            ?? fallbackFoods(targetCalories: target.calories)

        return MealPlanSlot(
            kind: kind,
            targetCalories: target.calories,
            targetProtein: target.protein,
            targetCarbs: target.carbs,
            targetFat: target.fat,
            foods: selectedFoods
        )
    }

    private func slotTarget(kind: MealPlanSlotKind, nutrition: NutritionProfile) -> SlotNutritionTarget {
        SlotNutritionTarget(
            calories: nutrition.targetCalories * kind.calorieRatio,
            protein: nutrition.proteinGrams * kind.calorieRatio,
            carbs: nutrition.carbsGrams * kind.calorieRatio,
            fat: nutrition.fatGrams * kind.calorieRatio
        )
    }

    private func makeFoodVariants(from names: [String], targetCalories: Double) -> [[MealPlanFood]] {
        let foods = names.compactMap(food(named:))
        guard foods.count == names.count else { return [] }

        let baseCalories = foods.reduce(0) { $0 + $1.calories }
        guard baseCalories > 0 else { return [] }

        return portionPatterns(itemCount: foods.count, baseCalories: baseCalories, targetCalories: targetCalories)
            .map { pattern in
                zip(foods, pattern).map { food, servings in
                    portionedFood(food, servings: servings)
                }
            }
    }

    private func fallbackFoods(targetCalories: Double) -> [MealPlanFood] {
        let fallback = catalog
            .filter { $0.calories > 0 }
            .sorted { abs(Double($0.calories) - targetCalories) < abs(Double($1.calories) - targetCalories) }
            .prefix(2)

        return fallback.map { portionedFood($0, servings: 1) }
    }

    private func candidate(from candidates: [[MealPlanFood]], offset: Int) -> [MealPlanFood]? {
        guard !candidates.isEmpty else { return nil }
        return candidates[abs(offset) % candidates.count]
    }

    private func food(named name: String) -> FoodItem? {
        catalog.first { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }
    }

    private func portionedFood(_ food: FoodItem, servings: Int) -> MealPlanFood {
        let safeServings = max(1, servings)

        return MealPlanFood(
            name: food.name,
            calories: food.calories * safeServings,
            protein: food.protein * Double(safeServings),
            carbs: food.carbs * Double(safeServings),
            fat: food.fat * Double(safeServings),
            unit: unitLabel(food.unit, servings: safeServings)
        )
    }

    private func unitLabel(_ unit: String, servings: Int) -> String {
        servings == 1 ? unit : "\(servings) x \(unit)"
    }

    private func portionPatterns(itemCount: Int, baseCalories: Int, targetCalories: Double) -> [[Int]] {
        let basePattern = Array(repeating: 1, count: itemCount)
        guard itemCount > 0 else { return [] }

        var patterns = [basePattern]

        for index in 0..<itemCount {
            var doubledItem = basePattern
            doubledItem[index] = 2
            patterns.append(doubledItem)
        }

        if Double(baseCalories) * 1.6 < targetCalories {
            patterns.append(Array(repeating: 2, count: itemCount))
        }

        if itemCount == 1, Double(baseCalories) * 2.4 < targetCalories {
            patterns.append([3])
        }

        return uniquePatterns(patterns)
    }

    private func uniquePatterns(_ patterns: [[Int]]) -> [[Int]] {
        var seen = Set<String>()
        return patterns.filter { pattern in
            seen.insert(pattern.map(String.init).joined(separator: "-")).inserted
        }
    }

    private func score(_ foods: [MealPlanFood], target: SlotNutritionTarget) -> Double {
        let calories = Double(foods.reduce(0) { $0 + $1.calories })
        let protein = foods.reduce(0) { $0 + $1.protein }
        let carbs = foods.reduce(0) { $0 + $1.carbs }
        let fat = foods.reduce(0) { $0 + $1.fat }

        return normalizedDifference(calories, target.calories)
            + normalizedDifference(protein, target.protein) * 1.2
            + normalizedDifference(carbs, target.carbs)
            + normalizedDifference(fat, target.fat)
    }

    private func normalizedDifference(_ value: Double, _ target: Double) -> Double {
        guard target > 0 else { return 0 }
        return abs(value - target) / target
    }

    private func signature(for foods: [MealPlanFood]) -> String {
        foods
            .map { "\($0.name)-\($0.calories)-\($0.unit)" }
            .joined(separator: "|")
    }

    private func templates(for kind: MealPlanSlotKind, goal: NutritionGoal) -> [[String]] {
        switch (kind, goal) {
        case (.breakfast, .lose):
            return [
                ["Yến mạch", "Sữa chua không đường", "Táo"],
                ["Trứng gà", "Khoai lang", "Bông cải xanh"],
                ["Sữa chua không đường", "Chuối", "Yến mạch"],
            ]
        case (.breakfast, .gain):
            return [
                ["Bánh mì thịt"],
                ["Xôi gà"],
                ["Phở bò"],
                ["Yến mạch", "Sữa tươi không đường", "Chuối"],
                ["Bánh mì trứng", "Sữa đậu nành không đường"],
            ]
        case (.breakfast, .maintain):
            return [
                ["Yến mạch", "Sữa chua không đường", "Chuối"],
                ["Phở gà"],
                ["Trứng gà", "Sữa chua không đường", "Cam"],
            ]
        case (.lunch, .lose):
            return [
                ["Cơm gạo lứt", "Ức gà", "Bông cải xanh"],
                ["Khoai lang", "Tôm luộc", "Dưa leo"],
                ["Cơm gạo lứt", "Cá basa", "Cải bó xôi"],
            ]
        case (.lunch, .gain):
            return [
                ["Cơm tấm sườn bì"],
                ["Bún chả"],
                ["Cơm gà xối mỡ"],
                ["Bún bò Huế"],
                ["Cơm trắng", "Thịt bò nạc", "Trứng gà", "Bông cải xanh"],
                ["Bún thịt nướng"],
            ]
        case (.lunch, .maintain):
            return [
                ["Cơm gạo lứt", "Ức gà", "Bông cải xanh"],
                ["Cơm gạo lứt", "Thịt bò nạc", "Cà chua"],
                ["Bún cá"],
                ["Gỏi cuốn tôm thịt", "Sữa đậu nành không đường"],
            ]
        case (.snack, .lose):
            return [
                ["Sữa chua không đường", "Táo"],
                ["Cam", "Sữa đậu nành không đường"],
                ["Bơ", "Sữa chua không đường"],
            ]
        case (.snack, .gain):
            return [
                ["Bánh mì thịt"],
                ["Chả giò"],
                ["Sữa tươi không đường", "Chuối", "Yến mạch"],
                ["Bánh mì trứng"],
                ["Bơ", "Sữa đậu nành không đường"],
            ]
        case (.snack, .maintain):
            return [
                ["Sữa chua không đường", "Chuối"],
                ["Táo", "Sữa đậu nành không đường"],
                ["Gỏi cuốn tôm thịt"],
            ]
        case (.dinner, .lose):
            return [
                ["Khoai lang", "Cá basa", "Cải bó xôi"],
                ["Đậu phụ", "Bông cải xanh", "Cà chua"],
                ["Canh chua cá", "Cơm gạo lứt"],
                ["Tôm luộc", "Khoai lang", "Dưa leo"],
            ]
        case (.dinner, .gain):
            return [
                ["Mì Quảng"],
                ["Bò lúc lắc"],
                ["Bánh xèo"],
                ["Hủ tiếu Nam Vang"],
                ["Cơm trắng", "Cá hồi", "Cải bó xôi"],
                ["Cơm trắng", "Thịt lợn nạc", "Dưa leo"],
            ]
        case (.dinner, .maintain):
            return [
                ["Cơm gạo lứt", "Cá hồi", "Cải bó xôi"],
                ["Khoai lang", "Tôm luộc", "Dưa leo"],
                ["Canh chua cá", "Cơm trắng"],
                ["Đậu phụ", "Bông cải xanh", "Cà chua"],
            ]
        }
    }
}

private struct SlotNutritionTarget {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
}
