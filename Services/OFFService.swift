import Foundation

class OFFService {
    static let shared = OFFService()
    private init() {}

    func search(query: String) async throws -> [FoodItem] {
        let response: OFFSearchResponse = try await NetworkManager.shared.request(.searchFood(query: query))
        return response.products.compactMap { $0.toFoodItem() }
    }
}
