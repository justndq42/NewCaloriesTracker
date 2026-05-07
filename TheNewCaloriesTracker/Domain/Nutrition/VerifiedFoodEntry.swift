import Foundation

enum FoodDataSource: String, Hashable {
    case nutritionReference
    case vietnameseCuratedEstimate
    case userCreated
}

enum FoodDataConfidence: String, Hashable {
    case referenceBased
    case estimated
    case userProvided
}

struct VerifiedFoodEntry: Hashable {
    let name: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let unit: String
    let servingSize: ServingSize
    let searchAliases: [String]
    let remoteSearchAliases: [String]
    let source: FoodDataSource
    let confidence: FoodDataConfidence

    init(
        name: String,
        calories: Int,
        protein: Double,
        carbs: Double,
        fat: Double,
        unit: String,
        servingSize: ServingSize = .grams(100),
        searchAliases: [String],
        remoteSearchAliases: [String],
        source: FoodDataSource,
        confidence: FoodDataConfidence
    ) {
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.unit = unit
        self.servingSize = servingSize
        self.searchAliases = searchAliases
        self.remoteSearchAliases = remoteSearchAliases
        self.source = source
        self.confidence = confidence
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

    func matches(query: String) -> Bool {
        searchableTerms.contains {
            SearchQueryNormalizer.localMatches(text: $0, query: query)
        }
    }

    func remoteAliases(for query: String) -> [String] {
        let normalizedQuery = SearchQueryNormalizer.normalized(query)
        guard !normalizedQuery.isEmpty else { return [] }

        let isExactLocalTerm = localSearchTerms.contains {
            SearchQueryNormalizer.normalized($0) == normalizedQuery
        }

        return isExactLocalTerm ? remoteSearchAliases : []
    }

    private var searchableTerms: [String] {
        localSearchTerms + remoteSearchAliases
    }

    private var localSearchTerms: [String] {
        [name] + searchAliases
    }
}
