import Foundation

enum MacroKind {
    case protein
    case carbs
    case fat
}

struct MacroTargets {
    let proteinGrams: Double
    let carbsGrams: Double
    let fatGrams: Double
}

struct MacroDistribution: Equatable {
    static let minimumPercent = 0.0
    static let maximumPercent = 100.0

    let proteinPercent: Double
    let carbsPercent: Double
    let fatPercent: Double

    static func `default`(for goal: NutritionGoal) -> MacroDistribution {
        switch goal {
        case .lose:
            return MacroDistribution(proteinPercent: 30, carbsPercent: 45, fatPercent: 25)
        case .maintain:
            return MacroDistribution(proteinPercent: 30, carbsPercent: 40, fatPercent: 30)
        case .gain:
            return MacroDistribution(proteinPercent: 30, carbsPercent: 50, fatPercent: 20)
        }
    }

    var totalPercent: Double {
        proteinPercent + carbsPercent + fatPercent
    }

    var isValid: Bool {
        abs(totalPercent - 100) < 0.5
    }

    func targets(for calories: Double) -> MacroTargets {
        MacroTargets(
            proteinGrams: calories * proteinPercent / 100 / 4,
            carbsGrams: calories * carbsPercent / 100 / 4,
            fatGrams: calories * fatPercent / 100 / 9
        )
    }

    func validated(fallback: MacroDistribution) -> MacroDistribution {
        isValid ? self : fallback
    }

    func updating(_ macro: MacroKind, to rawValue: Double) -> MacroDistribution {
        let value = min(max(rawValue.rounded(), Self.minimumPercent), Self.maximumPercent)

        switch macro {
        case .protein:
            return MacroDistribution(proteinPercent: value, carbsPercent: carbsPercent, fatPercent: fatPercent)
        case .carbs:
            return MacroDistribution(proteinPercent: proteinPercent, carbsPercent: value, fatPercent: fatPercent)
        case .fat:
            return MacroDistribution(proteinPercent: proteinPercent, carbsPercent: carbsPercent, fatPercent: value)
        }
    }
}
