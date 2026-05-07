import Foundation

enum VietnameseFoodCatalog {
    static var coreVerified: [VerifiedFoodEntry] {
        CoreVerifiedFoodCatalog.entries
    }

    static var vietnameseMeals: [VerifiedFoodEntry] {
        VietnameseMealsCatalog.entries
    }

    static var entries: [VerifiedFoodEntry] {
        coreVerified + vietnameseMeals
    }

    static var recommended: [FoodItem] {
        entries.map(\.foodItem)
    }

    static func search(query: String) -> [FoodItem] {
        entries
            .filter { $0.matches(query: query) }
            .map(\.foodItem)
    }

    static func remoteAliases(for query: String) -> [String] {
        entries.flatMap {
            $0.remoteAliases(for: query)
        }
    }
}
