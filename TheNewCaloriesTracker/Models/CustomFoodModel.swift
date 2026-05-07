import Foundation
import SwiftData

@Model
final class CustomFoodModel {
    var name: String
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var unit: String
    var createdAt: Date

    var foodItem: FoodItem {
        FoodItem(
            name: name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            unit: unit
        )
    }

    init(
        name: String,
        calories: Int,
        protein: Double,
        carbs: Double,
        fat: Double,
        unit: String,
        createdAt: Date = Date()
    ) {
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.unit = unit
        self.createdAt = createdAt
    }
}
