import Foundation

final class SpoonacularClient {
    private let apiKey = "40fb1118a4714ca296a1c7b42a6f7cfb"
    private let baseURL = "https://api.spoonacular.com"

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }()

    func searchFood(query: String) async throws -> [FoodItem] {
        let ids = try await searchRecipeIDs(query: query, number: 15)
        guard !ids.isEmpty else { return [] }
        return try await fetchNutrition(for: ids)
    }

    func loadRecommended() async throws -> [FoodItem] {
        let queries: [(String, Int)] = [
            ("banh mi vietnamese", 3),
            ("pho vietnamese soup", 3),
            ("vietnamese rice", 3),
            ("spring rolls", 3),
            ("chicken rice", 3),
        ]

        var allIDs: [Int] = []
        for (query, number) in queries {
            if let ids = try? await searchRecipeIDs(query: query, number: number) {
                allIDs.append(contentsOf: ids)
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
        }

        guard !allIDs.isEmpty else { return [] }
        return try await fetchNutrition(for: Array(allIDs.prefix(15)))
    }

    func generateMealPlan(
        targetCalories: Int,
        goal: String,
        diet: String = ""
    ) async throws -> MealPlanResponse {
        var components = URLComponents(string: "\(baseURL)/mealplanner/generate")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "timeFrame", value: "day"),
            URLQueryItem(name: "targetCalories", value: "\(targetCalories)"),
        ]

        if !diet.isEmpty {
            queryItems.append(URLQueryItem(name: "diet", value: diet))
        }

        components.queryItems = queryItems
        return try await request(components: components, as: MealPlanResponse.self)
    }

    private func searchRecipeIDs(query: String, number: Int) async throws -> [Int] {
        var components = URLComponents(string: "\(baseURL)/recipes/complexSearch")!
        components.queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "number", value: "\(number)"),
        ]

        let response = try await request(components: components, as: SpoonacularSearchResponse.self)
        return response.results.map(\.id)
    }

    private func fetchNutrition(for ids: [Int]) async throws -> [FoodItem] {
        guard !ids.isEmpty else { return [] }

        var components = URLComponents(string: "\(baseURL)/recipes/informationBulk")!
        components.queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "ids", value: ids.map(String.init).joined(separator: ",")),
            URLQueryItem(name: "includeNutrition", value: "true"),
        ]

        let recipes = try await request(components: components, as: [SpoonacularBulkInfo].self)
        return recipes.compactMap { recipe in
            guard let nutrition = recipe.nutrition else { return nil }
            let calories = nutrition.value(for: "Calories")
            guard calories > 0 else { return nil }

            return FoodItem(
                name: recipe.title,
                calories: Int(calories),
                protein: nutrition.value(for: "Protein"),
                carbs: nutrition.value(for: "Carbohydrates"),
                fat: nutrition.value(for: "Fat"),
                unit: "1 serving"
            )
        }
    }

    private func request<Response: Decodable>(
        components: URLComponents,
        as type: Response.Type
    ) async throws -> Response {
        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(Response.self, from: data)
    }
}
