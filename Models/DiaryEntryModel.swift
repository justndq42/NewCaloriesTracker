import Foundation
import SwiftData

@Model
class DiaryEntryModel {
    var foodName: String
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var unit: String
    var meal: String
    var date: Date
    
    init(
        foodName: String,
        calories: Int,
        protein: Double,
        carbs: Double,
        fat: Double,
        unit: String,
        meal: String,
        date: Date = Date()
    ) {
        self.foodName = foodName
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.unit = unit
        self.meal = meal
        self.date = date
    }
    
    var mealIcon: String {
        switch meal {
        case "Sáng":  return "☀️"
        case "Trưa":  return "🌤️"
        case "Snack": return "🍎"
        case "Tối":   return "🌙"
        default:      return "🍽️"
        }
    }
}
