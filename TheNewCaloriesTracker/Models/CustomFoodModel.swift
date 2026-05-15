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
    var updatedAt: Date
    var lastSyncedAt: Date?
    var customFoodID: String?
    var remoteID: String?
    var userID: String?

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
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastSyncedAt: Date? = nil,
        customFoodID: String = UUID().uuidString,
        remoteID: String? = nil,
        userID: String? = nil
    ) {
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.unit = unit
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastSyncedAt = lastSyncedAt
        self.customFoodID = customFoodID
        self.remoteID = remoteID
        self.userID = userID
    }

    func resolvedCustomFoodID() -> String {
        if let customFoodID {
            return customFoodID
        }

        let newID = UUID().uuidString
        self.customFoodID = newID
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
