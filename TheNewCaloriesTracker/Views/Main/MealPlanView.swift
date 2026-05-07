import SwiftUI
import SwiftData

struct MealPlanView: View {
    let profile: UserProfileModel
    @Environment(\.modelContext) private var context
    @StateObject private var vm = MealPlanViewModel()
    @State private var loggedMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.section) {
                    MealPlanGoalHeader(profile: profile)
                    MealPlanSuggestionSection(
                        profile: profile,
                        onAddFood: addSuggestedFood
                    )
                    MealPlanGenerateButton {
                        vm.generatePlan(profile: profile)
                    }
                    MealPlanContent(
                        state: vm.state,
                        onRetry: { vm.generatePlan(profile: profile) },
                        onRegenerateSlot: regenerateSlot,
                        onLogSlot: logSlot
                    )
                }
                .padding(.top, 8)
                .padding(.bottom, 92)
            }
            .appScreenBackground()
            .navigationTitle("Kế hoạch ăn")
            .overlay(alignment: .bottom) {
                if let loggedMessage {
                    Text(loggedMessage)
                        .font(.caption.bold())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.black)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .padding(.bottom, 12)
                }
            }
        }
    }

    private func regenerateSlot(_ kind: MealPlanSlotKind) {
        vm.regenerateSlot(kind, profile: profile)
    }

    private func addSuggestedFood(_ food: FoodItem, to kind: MealPlanSlotKind) {
        vm.addSuggestedFood(food, to: kind, profile: profile)
        showLoggedMessage("Đã thêm \(food.name) vào bữa \(kind.title)")
    }

    private func logSlot(_ slot: MealPlanSlot) {
        let date = Calendar.current.date(bySettingHour: slot.kind.defaultHour, minute: 0, second: 0, of: Date()) ?? Date()

        for food in slot.foods {
            let entry = DiaryEntryModel(
                foodName: food.name,
                calories: food.calories,
                protein: food.protein,
                carbs: food.carbs,
                fat: food.fat,
                unit: food.unit,
                meal: slot.kind.mealPeriod.title,
                date: date
            )
            context.insert(entry)
        }

        try? context.save()
        showLoggedMessage("Đã log bữa \(slot.kind.title)")
    }

    private func showLoggedMessage(_ message: String) {
        loggedMessage = message
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            loggedMessage = nil
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
