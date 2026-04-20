import Foundation

struct MealPlanResponse: Codable {
    let meals: [MealPlanItem]
    let nutrients: MealPlanNutrients
}

struct MealPlanItem: Codable, Identifiable {
    let id: Int
    let title: String
    let readyInMinutes: Int
    let servings: Int
    let sourceUrl: String?
    let imageType: String?

    var imageURL: String {
        "https://spoonacular.com/recipeImages/\(id)-312x231.\(imageType ?? "jpg")"
    }
}

struct MealPlanNutrients: Codable {
    let calories: Double
    let protein: Double
    let fat: Double
    let carbohydrates: Double
}

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
