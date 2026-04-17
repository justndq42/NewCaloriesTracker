import Foundation

struct DayMealPlan: Identifiable {
    let id = UUID()
    let meals: [MealPlanItem]
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    let goal: String
    let targetCalories: Int
}
