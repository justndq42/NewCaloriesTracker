import SwiftUI
import SwiftData

struct CreateCustomFoodSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var unit = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !unit.trimmingCharacters(in: .whitespaces).isEmpty &&
        Int(calories) != nil &&
        parseDouble(protein) != nil &&
        parseDouble(carbs) != nil &&
        parseDouble(fat) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Thông tin cơ bản") {
                    TextField("Tên món", text: $name)
                    TextField("Khẩu phần", text: $unit)
                }

                Section("Dinh dưỡng") {
                    TextField("Calories", text: $calories)
                        .keyboardType(.numberPad)
                    TextField("Protein (g)", text: $protein)
                        .keyboardType(.decimalPad)
                    TextField("Carbs (g)", text: $carbs)
                        .keyboardType(.decimalPad)
                    TextField("Fat (g)", text: $fat)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Tạo thực phẩm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Lưu", action: saveFood)
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
        }
    }

    private func parseDouble(_ text: String) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: "."))
    }

    private func saveFood() {
        guard
            let caloriesValue = Int(calories),
            let proteinValue = parseDouble(protein),
            let carbsValue = parseDouble(carbs),
            let fatValue = parseDouble(fat)
        else { return }

        let food = CustomFoodModel(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            calories: caloriesValue,
            protein: proteinValue,
            carbs: carbsValue,
            fat: fatValue,
            unit: unit.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        context.insert(food)
        try? context.save()
        dismiss()
    }
}
