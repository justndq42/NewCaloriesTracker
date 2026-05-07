import Foundation

struct DayMealPlan: Identifiable {
    let id = UUID()
    let slots: [MealPlanSlot]
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    let goal: String
    let targetCalories: Int
    let targetProtein: Double
    let targetCarbs: Double
    let targetFat: Double
}

enum MealPlanSlotKind: String, CaseIterable, Identifiable {
    case breakfast
    case lunch
    case snack
    case dinner

    var id: String { rawValue }

    var title: String {
        switch self {
        case .breakfast:
            return "Sáng"
        case .lunch:
            return "Trưa"
        case .snack:
            return "Snack"
        case .dinner:
            return "Tối"
        }
    }

    var icon: String {
        switch self {
        case .breakfast:
            return "sunrise.fill"
        case .lunch:
            return "sun.max.fill"
        case .snack:
            return "carrot.fill"
        case .dinner:
            return "moon.fill"
        }
    }

    var colorName: String {
        switch self {
        case .breakfast:
            return "orange"
        case .lunch:
            return "blue"
        case .snack:
            return "green"
        case .dinner:
            return "indigo"
        }
    }

    var calorieRatio: Double {
        switch self {
        case .breakfast:
            return 0.25
        case .lunch:
            return 0.35
        case .snack:
            return 0.10
        case .dinner:
            return 0.30
        }
    }

    var defaultHour: Int {
        switch self {
        case .breakfast:
            return 8
        case .lunch:
            return 12
        case .snack:
            return 16
        case .dinner:
            return 19
        }
    }

    var mealPeriod: MealPeriod {
        switch self {
        case .breakfast:
            return .breakfast
        case .lunch:
            return .lunch
        case .snack:
            return .snack
        case .dinner:
            return .dinner
        }
    }
}

struct MealPlanFood: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let unit: String
    let servingSize: ServingSize?

    init(
        name: String,
        calories: Int,
        protein: Double,
        carbs: Double,
        fat: Double,
        unit: String,
        servingSize: ServingSize? = nil
    ) {
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.unit = unit
        self.servingSize = servingSize
    }

    init(food: FoodItem) {
        self.init(
            name: food.name,
            calories: food.calories,
            protein: food.protein,
            carbs: food.carbs,
            fat: food.fat,
            unit: food.unit,
            servingSize: food.servingSize
        )
    }

    var foodItem: FoodItem {
        FoodItem(
            name: name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            unit: unit,
            servingSize: servingSize
        )
    }
}

struct MealPlanSlot: Identifiable {
    let id = UUID()
    let kind: MealPlanSlotKind
    let targetCalories: Double
    let targetProtein: Double
    let targetCarbs: Double
    let targetFat: Double
    let foods: [MealPlanFood]

    var totalCalories: Int {
        foods.reduce(0) { $0 + $1.calories }
    }

    var totalProtein: Double {
        foods.reduce(0) { $0 + $1.protein }
    }

    var totalCarbs: Double {
        foods.reduce(0) { $0 + $1.carbs }
    }

    var totalFat: Double {
        foods.reduce(0) { $0 + $1.fat }
    }
}
