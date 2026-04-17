import Foundation
import SwiftData

@Observable
class OnboardingViewModel {
    var name: String = ""
    var gender: String = "male"
    var age: Int = 22
    var weight: Double = 60
    var height: Double = 165
    var activityLevel: Int = 0
    var goal: String = "maintain"
    var currentStep: Int = 1
    
    var isStep1Valid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }
    
    var bmr: Double {
        let base = 10 * weight + 6.25 * height - 5 * Double(age)
        return gender == "male" ? base + 5 : base - 161
    }
    private let activityMultipliers = [1.2, 1.375, 1.55, 1.725, 1.9]

    var tdee: Double { bmr * activityMultipliers[activityLevel] }
    var targetCalories: Double {
        switch goal {
        case "lose":  return tdee - 500
        case "gain":  return tdee + 500
        default:      return tdee
        }
    }
    
    func saveProfile(context: ModelContext) {
        let profile = UserProfileModel(
            name: name,
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
    }
}
