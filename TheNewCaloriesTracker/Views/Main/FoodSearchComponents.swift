import SwiftUI

struct FoodSearchContent: View {
    let state: SearchState
    let onSelectFood: (FoodItem) -> Void
    let onRetry: () -> Void

    var body: some View {
        switch state {
        case .idle(let recommended):
            FoodSearchIdleSection(items: recommended, onSelectFood: onSelectFood)
        case .loading:
            FoodSearchLoadingSection()
        case .success(let foods):
            FoodSearchResultsSection(foods: foods, onSelectFood: onSelectFood)
        case .error(let message):
            FoodSearchErrorSection(message: message, onRetry: onRetry)
        }
    }
}

struct FoodSectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 2)
    }
}

private struct FoodSearchIdleSection: View {
    let items: [FoodItem]
    let onSelectFood: (FoodItem) -> Void

    var body: some View {
        if items.isEmpty {
            HStack {
                Spacer()
                VStack(spacing: 12) {
                    ProgressView().scaleEffect(1.1)
                    Text("Đang tải gợi ý...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 40)
        } else {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
                FoodSectionTitle("Gợi ý phổ biến")

                ForEach(items) { food in
                    Button { onSelectFood(food) } label: {
                        FoodRow(food: food)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct FoodSearchLoadingSection: View {
    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 10) {
                ProgressView().scaleEffect(1.1)
                Text("Đang tìm kiếm...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 30)
    }
}

private struct FoodSearchResultsSection: View {
    let foods: [FoodItem]
    let onSelectFood: (FoodItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            FoodSectionTitle("Kết quả (\(foods.count) món)")

            ForEach(foods) { food in
                Button { onSelectFood(food) } label: {
                    FoodRow(food: food)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct FoodSearchErrorSection: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: onRetry) {
                Label("Thử lại", systemImage: "arrow.clockwise")
                    .appCompactPrimaryButtonStyle(radius: 14)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, AppTheme.Spacing.card)
        .appCard(radius: AppTheme.Radius.card, shadow: true)
    }
}

struct FoodRow: View {
    let food: FoodItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(food.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.ColorToken.primary)
                    .lineLimit(1)
                Text(food.unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(food.calories)")
                    .font(.subheadline.bold())
                Text("kcal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(AppTheme.Spacing.card)
        .appCard(radius: AppTheme.Radius.compactCard, shadow: true)
    }
}

struct FoodDetailSheet: View {
    let food: FoodItem
    let entryDate: Date
    let onAdd: (FoodItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var portionCount = 1.0

    private var portionedFood: FoodItem {
        food.scaledForPortions(portionCount)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    FoodNutritionHero(food: portionedFood)
                    FoodPortionControl(food: food, portionCount: $portionCount)
                    FoodMacroRow(food: portionedFood)
                    FoodDetectedMealCard(entryDate: entryDate)
                    FoodAddButton {
                        onAdd(portionedFood)
                    }
                }
                .padding(AppTheme.Spacing.screen)
            }
            .appScreenBackground()
            .navigationTitle(food.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

private struct FoodPortionControl: View {
    let food: FoodItem
    @Binding var portionCount: Double
    @State private var portionText = "1"

    private let minPortions = 0.1
    private let maxPortions = 20.0
    private let step = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Khẩu phần")
                        .font(.subheadline.weight(.semibold))
                    Text("1 khẩu phần = \(food.unit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(food.portionUnitDescription(for: portionCount))
                    .font(.headline.weight(.bold))
            }

            HStack(spacing: 18) {
                PortionStepButton(systemName: "minus", isDisabled: portionCount <= minPortions) {
                    setPortionCount(portionCount - step)
                }

                VStack(spacing: 2) {
                    TextField("1", text: $portionText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .font(.title2.weight(.bold))
                        .frame(maxWidth: 90)
                        .onChange(of: portionText) { _, newValue in
                            updatePortionCount(from: newValue)
                        }
                        .onSubmit {
                            portionText = food.formattedPortionCount(portionCount)
                        }
                    Text("khẩu phần")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                PortionStepButton(systemName: "plus", isDisabled: portionCount >= maxPortions) {
                    setPortionCount(portionCount + step)
                }
            }
            .padding(12)
            .background(AppTheme.ColorToken.mutedFill)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(AppTheme.Spacing.card)
        .appCard(radius: AppTheme.Radius.compactCard, shadow: true)
        .onAppear {
            portionText = food.formattedPortionCount(portionCount)
        }
    }

    private func setPortionCount(_ value: Double) {
        portionCount = clampedPortionCount(value)
        portionText = food.formattedPortionCount(portionCount)
    }

    private func updatePortionCount(from text: String) {
        guard let parsedValue = DecimalTextParser.double(from: text) else { return }
        portionCount = clampedPortionCount(parsedValue)
    }

    private func clampedPortionCount(_ value: Double) -> Double {
        min(max(value, minPortions), maxPortions)
    }
}

private struct PortionStepButton: View {
    let systemName: String
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(isDisabled ? Color.secondary : Color.white)
                .frame(width: 42, height: 42)
                .background(isDisabled ? AppTheme.ColorToken.mutedFill : AppTheme.ColorToken.primary)
                .clipShape(Circle())
        }
        .disabled(isDisabled)
    }
}

private struct FoodNutritionHero: View {
    let food: FoodItem

    var body: some View {
        VStack(spacing: 6) {
            Text("\(food.calories)")
                .font(.system(size: 80, weight: .bold, design: .rounded))
            Text("kcal")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(food.unit)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(AppTheme.ColorToken.primarySoft)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
    }
}

private struct FoodMacroRow: View {
    let food: FoodItem

    var body: some View {
        HStack(spacing: 12) {
            MacroDetailCard(symbolName: "bolt.fill", label: "Protein", value: food.protein, color: AppTheme.ColorToken.protein)
            MacroDetailCard(symbolName: "leaf.fill", label: "Carbs", value: food.carbs, color: AppTheme.ColorToken.carb)
            MacroDetailCard(symbolName: "drop.fill", label: "Chất béo", value: food.fat, color: AppTheme.ColorToken.fat)
        }
    }
}

private struct FoodDetectedMealCard: View {
    let entryDate: Date

    private var mealPeriod: MealPeriod {
        MealPeriod.from(date: entryDate)
    }

    private var mealIcon: String {
        switch mealPeriod {
        case .breakfast:
            return "sunrise.fill"
        case .lunch:
            return "sun.max.fill"
        case .snack:
            return "carrot.fill"
        case .dinner:
            return "moon.stars.fill"
        }
    }

    private var mealColor: Color {
        switch mealPeriod {
        case .breakfast:
            return .orange
        case .lunch:
            return AppTheme.ColorToken.calories
        case .snack:
            return AppTheme.ColorToken.protein
        case .dinner:
            return .indigo
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bạn đang ăn vào lúc")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 10) {
                Image(systemName: mealIcon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(mealColor)
                    .frame(width: 34, height: 34)
                    .background(mealColor.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(mealPeriod.title)
                        .font(.subheadline.weight(.semibold))
                    Text(entryDate.formatted(.dateTime.hour().minute()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(14)
            .background(AppTheme.ColorToken.mutedFill)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.compactCard, style: .continuous))
        }
    }
}

private struct FoodAddButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Thêm vào nhật ký")
                    .font(.headline)
            }
            .appPrimaryButtonStyle()
        }
    }
}

struct MacroDetailCard: View {
    let symbolName: String
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            AppIconBadge(systemName: symbolName, color: color, size: 34)
            Text("\(value, specifier: "%.1f")g")
                .font(.headline.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.compactCard, style: .continuous))
    }
}
