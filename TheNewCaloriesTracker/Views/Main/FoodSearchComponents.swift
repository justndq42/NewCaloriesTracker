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

private struct FoodSearchIdleSection: View {
    let items: [FoodItem]
    let onSelectFood: (FoodItem) -> Void

    var body: some View {
        if items.isEmpty {
            Section {
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
            }
            .listRowBackground(Color.clear)
        } else {
            Section {
                ForEach(items) { food in
                    Button { onSelectFood(food) } label: {
                        FoodRow(food: food)
                    }
                }
            } header: {
                HStack {
                    Text("⭐ Gợi ý phổ biến")
                    Spacer()
                    Text("Powered by Spoonacular")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct FoodSearchLoadingSection: View {
    var body: some View {
        Section {
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
        .listRowBackground(Color.clear)
    }
}

private struct FoodSearchResultsSection: View {
    let foods: [FoodItem]
    let onSelectFood: (FoodItem) -> Void

    var body: some View {
        Section {
            ForEach(foods) { food in
                Button { onSelectFood(food) } label: {
                    FoodRow(food: food)
                }
            }
        } header: {
            Text("Kết quả (\(foods.count) món)")
        }
    }
}

private struct FoodSearchErrorSection: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        Section {
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
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .font(.subheadline.bold())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
        .listRowBackground(Color.clear)
    }
}

struct FoodRow: View {
    let food: FoodItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(food.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
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
        .padding(.vertical, 4)
    }
}

struct FoodDetailSheet: View {
    let food: FoodItem
    let entryDate: Date
    let onAdd: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    FoodNutritionHero(food: food)
                    FoodMacroRow(food: food)
                    FoodDetectedMealCard(entryDate: entryDate)
                    FoodAddButton(action: onAdd)
                }
                .padding()
            }
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
        .padding(.vertical, 24)
        .background(Color.black)
        .foregroundColor(.white)
        .cornerRadius(24)
    }
}

private struct FoodMacroRow: View {
    let food: FoodItem

    var body: some View {
        HStack(spacing: 12) {
            MacroDetailCard(icon: "🥩", label: "Protein", value: food.protein, color: .orange)
            MacroDetailCard(icon: "🍞", label: "Carbs", value: food.carbs, color: .blue)
            MacroDetailCard(icon: "🫒", label: "Chất béo", value: food.fat, color: .green)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bữa ăn được nhận diện tự động")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 10) {
                Image(systemName: mealIcon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: 34, height: 34)
                    .background(Color.gray.opacity(0.08))
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
            .background(Color.gray.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
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
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(16)
        }
    }
}

struct MacroDetailCard: View {
    let icon: String
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(icon).font(.title2)
            Text("\(value, specifier: "%.1f")g")
                .font(.title3.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.08))
        .cornerRadius(16)
    }
}
