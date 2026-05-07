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
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
                    VStack(alignment: .leading, spacing: 6) {
                        AppIconBadge(systemName: "square.and.pencil.circle.fill", color: AppTheme.ColorToken.protein, size: 42)
                        Text("Tạo thực phẩm riêng")
                            .font(.title3.bold())
                        Text("Lưu món tự tạo vào dữ liệu local để dùng lại khi ghi nhật ký.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppTheme.Spacing.card)
                    .appCard(radius: AppTheme.Radius.card, shadow: true)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Thông tin cơ bản")
                            .font(.headline.bold())

                        inputField("Tên món", text: $name)
                        inputField("Khẩu phần", text: $unit)
                    }
                    .padding(AppTheme.Spacing.card)
                    .appCard(radius: AppTheme.Radius.card, shadow: true)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Dinh dưỡng")
                            .font(.headline.bold())

                        inputField("Calories", text: $calories, keyboardType: .numberPad, symbolName: "flame.fill", color: AppTheme.ColorToken.calories)
                        inputField("Protein (g)", text: $protein, keyboardType: .decimalPad, symbolName: "bolt.fill", color: AppTheme.ColorToken.protein)
                        inputField("Carbs (g)", text: $carbs, keyboardType: .decimalPad, symbolName: "leaf.fill", color: AppTheme.ColorToken.carb)
                        inputField("Fat (g)", text: $fat, keyboardType: .decimalPad, symbolName: "drop.fill", color: AppTheme.ColorToken.fat)
                    }
                    .padding(AppTheme.Spacing.card)
                    .appCard(radius: AppTheme.Radius.card, shadow: true)
                }
                .padding(AppTheme.Spacing.screen)
            }
            .appScreenBackground()
            .navigationTitle("Tạo thực phẩm")
            .navigationBarTitleDisplayMode(.inline)
            .presentationBackground(AppTheme.ColorToken.screenBackground)
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

    private func inputField(
        _ placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        symbolName: String? = nil,
        color: Color = AppTheme.ColorToken.primary
    ) -> some View {
        HStack(spacing: 10) {
            if let symbolName {
                Image(systemName: symbolName)
                    .font(.caption.bold())
                    .foregroundStyle(color)
                    .frame(width: 24, height: 24)
                    .background(color.opacity(0.12))
                    .clipShape(Circle())
            }

            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .font(.subheadline.weight(.semibold))
        }
        .padding(14)
        .background(AppTheme.ColorToken.mutedFill)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func parseDouble(_ text: String) -> Double? {
        DecimalTextParser.double(from: text)
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
