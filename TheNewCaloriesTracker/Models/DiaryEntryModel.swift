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
    var updatedAt: Date
    var lastSyncedAt: Date?
    var clientID: String?
    var customFoodID: String?
    var remoteID: String?
    var userID: String?
    
    init(
        foodName: String,
        calories: Int,
        protein: Double,
        carbs: Double,
        fat: Double,
        unit: String,
        meal: String,
        date: Date = Date(),
        updatedAt: Date = Date(),
        lastSyncedAt: Date? = nil,
        clientID: String = UUID().uuidString,
        customFoodID: String? = nil,
        remoteID: String? = nil,
        userID: String? = nil
    ) {
        self.foodName = foodName
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.unit = unit
        self.meal = meal
        self.date = date
        self.updatedAt = updatedAt
        self.lastSyncedAt = lastSyncedAt
        self.clientID = clientID
        self.customFoodID = customFoodID
        self.remoteID = remoteID
        self.userID = userID
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

    func resolvedClientID() -> String {
        if let clientID {
            return clientID
        }

        let newID = UUID().uuidString
        self.clientID = newID
        return newID
    }

    func markLocallyUpdated(at date: Date = Date()) {
        updatedAt = date
    }

    var hasUnsyncedChanges: Bool {
        guard let lastSyncedAt else {
            return true
        }

        return updatedAt > lastSyncedAt
    }
}
