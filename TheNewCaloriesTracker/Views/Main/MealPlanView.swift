import SwiftUI

struct MealPlanView: View {
    let profile: UserProfileModel
    @StateObject private var vm = MealPlanViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    MealPlanGoalHeader(profile: profile)
                    MealPlanGuideSection(goal: profile.goal)
                    MealPlanGenerateButton {
                        vm.generatePlan(profile: profile)
                    }
                    MealPlanContent(
                        state: vm.state,
                        onRetry: { vm.generatePlan(profile: profile) }
                    )
                }
                .padding(.top)
            }
            .background(Color.gray.opacity(0.07))
            .navigationTitle("Kế hoạch ăn")
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
