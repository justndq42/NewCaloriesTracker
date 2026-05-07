import Foundation

struct FoodItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let unit: String
    let servingSize: ServingSize?

    init(
        name: String,
        calories: Int,
        protein: Double,
        carbs: Double,
        fat: Double,
        unit: String,
        servingSize: ServingSize? = nil
    ) {
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.unit = unit
        self.servingSize = servingSize
    }
}

extension FoodItem {
    func scaledForPortions(_ portionCount: Double) -> FoodItem {
        let safePortionCount = max(0.1, portionCount)

        return FoodItem(
            name: name,
            calories: Int((Double(calories) * safePortionCount).rounded()),
            protein: protein * safePortionCount,
            carbs: carbs * safePortionCount,
            fat: fat * safePortionCount,
            unit: portionUnitDescription(for: safePortionCount)
        )
    }

    func portionUnitDescription(for portionCount: Double) -> String {
        let safePortionCount = max(0.1, portionCount)

        guard let servingSize else {
            return "\(formattedPortionCount(safePortionCount)) khẩu phần (\(unit))"
        }

        return "\(formattedPortionCount(safePortionCount)) khẩu phần (\(servingSize.scaledDescription(by: safePortionCount)))"
    }

    func formattedPortionCount(_ value: Double) -> String {
        value.rounded() == value
            ? String(Int(value))
            : String(format: "%.1f", value)
    }
}

struct ServingSize: Hashable {
    let value: Double
    let unit: ServingUnit

    static func grams(_ value: Double) -> ServingSize {
        ServingSize(value: value, unit: .grams)
    }

    static func milliliters(_ value: Double) -> ServingSize {
        ServingSize(value: value, unit: .milliliters)
    }

    func scaledDescription(by multiplier: Double) -> String {
        "\(formatted(value * max(0.1, multiplier)))\(unit.symbol)"
    }

    private func formatted(_ value: Double) -> String {
        value.rounded() == value
            ? String(Int(value))
            : String(format: "%.1f", value)
    }
}

enum ServingUnit: Hashable {
    case grams
    case milliliters

    var symbol: String {
        switch self {
        case .grams:
            return "g"
        case .milliliters:
            return "ml"
        }
    }
}
