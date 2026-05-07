import Foundation
import Combine

enum MealPlanState {
    case idle
    case loading
    case success(DayMealPlan)
    case error(String)
}

final class MealPlanViewModel: ObservableObject {
    @Published var state: MealPlanState = .idle

    private let generator = LocalMealPlanGenerator()
    private var replacementOffsets: [String: Int] = [:]

    func generatePlan(profile: UserProfileModel) {
        replacementOffsets = [:]
        state = .success(generator.generate(profile: profile))
    }

    func regenerateSlot(_ kind: MealPlanSlotKind, profile: UserProfileModel) {
        guard case .success(let plan) = state else {
            generatePlan(profile: profile)
            return
        }

        let nextOffset = (replacementOffsets[kind.rawValue] ?? 0) + 1
        replacementOffsets[kind.rawValue] = nextOffset
        state = .success(generator.replacingSlot(kind, in: plan, profile: profile, variationOffset: nextOffset))
    }

    func addSuggestedFood(_ food: FoodItem, to kind: MealPlanSlotKind, profile: UserProfileModel) {
        let plan: DayMealPlan

        if case .success(let currentPlan) = state {
            plan = currentPlan
        } else {
            plan = generator.generate(profile: profile)
        }

        state = .success(generator.addingFood(food, to: kind, in: plan, profile: profile))
    }
}
