import Foundation
import SwiftData

@Model
class UserProfileModel {
    var name: String
    var gender: String
    var age: Int
    var weight: Double
    var weightUpdatedAt: Date?
    var height: Double
    var activityLevel: Int
    var goal: String          
    var isOnboardingDone: Bool
    
    init(
        name: String = "",
        gender: String = "male",
        age: Int = 25,
        weight: Double = 65,
        weightUpdatedAt: Date? = nil,
        height: Double = 170,
        activityLevel: Int = 0,
        goal: String = "maintain",
        isOnboardingDone: Bool = false
    ) {
        self.name = name
        self.gender = gender
        self.age = age
        self.weight = weight
        self.weightUpdatedAt = weightUpdatedAt
        self.height = height
        self.activityLevel = activityLevel
        self.goal = goal
        self.isOnboardingDone = isOnboardingDone
    }
}
