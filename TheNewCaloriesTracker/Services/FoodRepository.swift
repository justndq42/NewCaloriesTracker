import Foundation

final class FoodRepository {
    static let shared = FoodRepository()
    private init() {}

    private let local = LocalFoodService.shared
    private let backend = BackendFoodService.shared
    private let fatSecret = FatSecretProxyService.shared
    private let off = OFFService.shared

    var recommended: [FoodItem] {
        local.recommended
    }

    func search(query: String) async -> [FoodItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return recommended }

        let localResults = local.search(query: trimmed)
        let remoteQueries = SearchQueryNormalizer.remoteQueries(for: trimmed)

        async let backendResults = searchBackend(using: remoteQueries)
        async let fatSecretResults = searchFatSecret(using: remoteQueries)
        async let offResults = searchOFF(using: remoteQueries)

        let remoteResults = await backendResults + fatSecretResults + offResults
        return deduplicated(localResults + remoteResults)
    }

    private func searchBackend(using queries: [String]) async -> [FoodItem] {
        await firstNonEmptyResult(using: queries) { query in
            try await self.backend.search(query: query)
        }
    }

    private func searchFatSecret(using queries: [String]) async -> [FoodItem] {
        guard fatSecret.isEnabled else { return [] }
        return await firstNonEmptyResult(using: queries) { query in
            try await self.fatSecret.search(query: query)
        }
    }

    private func searchOFF(using queries: [String]) async -> [FoodItem] {
        await firstNonEmptyResult(using: queries) { query in
            try await self.off.search(query: query)
        }
    }

    private func firstNonEmptyResult(
        using queries: [String],
        search: (String) async throws -> [FoodItem]
    ) async -> [FoodItem] {
        for query in queries {
            if let results = try? await search(query), !results.isEmpty {
                return results
            }
        }

        return []
    }

    private func deduplicated(_ items: [FoodItem]) -> [FoodItem] {
        var seen = Set<String>()

        return items.filter { item in
            let key = SearchQueryNormalizer.normalized(item.name)
            guard seen.insert(key).inserted else { return false }
            return true
        }
    }
}
