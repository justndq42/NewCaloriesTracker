import Foundation
import SwiftData

@Observable
class OnboardingViewModel {
    var gender: String = "male"
    var age: Int = 22
    var weight: Double = 60
    var height: Double = 165
    var activityLevel: Int = 0
    var goal: String = "maintain"
    var currentStep: Int = 1

    private var nutritionProfile: NutritionProfile {
        NutritionProfile(
            input: NutritionProfileInput(
                gender: gender,
                age: age,
                weight: weight,
                targetWeight: UserProfileModel.defaultTargetWeight(for: goal, currentWeight: weight),
                height: height,
                activityLevel: ActivityLevelOption(rawValue: activityLevel) ?? .sedentary,
                goal: NutritionGoal(rawValue: goal) ?? .maintain,
                macroDistribution: nil
            )
        )
    }

    var bmr: Double { nutritionProfile.bmr }
    var tdee: Double { nutritionProfile.tdee }
    var targetCalories: Double { nutritionProfile.targetCalories }
    
    func saveProfile(userID: String, displayName: String, context: ModelContext) -> UserProfileModel {
        let profile = UserProfileModel(
            userID: userID,
            name: displayName,
            gender: gender,
            age: age,
            weight: weight,
            height: height,
            activityLevel: activityLevel,
            goal: goal,
            isOnboardingDone: true
        )
        context.insert(profile)
        try? context.save()

        return profile
    }
}
