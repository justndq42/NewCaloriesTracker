import SwiftUI

struct MealPlanGoalHeader: View {
    let profile: UserProfileModel

    private var nutrition: NutritionProfile {
        NutritionProfile(profile: profile)
    }

    private var goalConfig: GoalConfig {
        GoalConfig.config(for: profile.goal)
    }

    var body: some View {
        VStack(spacing: 8) {
            AppIconBadge(systemName: goalConfig.symbolName, color: .white.opacity(0.92), size: 44)
            Text(goalConfig.title)
                .font(.title2.bold())
            Text("Mục tiêu: \(Int(nutrition.targetCalories)) kcal/ngày")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.68))
            Text(goalConfig.subtitle)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.58))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(AppTheme.ColorToken.primarySoft)
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
        .padding(.horizontal)
    }
}

struct MealPlanSuggestionSection: View {
    let profile: UserProfileModel
    let onAddFood: (FoodItem, MealPlanSlotKind) -> Void

    private var suggestions: [MealPlanSuggestedFood] {
        MealPlanSuggestionProvider().suggestions(for: profile.nutritionGoal)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Món ăn phù hợp với bạn")
                    .font(.headline.bold())
                Text(suggestionSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
                    .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(suggestions) { suggestion in
                        MealPlanSuggestionCard(
                            suggestion: suggestion,
                            onAddFood: onAddFood
                        )
                    }
                }
                .padding(.horizontal)
            }

            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
                Text("Chia theo 4 khung: sáng, trưa, snack, tối")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
    }

    private var suggestionSubtitle: String {
        switch profile.nutritionGoal {
        case .gain:
            return "Thoáng hơn về calo, ưu tiên món Việt ngon và giàu năng lượng."
        case .lose:
            return "Ưu tiên món giàu dinh dưỡng, ít calo: protein, carb tốt, fat tốt và chất xơ."
        case .maintain:
            return "Khuyến khích ăn lean với món calo trung bình, dễ duy trì lâu dài."
        }
    }
}

struct MealPlanGenerateButton: View {
    let onGenerate: () -> Void

    var body: some View {
        Button(action: onGenerate) {
            Label("Tạo meal plan ngày hôm nay", systemImage: "sparkles")
                .appCompactPrimaryButtonStyle()
        }
        .padding(.horizontal)
    }
}

struct MealPlanContent: View {
    let state: MealPlanState
    let onRetry: () -> Void
    let onRegenerateSlot: (MealPlanSlotKind) -> Void
    let onLogSlot: (MealPlanSlot) -> Void

    var body: some View {
        switch state {
        case .idle:
            MealPlanIdleState()
        case .loading:
            MealPlanLoadingState()
        case .success(let plan):
            MealPlanResultSection(
                plan: plan,
                onRegenerateSlot: onRegenerateSlot,
                onLogSlot: onLogSlot
            )
        case .error(let message):
            MealPlanErrorState(message: message, onRetry: onRetry)
        }
    }
}

private struct MealPlanIdleState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 50))
                .foregroundStyle(.black.opacity(0.15))
            Text("Nhấn tạo meal plan để nhận\ngợi ý bữa ăn phù hợp với mục tiêu")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

private struct MealPlanLoadingState: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.3)
            Text("Đang tạo meal plan...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(40)
    }
}

private struct MealPlanErrorState: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle")
                .font(.largeTitle)
                .foregroundStyle(.red)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Thử lại", action: onRetry)
                .buttonStyle(.bordered)
                .tint(.black)
        }
        .padding(40)
    }
}

private struct MealPlanResultSection: View {
    let plan: DayMealPlan
    let onRegenerateSlot: (MealPlanSlotKind) -> Void
    let onLogSlot: (MealPlanSlot) -> Void

    var body: some View {
        VStack(spacing: 16) {
            MealPlanNutritionSummary(plan: plan)

            ForEach(plan.slots) { slot in
                MealSlotCard(
                    slot: slot,
                    onRegenerate: { onRegenerateSlot(slot.kind) },
                    onLog: { onLogSlot(slot) }
                )
                .padding(.horizontal)
            }
        }
    }
}

private struct MealPlanNutritionSummary: View {
    let plan: DayMealPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Tổng kế hoạch hôm nay")
                    .font(.subheadline.bold())
                Spacer()
                Text("\(Int(plan.totalCalories)) kcal")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                MealPlanSummaryStat(
                    icon: "flame.fill",
                    value: "\(Int(plan.totalCalories))/\(plan.targetCalories)",
                    unit: "kcal",
                    color: .red
                )
                MealPlanSummaryStat(
                    icon: "bolt.fill",
                    value: "\(Int(plan.totalProtein))/\(Int(plan.targetProtein))",
                    unit: "gram",
                    color: .green
                )
                MealPlanSummaryStat(
                    icon: "leaf.fill",
                    value: "\(Int(plan.totalCarbs))/\(Int(plan.targetCarbs))",
                    unit: "gram",
                    color: .blue
                )
                MealPlanSummaryStat(
                    icon: "drop.fill",
                    value: "\(Int(plan.totalFat))/\(Int(plan.targetFat))",
                    unit: "gram",
                    color: .yellow
                )
            }
        }
        .padding(14)
        .appCard(radius: AppTheme.Radius.card)
        .padding(.horizontal)
    }
}

