import Foundation

struct OFFNutriments: Codable {
    let energyKcal: Double?
    let protein: Double?
    let carbs: Double?
    let fat: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal = "energy-kcal_100g"
        case protein    = "proteins_100g"
        case carbs      = "carbohydrates_100g"
        case fat        = "fat_100g"
    }
}
