import Foundation

struct FoodItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let unit: String
}
