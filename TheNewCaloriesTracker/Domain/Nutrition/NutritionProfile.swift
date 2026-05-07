import Foundation

enum NutritionGoal: String, CaseIterable, Identifiable {
    case lose
    case maintain
    case gain

    var id: String { rawValue }

    var calorieAdjustment: Double {
        switch self {
        case .lose:
            return -500
        case .maintain:
            return 0
        case .gain:
            return 500
        }
    }

    var title: String {
        switch self {
        case .lose:
            return "Giảm cân"
        case .maintain:
            return "Duy trì"
        case .gain:
            return "Tăng cân"
        }
    }

    var shortTitle: String {
        switch self {
        case .lose:
            return "Giảm"
        case .maintain:
            return "Duy trì"
        case .gain:
            return "Tăng"
        }
    }

    var symbolName: String {
        switch self {
        case .lose:
            return "arrow.down.forward.circle.fill"
        case .maintain:
            return "equal.circle.fill"
        case .gain:
            return "arrow.up.forward.circle.fill"
        }
    }
}

enum ActivityLevelOption: Int, CaseIterable, Identifiable {
    case sedentary
    case light
    case moderate
    case active
    case athlete

    var id: Int { rawValue }

    var multiplier: Double {
        switch self {
        case .sedentary:
            return 1.2
        case .light:
            return 1.375
        case .moderate:
            return 1.55
        case .active:
            return 1.725
        case .athlete:
            return 1.9
        }
    }

    var label: String {
        switch self {
        case .sedentary:
            return "≤3 buổi/tuần"
        case .light:
            return "3–4 buổi/tuần"
        case .moderate:
            return "4–5 buổi/tuần"
        case .active:
            return "6–7 buổi/tuần"
        case .athlete:
            return ">7 buổi/tuần"
        }
    }

    var description: String {
        switch self {
        case .sedentary:
            return "Ít vận động, chủ yếu ngồi"
        case .light:
            return "Tập nhẹ vài buổi/tuần"
        case .moderate:
            return "Tập đều đặn 4-5 buổi"
        case .active:
            return "Tập cường độ cao 6-7 buổi"
        case .athlete:
            return "VĐV, lao động nặng hàng ngày"
        }
    }

    var shortTitle: String {
        switch self {
        case .sedentary:
            return "Ít vận động"
        case .light:
            return "Nhẹ"
        case .moderate:
            return "Vừa"
        case .active:
            return "Cao"
        case .athlete:
            return "Rất cao"
        }
    }

    var shortDescription: String {
        switch self {
        case .sedentary:
            return "Ngồi văn phòng, ít đi lại"
        case .light:
            return "Tập 1–3 ngày/tuần"
        case .moderate:
            return "Tập 3–5 ngày/tuần"
        case .active:
            return "Tập 6–7 ngày/tuần"
        case .athlete:
            return "VĐV, lao động nặng"
        }
    }

    var symbolName: String {
        switch self {
        case .sedentary:
            return "chair.fill"
        case .light:
            return "figure.walk"
        case .moderate:
            return "figure.run"
        case .active:
            return "figure.highintensity.intervaltraining"
        case .athlete:
            return "figure.strengthtraining.traditional"
        }
    }
}

struct NutritionProfileInput {
    let gender: String
    let age: Int
    let weight: Double
    let targetWeight: Double
    let height: Double
    let activityLevel: ActivityLevelOption
    let goal: NutritionGoal
    let macroDistribution: MacroDistribution?
}

struct NutritionProfile {
    let bmr: Double
    let tdee: Double
    let targetCalories: Double
    let targetWeight: Double
    let macroDistribution: MacroDistribution
    let proteinGrams: Double
    let fatGrams: Double
    let carbsGrams: Double

    init(input: NutritionProfileInput) {
        let base = 10 * input.weight + 6.25 * input.height - 5 * Double(input.age)
        let bmr = input.gender == "male" ? base + 5 : base - 161
        let tdee = bmr * input.activityLevel.multiplier
        let targetCalories = tdee + input.goal.calorieAdjustment
        let defaultDistribution = MacroDistribution.default(for: input.goal)
        let macroDistribution = (input.macroDistribution ?? defaultDistribution)
            .validated(fallback: defaultDistribution)
        let macroTargets = macroDistribution.targets(for: targetCalories)

        self.bmr = bmr
        self.tdee = tdee
        self.targetCalories = targetCalories
        self.targetWeight = input.targetWeight
        self.macroDistribution = macroDistribution
        self.proteinGrams = macroTargets.proteinGrams
        self.fatGrams = macroTargets.fatGrams
        self.carbsGrams = macroTargets.carbsGrams
    }

    init(profile: UserProfileModel) {
        self.init(
            input: NutritionProfileInput(
                gender: profile.gender,
                age: profile.age,
                weight: profile.weight,
                targetWeight: profile.targetWeight,
                height: profile.height,
                activityLevel: ActivityLevelOption(rawValue: profile.activityLevel) ?? .sedentary,
                goal: profile.nutritionGoal,
                macroDistribution: profile.macroDistribution
            )
        )
    }
}