private struct MealPlanSummaryStat: View {
    let icon: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption.bold())
                    .foregroundStyle(color)
                Text(value)
                    .font(.caption.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct GoalConfig {
    let symbolName: String
    let title: String
    let subtitle: String

    static func config(for goal: String) -> GoalConfig {
        switch goal {
        case "lose":
            return .lose
        case "gain":
            return .gain
        default:
            return .maintain
        }
    }

    static let lose = GoalConfig(
        symbolName: "figure.run",
        title: "Giảm cân",
        subtitle: "Bám macro giảm cân\n45% carb • 30% protein • 25% fat"
    )

    static let gain = GoalConfig(
        symbolName: "arrow.up.heart.fill",
        title: "Tăng cơ",
        subtitle: "Bám macro tăng cân\n50% carb • 30% protein • 20% fat"
    )

    static let maintain = GoalConfig(
        symbolName: "scalemass.fill",
        title: "Duy trì",
        subtitle: "Bám macro duy trì\n40% carb • 30% protein • 30% fat"
    )
}

struct MealPlanSuggestionCard: View {
    let suggestion: MealPlanSuggestedFood
    let onAddFood: (FoodItem, MealPlanSlotKind) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(suggestion.reason)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(reasonColor.opacity(0.14))
                    .foregroundStyle(reasonColor)
                    .clipShape(Capsule())
                Spacer()
            }

            Text(suggestion.food.name)
                .font(.subheadline.bold())
                .lineLimit(2)

            Text("\(suggestion.food.calories) kcal • P \(Int(suggestion.food.protein))g • C \(Int(suggestion.food.carbs))g • F \(Int(suggestion.food.fat))g")
                .font(.caption)
                .foregroundStyle(.secondary)

            Menu {
                ForEach(MealPlanSlotKind.allCases) { kind in
                    Button("Thêm vào \(kind.title)") {
                        onAddFood(suggestion.food, kind)
                    }
                }
            } label: {
                Label("Thêm vào", systemImage: "plus.circle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.black)
            }
        }
        .frame(width: 180, alignment: .leading)
        .padding(14)
        .appCard(radius: AppTheme.Radius.compactCard, shadow: true)
    }

    private var reasonColor: Color {
        switch suggestion.category {
        case .energyDense:
            return .orange
        case .proteinFocused:
            return .green
        case .carbFocused:
            return .blue
        case .fiberFocused:
            return .mint
        case .healthyFat:
            return .yellow
        case .balanced:
            return .indigo
        }
    }
}

struct MealSlotCard: View {
    let slot: MealPlanSlot
    let onRegenerate: () -> Void
    let onLog: () -> Void

    private var color: Color {
        switch slot.kind.colorName {
        case "orange":
            return .orange
        case "blue":
            return .blue
        case "green":
            return .green
        default:
            return .indigo
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(slot.kind.title, systemImage: slot.kind.icon)
                    .font(.headline.bold())
                    .foregroundStyle(color)
                Spacer()
                Text("\(slot.totalCalories)/\(Int(slot.targetCalories)) kcal")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            MealSlotMacroRow(slot: slot)

            VStack(spacing: 10) {
                ForEach(slot.foods) { food in
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(food.name)
                                .font(.subheadline.bold())
                            Text(food.unit)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(food.calories) kcal")
                            .font(.caption.bold())
                    }
                }
            }

            HStack(spacing: 10) {
                Button(action: onRegenerate) {
                    Label("Đổi món", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.bordered)
                .tint(.black)

                Button(action: onLog) {
                    Label("Log bữa này", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.black)
            }
            .font(.caption.bold())
        }
        .padding(16)
        .appCard(radius: AppTheme.Radius.card)
    }
}

private struct MealSlotMacroRow: View {
    let slot: MealPlanSlot

    var body: some View {
        HStack(spacing: 8) {
            MealSlotMacroPill(symbolName: "bolt.fill", value: Int(slot.totalProtein), target: Int(slot.targetProtein), color: .green)
            MealSlotMacroPill(symbolName: "leaf.fill", value: Int(slot.totalCarbs), target: Int(slot.targetCarbs), color: .blue)
            MealSlotMacroPill(symbolName: "drop.fill", value: Int(slot.totalFat), target: Int(slot.targetFat), color: .yellow)
        }
    }
}

private struct MealSlotMacroPill: View {
    let symbolName: String
    let value: Int
    let target: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbolName)
                .font(.caption2.bold())
                .foregroundStyle(color)
            Text("\(value)/\(target)g")
                .font(.caption2.bold())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(color.opacity(0.10))
        .clipShape(Capsule())
    }
}

struct NutritionStat: View {
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold()).foregroundColor(color)
            Text(unit).font(.caption2).foregroundStyle(.secondary)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
