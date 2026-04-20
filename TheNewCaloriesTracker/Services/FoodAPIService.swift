import Foundation

final class FoodAPIService {
    static let shared = FoodAPIService()

    private let client: SpoonacularClient

    private init(client: SpoonacularClient = SpoonacularClient()) {
        self.client = client
    }

    func searchFood(query: String) async throws -> [FoodItem] {
        try await client.searchFood(query: query)
    }

    func loadRecommended() async throws -> [FoodItem] {
        try await client.loadRecommended()
    }

    func generateMealPlan(
        targetCalories: Int,
        goal: String,
        diet: String = ""
    ) async throws -> MealPlanResponse {
        try await client.generateMealPlan(
            targetCalories: targetCalories,
            goal: goal,
            diet: diet
        )
    }
}
