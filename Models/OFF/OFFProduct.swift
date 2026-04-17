import Foundation

struct OFFProduct: Codable {
    let productName: String?
    let productNameEn: String?
    let nutriments: OFFNutriments?
    let servingSize: String?
    let quantity: String?

    enum CodingKeys: String, CodingKey {
        case productName    = "product_name"
        case productNameEn  = "product_name_en"
        case nutriments
        case servingSize    = "serving_size"
        case quantity
    }

    var name: String? {
        [productNameEn, productName]
            .compactMap { $0?.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty }
    }

    func toFoodItem() -> FoodItem? {
        guard let name,
              let n = nutriments,
              let cal = n.energyKcal, cal > 0
        else { return nil }

        return FoodItem(
            name: name.capitalized,
            calories: Int(cal),
            protein: n.protein ?? 0,
            carbs: n.carbs ?? 0,
            fat: n.fat ?? 0,
            unit: servingSize ?? quantity ?? "100g"
        )
    }
}
