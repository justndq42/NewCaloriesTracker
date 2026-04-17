import Foundation

class LocalFoodService {
    static let shared = LocalFoodService()
    private init() {}

    let recommended: [FoodItem] = [
        FoodItem(name: "Phở bò",            calories: 400, protein: 22.0, carbs: 55.0, fat: 9.0,  unit: "1 tô (500g)"),
        FoodItem(name: "Bún chả",           calories: 480, protein: 28.0, carbs: 55.0, fat: 15.0, unit: "1 phần (400g)"),
        FoodItem(name: "Cơm tấm sườn bì",   calories: 650, protein: 30.0, carbs: 70.0, fat: 25.0, unit: "1 đĩa (400g)"),
        FoodItem(name: "Bánh mì thịt",      calories: 350, protein: 16.0, carbs: 42.0, fat: 12.0, unit: "1 ổ (180g)"),
        FoodItem(name: "Bún bò Huế",        calories: 430, protein: 24.0, carbs: 58.0, fat: 11.0, unit: "1 tô (500g)"),
        FoodItem(name: "Phở gà",            calories: 350, protein: 20.0, carbs: 52.0, fat: 7.0,  unit: "1 tô (500g)"),
        FoodItem(name: "Bún riêu cua",      calories: 380, protein: 18.0, carbs: 52.0, fat: 10.0, unit: "1 tô (500g)"),
        FoodItem(name: "Cơm gà xối mỡ",    calories: 550, protein: 32.0, carbs: 55.0, fat: 20.0, unit: "1 đĩa (350g)"),
        FoodItem(name: "Hủ tiếu Nam Vang",  calories: 420, protein: 22.0, carbs: 55.0, fat: 11.0, unit: "1 tô (500g)"),
        FoodItem(name: "Mì Quảng",          calories: 460, protein: 24.0, carbs: 60.0, fat: 12.0, unit: "1 tô (400g)"),
        FoodItem(name: "Bánh mì trứng",     calories: 300, protein: 12.0, carbs: 40.0, fat: 10.0, unit: "1 ổ (180g)"),
        FoodItem(name: "Cháo gà",           calories: 150, protein: 12.0, carbs: 20.0, fat: 3.0,  unit: "1 tô (300g)"),
        FoodItem(name: "Gỏi cuốn tôm thịt", calories: 120, protein: 8.0,  carbs: 16.0, fat: 2.5,  unit: "2 cuốn (120g)"),
        FoodItem(name: "Cà phê sữa đá",     calories: 120, protein: 2.0,  carbs: 18.0, fat: 4.0,  unit: "1 ly (250ml)"),
        FoodItem(name: "Chả giò",           calories: 200, protein: 8.0,  carbs: 18.0, fat: 11.0, unit: "3 cuốn (100g)"),
    ]

    func search(query: String) -> [FoodItem] {
        recommended.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }
}
