import Foundation

class FoodRepository {
    static let shared = FoodRepository()
    private init() {}

    private let local = LocalFoodService.shared
    private let remote = OFFService.shared

    var recommended: [FoodItem] {
        local.recommended
    }

    func search(query: String) async -> [FoodItem] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return recommended }

        async let localResults = local.search(query: trimmed)
        async let remoteResults = (try? remote.search(query: trimmed)) ?? []

        let (local, remote) = await (localResults, remoteResults)

        // Local lên đầu, loại trùng từ remote
        let localNames = Set(local.map { $0.name.lowercased() })
        let uniqueRemote = remote.filter { !localNames.contains($0.name.lowercased()) }

        return local + uniqueRemote
    }
}
