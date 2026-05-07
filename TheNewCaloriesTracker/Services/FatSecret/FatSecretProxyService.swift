import Foundation

final class FatSecretProxyService {
    static let shared = FatSecretProxyService()

    private struct SearchResponse: Decodable {
        let items: [FatSecretFood]
    }

    private struct FatSecretFood: Decodable {
        let name: String
        let calories: Int
        let protein: Double
        let carbs: Double
        let fat: Double
        let unit: String
    }

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }()

    private init() {}

    private var proxyBaseURL: URL? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "FATSECRET_PROXY_BASE_URL") as? String,
              !raw.isEmpty
        else {
            return nil
        }

        return URL(string: raw)
    }

    var isEnabled: Bool {
        proxyBaseURL != nil
    }

    func search(query: String) async throws -> [FoodItem] {
        guard let proxyBaseURL else { return [] }

        var components = URLComponents(url: proxyBaseURL.appendingPathComponent("foods/search"), resolvingAgainstBaseURL: false)
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
        return payload.items.map { item in
            FoodItem(
                name: item.name,
                calories: item.calories,
                protein: item.protein,
                carbs: item.carbs,
                fat: item.fat,
                unit: item.unit
            )
        }
    }
}
