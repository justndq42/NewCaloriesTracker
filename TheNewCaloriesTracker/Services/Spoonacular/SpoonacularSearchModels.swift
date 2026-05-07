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

    func value(for nutrientName: SpoonacularNutrientName) -> Double {
        nutrients.first {
            nutrientName.matches($0.name)
        }?.amount ?? 0
    }
}

enum SpoonacularNutrientName {
    case calories
    case protein
    case carbohydrates
    case fat

    func matches(_ apiName: String) -> Bool {
        apiName.localizedCaseInsensitiveContains(apiLabel)
    }

    private var apiLabel: String {
        switch self {
        case .calories:
            return "Calories"
        case .protein:
            return "Protein"
        case .carbohydrates:
            return "Carbohydrates"
        case .fat:
            return "Fat"
        }
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
