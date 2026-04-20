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
        VStack(spacing: 6) {
            Text(goalConfig.icon + " " + goalConfig.title)
                .font(.title2.bold())
            Text("Mục tiêu: \(Int(nutrition.targetCalories)) kcal/ngày")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(goalConfig.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.black)
        .foregroundColor(.white)
        .cornerRadius(20)
        .padding(.horizontal)
    }
}

struct MealPlanGuideSection: View {
    let goal: String

    private var goalConfig: GoalConfig {
        GoalConfig.config(for: goal)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gợi ý dinh dưỡng")
                .font(.headline.bold())
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(goalConfig.nutrients, id: \.title) { nutrient in
                        NutrientGuideCard(nutrient: nutrient)
                    }
                }
                .padding(.horizontal)
            }

            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
                Text("Gợi ý \(goalConfig.mealCount) bữa/ngày")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
    }
}

struct MealPlanGenerateButton: View {
    let onGenerate: () -> Void

    var body: some View {
        Button(action: onGenerate) {
            Label("Tạo kế hoạch hôm nay", systemImage: "sparkles")
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(16)
                .font(.headline)
        }
        .padding(.horizontal)
    }
}

struct MealPlanContent: View {
    let state: MealPlanState
    let onRetry: () -> Void

    var body: some View {
        switch state {
        case .idle:
            MealPlanIdleState()
        case .loading:
            MealPlanLoadingState()
        case .success(let plan):
            MealPlanResultSection(plan: plan)
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
            Text("Nhấn tạo kế hoạch để nhận\ngợi ý bữa ăn phù hợp với mục tiêu")
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
            Text("Đang tạo kế hoạch...")
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

    var body: some View {
        VStack(spacing: 16) {
            MealPlanNutritionSummary(plan: plan)

            ForEach(Array(plan.meals.enumerated()), id: \.0) { index, meal in
                MealCard(
                    mealTime: MealTiming.label(for: index, total: plan.meals.count),
                    meal: meal
                )
                .padding(.horizontal)
            }
        }
    }
}

private struct MealPlanNutritionSummary: View {
    let plan: DayMealPlan

    var body: some View {
        VStack(spacing: 12) {
            Text("Tổng dinh dưỡng hôm nay")
                .font(.subheadline.bold())
            HStack(spacing: 0) {
                NutritionStat(label: "Calo", value: "\(Int(plan.totalCalories))", unit: "kcal", color: .black)
                NutritionStat(label: "Protein", value: "\(Int(plan.totalProtein))", unit: "g", color: .orange)
                NutritionStat(label: "Carbs", value: "\(Int(plan.totalCarbs))", unit: "g", color: .blue)
                NutritionStat(label: "Chất béo", value: "\(Int(plan.totalFat))", unit: "g", color: .green)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .padding(.horizontal)
    }
}

struct GoalConfig {
    let icon: String
    let title: String
    let subtitle: String
    let mealCount: Int
    let nutrients: [NutrientGuide]

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
        icon: "🏃",
        title: "Giảm cân",
        subtitle: "Ưu tiên rau xanh, đồ luộc\nHạn chế tinh bột và chất béo",
        mealCount: 3,
        nutrients: [
            NutrientGuide(title: "Protein", tip: "Thịt nạc, cá, trứng", icon: "🥩", color: .orange),
            NutrientGuide(title: "Chất xơ", tip: "Rau xanh, salad", icon: "🥗", color: .green),
            NutrientGuide(title: "Carb thấp", tip: "Hạn chế cơm, bánh mì", icon: "🌾", color: .brown),
        ]
    )

    static let gain = GoalConfig(
        icon: "💪",
        title: "Tăng cơ",
        subtitle: "Ưu tiên protein cao, carb phức hợp\nĂn 4-5 bữa/ngày để đủ năng lượng",
        mealCount: 5,
        nutrients: [
            NutrientGuide(title: "Protein cao", tip: "Thịt gà, cá, đậu, trứng", icon: "🥩", color: .orange),
            NutrientGuide(title: "Carb tốt", tip: "Cơm, khoai lang, yến mạch", icon: "🍚", color: .blue),
            NutrientGuide(title: "Chất xơ", tip: "Rau xanh, trái cây", icon: "🥦", color: .green),
        ]
    )

    static let maintain = GoalConfig(
        icon: "⚖️",
        title: "Duy trì",
        subtitle: "Cân bằng protein, carb và chất béo\nĂn đều đặn 3 bữa chính",
        mealCount: 3,
        nutrients: [
            NutrientGuide(title: "Protein", tip: "Thịt, cá, đậu", icon: "🥩", color: .orange),
            NutrientGuide(title: "Carb", tip: "Cơm, bánh mì nguyên cám", icon: "🍚", color: .blue),
            NutrientGuide(title: "Chất xơ", tip: "Rau củ, trái cây", icon: "🥗", color: .green),
        ]
    )
}

struct NutrientGuide {
    let title: String
    let tip: String
    let icon: String
    let color: Color
}

struct NutrientGuideCard: View {
    let nutrient: NutrientGuide

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(nutrient.icon).font(.title2)
            Text(nutrient.title)
                .font(.subheadline.bold())
                .foregroundColor(nutrient.color)
            Text(nutrient.tip)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 140)
        .padding(14)
        .background(nutrient.color.opacity(0.08))
        .cornerRadius(16)
    }
}

struct MealCard: View {
    let mealTime: String
    let meal: MealPlanItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(mealTime)
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            HStack(spacing: 14) {
                AsyncImage(url: URL(string: meal.imageURL)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.15))
                        .overlay(Image(systemName: "fork.knife").foregroundStyle(.secondary))
                }
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 6) {
                    Text(meal.title)
                        .font(.subheadline.bold())
                        .lineLimit(2)
                    HStack(spacing: 12) {
                        Label("\(meal.readyInMinutes) phút", systemImage: "clock")
                        Label("\(meal.servings) phần", systemImage: "person")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if let url = meal.sourceUrl, let link = URL(string: url) {
                Link(destination: link) {
                    Label("Xem công thức", systemImage: "arrow.up.right")
                        .font(.caption.bold())
                        .foregroundColor(.black)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
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

enum MealTiming {
    static func label(for index: Int, total: Int) -> String {
        if total <= 3 {
            return ["☀️ Bữa sáng", "🌤️ Bữa trưa", "🌙 Bữa tối"][safe: index] ?? "🍽️ Bữa \(index + 1)"
        }

        let labels = ["☀️ Bữa sáng", "🥗 Bữa phụ sáng", "🌤️ Bữa trưa", "💪 Bữa phụ chiều", "🌙 Bữa tối"]
        return labels[safe: index] ?? "🍽️ Bữa \(index + 1)"
    }
}
