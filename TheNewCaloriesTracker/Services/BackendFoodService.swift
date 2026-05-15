import Foundation

final class BackendFoodService {
    static let shared = BackendFoodService()

    private struct SearchResponse: Decodable {
        let items: [BackendFoodItem]
    }

    private struct BackendFoodItem: Decodable {
        let name: String
        let calories: Int
        let protein: Double
        let carbs: Double
        let fat: Double
        let unit: String

        var foodItem: FoodItem {
            FoodItem(
                name: name,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                unit: unit
            )
        }
    }

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }()

    private init() {}

    private var baseURL: URL {
        BackendAPIConfiguration.baseURL
    }

    func search(query: String) async throws -> [FoodItem] {
        var components = URLComponents(url: baseURL.appendingPathComponent("foods/search"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "query", value: query)
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        let payload = try JSONDecoder().decode(SearchResponse.self, from: data)
        return payload.items.map(\.foodItem)
    }
}
