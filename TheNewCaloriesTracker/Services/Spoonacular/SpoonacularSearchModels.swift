import Foundation

struct SpoonacularSearchResponse: Codable {
    let results: [SpoonacularResult]
    let totalResults: Int
}

struct SpoonacularResult: Codable, Identifiable {
    let id: Int
    let title: String
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
