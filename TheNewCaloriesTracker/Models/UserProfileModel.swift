import Foundation
import SwiftData

@Model
class UserProfileModel {
    var name: String
    var gender: String
    var age: Int
    var weight: Double
    var height: Double
    var activityLevel: Int
    var goal: String          
    var isOnboardingDone: Bool
    
    init(
        name: String = "",
        gender: String = "male",
        age: Int = 25,
        weight: Double = 65,
        height: Double = 170,
        activityLevel: Int = 0,
        goal: String = "maintain",
        isOnboardingDone: Bool = false
    ) {
        self.name = name
        self.gender = gender
        self.age = age
        self.weight = weight
        self.height = height
        self.activityLevel = activityLevel
        self.goal = goal
        self.isOnboardingDone = isOnboardingDone
    }
    
    // MARK: - Computed
    var bmr: Double {
        let base = 10 * weight + 6.25 * height - 5 * Double(age)
        return gender == "male" ? base + 5 : base - 161
    }
    
    var activityMultiplier: Double {
        switch activityLevel {
        case 0: return 1.2
        case 1: return 1.375
        case 2: return 1.55
        case 3: return 1.725
        case 4: return 1.9
        default: return 1.2
        }
    }
    
    var tdee: Double { bmr * activityMultiplier }
    
    var targetCalories: Double {
        switch goal {
        case "lose": return tdee - 500
        case "gain": return tdee + 500
        default:     return tdee
        }
    }
    

    var proteinGrams: Double {
        switch goal {
        case "gain":    return weight * 2.2
        case "maintain": return weight * 1.6
        default:        return weight * 1.2
        }
    }

    var fatGrams: Double {
        // 25% từ TDEE
        return (tdee * 0.15) / 9
    }

    var carbsGrams: Double {
        let proteinCal = proteinGrams * 4
        let fatCal     = fatGrams * 9
        let remaining  = targetCalories - proteinCal - fatCal
        return max(0, remaining / 4)
    }

    // MARK: - 3 mức protein
    var highProteinGrams: Double  { weight * 2.2 }
    var medProteinGrams: Double   { weight * 1.6 }
    var lowProteinGrams: Double   { weight * 1.2 }

    func carbsForProtein(_ proteinG: Double) -> Double {
        let proteinCal = proteinG * 4
        let fatCal     = fatGrams * 9
        let remaining  = targetCalories - proteinCal - fatCal
        return max(0, remaining / 4)
    }
    
    // MARK: - Helpers
    static let activityLabels = [
        "≤3 buổi/tuần",
        "3–4 buổi/tuần",
        "4–5 buổi/tuần",
        "6–7 buổi/tuần",
        ">7 buổi/tuần"
    ]

    static let activityDescriptions = [
        "Ít vận động, chủ yếu ngồi",
        "Tập nhẹ vài buổi/tuần",
        "Tập đều đặn 4-5 buổi",
        "Tập cường độ cao 6-7 buổi",
        "VĐV, lao động nặng hàng ngày"
    ]
}
