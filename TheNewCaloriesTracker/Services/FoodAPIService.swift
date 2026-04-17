import Foundation

// MARK: - Models
struct SpoonacularSearchResponse: Codable {
    let results: [SpoonacularResult]
    let totalResults: Int
}

struct SpoonacularResult: Codable, Identifiable {
    let id: Int
    let title: String
}

struct SpoonacularRecipeInfo: Codable {
    let id: Int
    let title: String
    let servings: Int?
    let nutrition: SpoonacularNutritionWrapper?
}

struct SpoonacularNutritionWrapper: Codable {
    let nutrients: [SpoonacularNutrient]

    func value(for name: String) -> Double {
        nutrients.first {
            $0.name.lowercased().contains(name.lowercased())
        }?.amount ?? 0
    }
}

struct SpoonacularNutrient: Codable {
    let name: String
    let amount: Double
    let unit: String
}

struct SpoonacularBulkInfo: Codable {
    let id: Int
    let title: String
    let servings: Int?
    let nutrition: SpoonacularNutritionWrapper?
}

// MARK: - Meal Plan
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

// MARK: - API Service
class FoodAPIService {
    static let shared = FoodAPIService()
    private init() {}

    private let apiKey = "40fb1118a4714ca296a1c7b42a6f7cfb"
    private let base = "https://api.spoonacular.com"

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }()

    // MARK: - Step 1: Search recipe IDs
    private func searchRecipeIds(query: String, number: Int = 10) async throws -> [Int] {
        var c = URLComponents(string: "\(base)/recipes/complexSearch")!
        c.queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "query",  value: query),
            URLQueryItem(name: "number", value: "\(number)"),
        ]
        guard let url = c.url else { throw URLError(.badURL) }
        print("Search: \(url)")

        let (data, resp) = try await session.data(from: url)
        if let http = resp as? HTTPURLResponse {
            print("Status: \(http.statusCode)")
            if http.statusCode != 200 {
                let body = String(data: data, encoding: .utf8) ?? ""
                print("\(body)")
                throw URLError(.badServerResponse)
            }
        }
        let decoded = try JSONDecoder().decode(SpoonacularSearchResponse.self, from: data)
        print("📦 Found \(decoded.results.count) recipes")
        return decoded.results.map { $0.id }
    }

    // MARK: - Step 2: Bulk fetch nutrition by IDs
    private func fetchNutrition(ids: [Int]) async throws -> [FoodItem] {
        guard !ids.isEmpty else { return [] }
        let idString = ids.map { "\($0)" }.joined(separator: ",")

        var c = URLComponents(string: "\(base)/recipes/informationBulk")!
        c.queryItems = [
            URLQueryItem(name: "apiKey",          value: apiKey),
            URLQueryItem(name: "ids",             value: idString),
            URLQueryItem(name: "includeNutrition",value: "true"),
        ]
        guard let url = c.url else { throw URLError(.badURL) }
        print("🥗 Bulk nutrition: \(ids.count) recipes")

        let (data, resp) = try await session.data(from: url)
        if let http = resp as? HTTPURLResponse {
            print(" Nutrition status: \(http.statusCode)")
            if http.statusCode != 200 {
                let body = String(data: data, encoding: .utf8) ?? ""
                print(" \(body)")
                throw URLError(.badServerResponse)
            }
        }

        let decoded = try JSONDecoder().decode([SpoonacularBulkInfo].self, from: data)

        return decoded.compactMap { recipe -> FoodItem? in
            guard let nutrition = recipe.nutrition else { return nil }
            let cal = nutrition.value(for: "Calories")
            guard cal > 0 else { return nil }
            return FoodItem(
                name: recipe.title,
                calories: Int(cal),
                protein: nutrition.value(for: "Protein"),
                carbs: nutrition.value(for: "Carbohydrates"),
                fat: nutrition.value(for: "Fat"),
                unit: "1 serving"
            )
        }
    }

    // MARK: - Public: Search food
    func searchFood(query: String) async throws -> [FoodItem] {
        let ids = try await searchRecipeIds(query: query, number: 15)
        guard !ids.isEmpty else { return [] }
        let items = try await fetchNutrition(ids: ids)
        print("Valid items: \(items.count)")
        return items
    }

    // MARK: - Public: Load recommended
    func loadRecommended() async throws -> [FoodItem] {
        let queries: [(String, Int)] = [
            ("banh mi vietnamese",  3),
            ("pho vietnamese soup", 3),
            ("vietnamese rice",     3),
            ("spring rolls",        3),
            ("chicken rice",        3),
        ]

        var allIds: [Int] = []
        for (query, num) in queries {
            if let ids = try? await searchRecipeIds(query: query, number: num) {
                allIds.append(contentsOf: ids)
            }
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s delay
        }

        guard !allIds.isEmpty else { return [] }

        // Fetch nutrition cho tất cả IDs cùng lúc
        let items = try await fetchNutrition(ids: Array(allIds.prefix(15)))
        print("⭐ Recommended: \(items.count) items")
        return items
    }

    // MARK: - Meal Plan
    func generateMealPlan(
        targetCalories: Int,
        goal: String,
        diet: String = ""
    ) async throws -> MealPlanResponse {
        var c = URLComponents(string: "\(base)/mealplanner/generate")!
        var items: [URLQueryItem] = [
            URLQueryItem(name: "apiKey",         value: apiKey),
            URLQueryItem(name: "timeFrame",      value: "day"),
            URLQueryItem(name: "targetCalories", value: "\(targetCalories)"),
        ]
        if !diet.isEmpty {
            items.append(URLQueryItem(name: "diet", value: diet))
        }
        c.queryItems = items

        guard let url = c.url else { throw URLError(.badURL) }
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(MealPlanResponse.self, from: data)
    }
}
