import Foundation
import SwiftData

@Model
class UserProfileModel {
    var name: String
    var joinedAt: Date = Date()
    var gender: String
    var age: Int
    var weight: Double
    var weightUpdatedAt: Date?
    var targetWeight: Double = 65
    var height: Double
    var activityLevel: Int
    var goal: String          
    var proteinMacroPercent: Double = 30
    var carbsMacroPercent: Double = 40
    var fatMacroPercent: Double = 30
    var isOnboardingDone: Bool
    
    init(
        name: String = "",
        joinedAt: Date = Date(),
        gender: String = "male",
        age: Int = 25,
        weight: Double = 65,
        weightUpdatedAt: Date? = nil,
        targetWeight: Double? = nil,
        height: Double = 170,
        activityLevel: Int = 0,
        goal: String = "maintain",
        proteinMacroPercent: Double? = nil,
        carbsMacroPercent: Double? = nil,
        fatMacroPercent: Double? = nil,
        isOnboardingDone: Bool = false
    ) {
        let defaultMacro = MacroDistribution.default(for: NutritionGoal(rawValue: goal) ?? .maintain)

        self.name = name
        self.joinedAt = joinedAt
        self.gender = gender
        self.age = age
        self.weight = weight
        self.weightUpdatedAt = weightUpdatedAt
        self.targetWeight = targetWeight ?? Self.defaultTargetWeight(for: goal, currentWeight: weight)
        self.height = height
        self.activityLevel = activityLevel
        self.goal = goal
        self.proteinMacroPercent = proteinMacroPercent ?? defaultMacro.proteinPercent
        self.carbsMacroPercent = carbsMacroPercent ?? defaultMacro.carbsPercent
        self.fatMacroPercent = fatMacroPercent ?? defaultMacro.fatPercent
        self.isOnboardingDone = isOnboardingDone
    }
}

extension UserProfileModel {
    var nutritionGoal: NutritionGoal {
        NutritionGoal(rawValue: goal) ?? .maintain
    }

    var macroDistribution: MacroDistribution {
        get {
            MacroDistribution(
                proteinPercent: proteinMacroPercent,
                carbsPercent: carbsMacroPercent,
                fatPercent: fatMacroPercent
            )
        }
        set {
            proteinMacroPercent = newValue.proteinPercent
            carbsMacroPercent = newValue.carbsPercent
            fatMacroPercent = newValue.fatPercent
        }
    }

    func applyDefaultMacroDistribution() {
        macroDistribution = .default(for: nutritionGoal)
    }

    func updateMacroPercent(_ macro: MacroKind, to value: Double) {
        macroDistribution = macroDistribution.updating(macro, to: value)
    }

    static func defaultTargetWeight(for goal: String, currentWeight: Double) -> Double {
        switch NutritionGoal(rawValue: goal) ?? .maintain {
        case .lose:
            return max(currentWeight - 5, 20)
        case .maintain:
            return currentWeight
        case .gain:
            return min(currentWeight + 5, 300)
        }
    }
}
