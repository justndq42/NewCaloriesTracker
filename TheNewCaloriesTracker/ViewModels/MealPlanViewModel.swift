import Foundation
import Combine

enum MealPlanState {
    case idle
    case loading
    case success(DayMealPlan)
    case error(String)
}

class MealPlanViewModel: ObservableObject {
    @Published var state: MealPlanState = .idle

    func generatePlan(profile: UserProfileModel) {
        Task { @MainActor in
            state = .loading
            do {
                let response = try await FoodAPIService.shared.generateMealPlan(
                    targetCalories: Int(profile.targetCalories),
                    goal: profile.goal
                )
                state = .success(DayMealPlan(
                    meals: response.meals,
                    totalCalories: response.nutrients.calories,
                    totalProtein: response.nutrients.protein,
                    totalCarbs: response.nutrients.carbohydrates,
                    totalFat: response.nutrients.fat,
                    goal: profile.goal,                          
                    targetCalories: Int(profile.targetCalories)
                ))
            } catch {
                state = .error("Không thể tạo kế hoạch. Thử lại sau.")
            }
        }
    }
}
