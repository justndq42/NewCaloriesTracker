import Foundation
import SwiftData
import Combine

enum SearchState {
    case idle([FoodItem])
    case loading
    case success([FoodItem])
    case error(String)
}

class FoodSearchViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchState: SearchState = .idle([])

    private let repository = FoodRepository.shared
    private var searchTask: Task<Void, Never>?

    func loadRecommended() {
        searchState = .idle(repository.recommended)
    }

    func onSearchQueryChanged() {
        searchTask?.cancel()

        let trimmed = searchQuery.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            loadRecommended()
            return
        }

        searchState = .loading

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            guard !Task.isCancelled else { return }
            let results = await repository.search(query: trimmed)
            await MainActor.run {
                guard !Task.isCancelled else { return }
                self.searchState = results.isEmpty
                    ? .error("Không tìm thấy '\(trimmed)'")
                    : .success(results)
            }
        }
    }

    @discardableResult
    func addEntry(
        food: FoodItem,
        date: Date = Date(),
        context: ModelContext,
        customFoodID: String? = nil,
        userID: String
    ) -> DiaryEntryModel {
        let entry = DiaryEntryModel(
            foodName: food.name,
            calories: food.calories,
            protein:  food.protein,
            carbs:    food.carbs,
            fat:      food.fat,
            unit:     food.unit,
            meal:     MealPeriod.from(date: date).title,
            date:     date,
            customFoodID: customFoodID,
            userID: userID
        )
        context.insert(entry)
        try? context.save()
        return entry
    }
}
