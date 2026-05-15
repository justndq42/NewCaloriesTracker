import SwiftUI
import SwiftData

struct CreateCustomFoodSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AuthSessionStore.self) private var authStore
    let foodToEdit: CustomFoodModel?

    @State private var name = ""
    @State private var unit = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var isSaving = false
    @State private var syncErrorMessage: String?

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !unit.trimmingCharacters(in: .whitespaces).isEmpty &&
        Int(calories) != nil &&
        parseDouble(protein) != nil &&
        parseDouble(carbs) != nil &&
        parseDouble(fat) != nil
    }

    private var isEditing: Bool {
        foodToEdit != nil
    }

    init(foodToEdit: CustomFoodModel? = nil) {
        self.foodToEdit = foodToEdit
        _name = State(initialValue: foodToEdit?.name ?? "")
        _unit = State(initialValue: foodToEdit?.unit ?? "")
        _calories = State(initialValue: foodToEdit.map { "\($0.calories)" } ?? "")
        _protein = State(initialValue: foodToEdit.map { Self.formattedMacro($0.protein) } ?? "")
        _carbs = State(initialValue: foodToEdit.map { Self.formattedMacro($0.carbs) } ?? "")
        _fat = State(initialValue: foodToEdit.map { Self.formattedMacro($0.fat) } ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
                    VStack(alignment: .leading, spacing: 6) {
                        AppIconBadge(systemName: "square.and.pencil.circle.fill", color: AppTheme.ColorToken.protein, size: 42)
                        Text(isEditing ? "Chỉnh sửa thực phẩm" : "Tạo thực phẩm riêng")
                            .font(.title3.bold())
                        Text(isEditing ? "Cập nhật lại thông tin món tự tạo đã lưu." : "Lưu món tự tạo vào dữ liệu local để dùng lại khi ghi nhật ký.")
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

                    if let syncErrorMessage {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(AppTheme.ColorToken.calories)
                            Text(syncErrorMessage)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(AppTheme.ColorToken.calories)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(AppTheme.ColorToken.calories.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.compactCard, style: .continuous))
                    }
                }
                .padding(AppTheme.Spacing.screen)
            }
            .appScreenBackground()
            .navigationTitle(isEditing ? "Sửa thực phẩm" : "Tạo thực phẩm")
            .navigationBarTitleDisplayMode(.inline)
            .presentationBackground(AppTheme.ColorToken.screenBackground)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await saveFood()
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Lưu")
                        }
                    }
                        .fontWeight(.semibold)
                        .disabled(!isValid || isSaving)
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

    private static func formattedMacro(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }

    private func saveFood() async {
        guard
            let userID = authStore.user?.id,
            let caloriesValue = Int(calories),
            let proteinValue = parseDouble(protein),
            let carbsValue = parseDouble(carbs),
            let fatValue = parseDouble(fat)
        else { return }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUnit = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        let savedFood: CustomFoodModel

        isSaving = true
        syncErrorMessage = nil

        if let foodToEdit {
            guard foodToEdit.userID == nil || foodToEdit.userID == userID else {
                syncErrorMessage = "Không thể sửa thực phẩm thuộc tài khoản khác."
                isSaving = false
                return
            }

            let previousName = foodToEdit.name
            let previousUnit = foodToEdit.unit
            let customFoodID = foodToEdit.resolvedCustomFoodID()

            foodToEdit.userID = userID
            foodToEdit.name = trimmedName
            foodToEdit.calories = caloriesValue
            foodToEdit.protein = proteinValue
            foodToEdit.carbs = carbsValue
            foodToEdit.fat = fatValue
            foodToEdit.unit = trimmedUnit
            foodToEdit.markLocallyUpdated()

            syncLoggedEntries(
                with: foodToEdit,
                customFoodID: customFoodID,
                previousName: previousName,
                previousUnit: previousUnit,
                userID: userID
            )
            savedFood = foodToEdit
        } else {
            let food = CustomFoodModel(
                name: trimmedName,
                calories: caloriesValue,
                protein: proteinValue,
                carbs: carbsValue,
                fat: fatValue,
                unit: trimmedUnit,
                userID: userID
            )
            context.insert(food)
            savedFood = food
        }

        do {
            try context.save()

            if let accessToken = await authStore.accessToken() {
                try await CustomFoodSyncService.shared.push(food: savedFood, userID: userID, accessToken: accessToken)
                try context.save()
            }

            isSaving = false
            dismiss()
        } catch {
            isSaving = false
            syncErrorMessage = "Đã lưu local nhưng chưa đồng bộ được lên tài khoản. Vui lòng thử lại."
        }
    }

    private func syncLoggedEntries(
        with food: CustomFoodModel,
        customFoodID: String,
        previousName: String,
        previousUnit: String,
        userID: String
    ) {
        let descriptor = FetchDescriptor<DiaryEntryModel>()
        let entries = (try? context.fetch(descriptor)) ?? []

        for entry in entries where entry.userID == userID && shouldSync(entry, customFoodID: customFoodID, previousName: previousName, previousUnit: previousUnit) {
            let portionCount = portionCount(from: entry.unit)
            let updatedFood = food.foodItem.scaledForPortions(portionCount)

            entry.foodName = updatedFood.name
            entry.calories = updatedFood.calories
            entry.protein = updatedFood.protein
            entry.carbs = updatedFood.carbs
            entry.fat = updatedFood.fat
            entry.unit = updatedFood.unit
            entry.customFoodID = customFoodID
            entry.markLocallyUpdated()
        }
    }

    private func shouldSync(
        _ entry: DiaryEntryModel,
        customFoodID: String,
        previousName: String,
        previousUnit: String
    ) -> Bool {
        if entry.customFoodID == customFoodID {
            return true
        }

        return entry.customFoodID == nil
            && entry.foodName == previousName
            && entry.unit.contains(previousUnit)
    }

    private func portionCount(from unitDescription: String) -> Double {
        guard let firstToken = unitDescription.split(separator: " ").first else {
            return 1
        }

        return DecimalTextParser.double(from: String(firstToken)) ?? 1
    }
}
