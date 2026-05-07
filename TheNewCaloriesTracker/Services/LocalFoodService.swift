import Foundation

final class LocalFoodService {
    static let shared = LocalFoodService()

    let recommended: [FoodItem]

    private let catalog: [VerifiedFoodEntry]

    private init(catalog: [VerifiedFoodEntry] = VietnameseFoodCatalog.entries) {
        self.catalog = catalog
        recommended = catalog.map(\.foodItem)
    }

    func search(query: String) -> [FoodItem] {
        catalog
            .filter { $0.matches(query: query) }
            .map(\.foodItem)
    }
}
