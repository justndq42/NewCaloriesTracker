import SwiftUI
import SwiftData

struct TDEEView: View {
    @Bindable var profile: UserProfileModel
    @Environment(\.modelContext) private var context

    private var nutrition: NutritionProfile {
        NutritionProfile(profile: profile)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    TDEEGenderSection(profile: profile)
                    TDEESlidersSection(profile: profile)
                    TDEEActivitySection(profile: profile)
                    TDEEGoalSection(profile: profile)
                    TDEEResultSection(nutrition: nutrition)
                    TDEEMacroSection(nutrition: nutrition, goal: profile.goal)
                }
                .padding()
            }
            .navigationTitle("Chỉ số TDEE")
            .background(Color.gray.opacity(0.07))
            .onChange(of: profile.gender) { try? context.save() }
            .onChange(of: profile.age) { try? context.save() }
            .onChange(of: profile.weight) { try? context.save() }
            .onChange(of: profile.height) { try? context.save() }
            .onChange(of: profile.activityLevel) { try? context.save() }
            .onChange(of: profile.goal) { try? context.save() }
        }
    }
}
