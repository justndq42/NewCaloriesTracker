import Foundation

enum BackendAPIConfiguration {
    private static let productionBaseURL = URL(string: "https://new-calories-food-api.onrender.com")!

    static var baseURL: URL {
        if let raw = Bundle.main.object(forInfoDictionaryKey: "FOOD_API_BASE_URL") as? String,
           let url = URL(string: raw),
           !raw.isEmpty {
            return url
        }

        return productionBaseURL
    }
}
