import SwiftUI
import SwiftData

struct AccountNutritionGoalSection: View {
    @Bindable var profile: UserProfileModel

    @State private var isShowingDetails = false

    private var nutrition: NutritionProfile {
        NutritionProfile(profile: profile)
    }

    private var metrics: [NutritionMacroMetric] {
        NutritionMacroMetric.metrics(for: nutrition)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mục tiêu dinh dưỡng & đa lượng")
                .font(.headline.bold())

            VStack(spacing: 16) {
                HStack(spacing: 22) {
                    MacroCalorieRing(nutrition: nutrition, metrics: metrics, size: 108)

                    VStack(spacing: 10) {
                        ForEach(metrics) { metric in
                            NutritionMacroRow(metric: metric)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 14)
                }

                Button {
                    isShowingDetails = true
                } label: {
                    Text("Tùy chỉnh mục tiêu")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(AppTheme.ColorToken.primary)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.compactCard, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .appCard(radius: AppTheme.Radius.card)
        }
        .sheet(isPresented: $isShowingDetails) {
            NutritionGoalDetailsSheet(profile: profile)
        }
    }
}

private struct MacroCalorieRing: View {
    let nutrition: NutritionProfile
    let metrics: [NutritionMacroMetric]
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.ColorToken.disabledFill.opacity(0.65), lineWidth: 12)

            ForEach(Array(metrics.enumerated()), id: \.element.id) { index, metric in
                Circle()
                    .trim(from: startFraction(at: index), to: endFraction(at: index))
                    .stroke(
                        metric.color,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }

            VStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.ColorToken.calories)
                    .frame(width: 28, height: 28)
                    .background(AppTheme.ColorToken.calories.opacity(0.10))
                    .clipShape(Circle())
                Text("\(Int(nutrition.targetCalories))")
                    .font(.headline.bold())
                Text("kcal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
    }

    private func startFraction(at index: Int) -> CGFloat {
        let percent = metrics.prefix(index).reduce(0) { $0 + $1.percent }
        return CGFloat(percent / 100)
    }

    private func endFraction(at index: Int) -> CGFloat {
        let percent = metrics.prefix(index + 1).reduce(0) { $0 + $1.percent }
        return CGFloat(percent / 100)
    }
}

private struct NutritionMacroRow: View {
    let metric: NutritionMacroMetric

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: metric.symbolName)
                .font(.caption.bold())
                .foregroundStyle(metric.color)
                .frame(width: 24, height: 24)
                    .background(metric.color.opacity(0.12))
                    .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(metric.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(Int(metric.percent))% (\(Int(metric.grams))g)")
                    .font(.subheadline.bold())
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct NutritionGoalDetailsSheet: View {
    @Bindable var profile: UserProfileModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AuthSessionStore.self) private var authStore

    @State private var proteinPercent: Double
    @State private var carbsPercent: Double
    @State private var fatPercent: Double

    init(profile: UserProfileModel) {
        self.profile = profile
        _proteinPercent = State(initialValue: profile.proteinMacroPercent)
        _carbsPercent = State(initialValue: profile.carbsMacroPercent)
        _fatPercent = State(initialValue: profile.fatMacroPercent)
    }

    private var nutrition: NutritionProfile {
        NutritionProfile(
            input: NutritionProfileInput(
                gender: profile.gender,
                age: profile.age,
                weight: profile.weight,
                targetWeight: profile.targetWeight,
                height: profile.height,
                activityLevel: ActivityLevelOption(rawValue: profile.activityLevel) ?? .sedentary,
                goal: profile.nutritionGoal,
                macroDistribution: draftDistribution
            )
        )
    }

    private var draftDistribution: MacroDistribution {
        MacroDistribution(
            proteinPercent: proteinPercent,
            carbsPercent: carbsPercent,
            fatPercent: fatPercent
        )
    }

    private var draftTargets: MacroTargets {
        draftDistribution.targets(for: nutrition.targetCalories)
    }

    private var totalPercent: Int {
        Int(round(draftDistribution.totalPercent))
    }

    private var canSave: Bool {
        draftDistribution.isValid
    }

    private var metrics: [NutritionMacroMetric] {
        NutritionMacroMetric.metrics(for: nutrition)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Thông tin dinh dưỡng")
                            .font(.title3.bold())

                        HStack(alignment: .bottom, spacing: 12) {
                            CalorieTargetColumn(calories: Int(nutrition.targetCalories))

                            ForEach(metrics) { metric in
                                MacroPercentColumn(metric: metric)
                            }
                        }
                    }
                    .padding(18)
                    .appCard(radius: AppTheme.Radius.card)

                    VStack(spacing: 0) {
                        NutritionDetailRow(
                            title: "Tỷ lệ trao đổi chất cơ bản",
                            subtitle: "BMR",
                            value: "\(Int(nutrition.bmr)) kcal"
                        )
                        Divider()
                        NutritionDetailRow(
                            title: "Tổng năng lượng tiêu thụ mỗi ngày",
                            subtitle: "TDEE",
                            value: "\(Int(nutrition.tdee)) kcal"
                        )
                        Divider()
                        NutritionDetailRow(
                            title: calorieAdjustmentTitle,
                            subtitle: calorieAdjustmentSubtitle,
                            value: calorieAdjustmentValue
                        )
                    }
                    .padding(.horizontal, 16)
                    .appCard(radius: AppTheme.Radius.card)

                    MacroEditorCard(
                        proteinPercent: $proteinPercent,
                        carbsPercent: $carbsPercent,
                        fatPercent: $fatPercent,
                        targets: draftTargets,
                        totalPercent: totalPercent,
                        isValid: canSave
                    )
                }
                .padding(20)
            }
            .appScreenBackground()
            .navigationTitle("Dinh dưỡng mục tiêu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đặt lại", action: resetToDefault)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Lưu", action: save)
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
        }
    }

    private var calorieAdjustment: Double {
        nutrition.targetCalories - nutrition.tdee
    }

    private var calorieAdjustmentTitle: String {
        if calorieAdjustment < 0 {
            return "Calo thâm hụt"
        }

        if calorieAdjustment > 0 {
            return "Calo dư"
        }

        return "Chênh lệch calo"
    }

    private var calorieAdjustmentSubtitle: String {
        if calorieAdjustment < 0 {
            return "Giảm so với TDEE"
        }

        if calorieAdjustment > 0 {
            return "Tăng so với TDEE"
        }

        return "Duy trì cân nặng"
    }

    private var calorieAdjustmentValue: String {
        "\(Int(abs(calorieAdjustment))) kcal"
    }

    private func resetToDefault() {
        let defaultDistribution = MacroDistribution.default(for: profile.nutritionGoal)
        proteinPercent = defaultDistribution.proteinPercent
        carbsPercent = defaultDistribution.carbsPercent
        fatPercent = defaultDistribution.fatPercent
    }

    private func save() {
        guard canSave else { return }
        profile.macroDistribution = draftDistribution
        try? context.save()
        syncProfile()
        dismiss()
    }

    private func syncProfile() {
        Task {
            guard let accessToken = await authStore.accessToken() else {
                return
            }

            try? await ProfileSyncService.shared.syncProfile(profile, accessToken: accessToken)
        }
    }
}

private struct MacroEditorCard: View {
    @Binding var proteinPercent: Double
    @Binding var carbsPercent: Double
    @Binding var fatPercent: Double

    let targets: MacroTargets
    let totalPercent: Int
    let isValid: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tùy chỉnh đa lượng")
                        .font(.headline.bold())
                    Text("Chỉ lưu khi tổng đúng 100%.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(totalPercent)%")
                    .font(.title3.bold())
                    .foregroundStyle(isValid ? AppTheme.ColorToken.protein : AppTheme.ColorToken.calories)
            }

            VStack(spacing: 15) {
                MacroEditorRow(
                    title: "Chất đạm",
                    symbolName: "bolt.fill",
                    color: AppTheme.ColorToken.protein,
                    grams: targets.proteinGrams,
                    value: $proteinPercent
                )
                MacroEditorRow(
                    title: "Tinh bột",
                    symbolName: "leaf.fill",
                    color: AppTheme.ColorToken.carb,
                    grams: targets.carbsGrams,
                    value: $carbsPercent
                )
                MacroEditorRow(
                    title: "Chất béo",
                    symbolName: "drop.fill",
                    color: AppTheme.ColorToken.fat,
                    grams: targets.fatGrams,
                    value: $fatPercent
                )
            }

            if !isValid {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(validationMessage)
                }
                .font(.caption.bold())
                .foregroundStyle(AppTheme.ColorToken.calories)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.ColorToken.calories.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(18)
        .appCard(radius: AppTheme.Radius.card)
    }

    private var validationMessage: String {
        if totalPercent > 100 {
            return "Đang vượt quá \(totalPercent - 100)%. Hãy giảm một chỉ số để về 100%."
        }

        return "Còn thiếu \(100 - totalPercent)%. Hãy tăng thêm chỉ số để đạt 100%."
    }
}

private struct MacroEditorRow: View {
    let title: String
    let symbolName: String
    let color: Color
    let grams: Double
    @Binding var value: Double

    var body: some View {
        VStack(spacing: 9) {
            HStack(spacing: 10) {
                Image(systemName: symbolName)
                    .font(.caption.bold())
                    .foregroundStyle(color)
                    .frame(width: 26, height: 26)
                    .background(color.opacity(0.12))
                    .clipShape(Circle())

                Text(title)
                    .font(.subheadline.bold())

                Spacer()

                Text("\(Int(round(value)))%")
                    .font(.subheadline.bold())
                    .foregroundStyle(color)
                    .contentTransition(.numericText())

                Text("(\(Int(round(grams)))g)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            Slider(value: $value, in: MacroDistribution.minimumPercent...MacroDistribution.maximumPercent, step: 1)
                .tint(color)
        }
    }
}

private struct CalorieTargetColumn: View {
    let calories: Int

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.headline.bold())
                .foregroundStyle(AppTheme.ColorToken.calories)
                .frame(width: 38, height: 38)
                .background(AppTheme.ColorToken.calories.opacity(0.10))
                .clipShape(Circle())

            Text("\(calories)")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text("Calo mục tiêu")
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MacroPercentColumn: View {
    let metric: NutritionMacroMetric

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(AppTheme.ColorToken.disabledFill.opacity(0.72), lineWidth: 7)
                Circle()
                    .trim(from: 0, to: CGFloat(metric.percent / 100))
                    .stroke(
                        metric.color,
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                Text("\(Int(metric.percent))%")
                    .font(.subheadline.bold())
            }
            .frame(width: 62, height: 62)

            Text(metric.shortTitle)
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct NutritionDetailRow: View {
    let title: String
    let subtitle: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(value)
                .font(.subheadline.bold())
        }
        .padding(.vertical, 15)
    }
}

private struct NutritionMacroMetric: Identifiable {
    let id: String
    let title: String
    let symbolName: String
    let color: Color
    let percent: Double
    let grams: Double

    var shortTitle: String {
        switch id {
        case "protein":
            return "Chất đạm"
        case "carbs":
            return "Đường bột"
        case "fat":
            return "Chất béo"
        default:
            return title
        }
    }

    static func metrics(for nutrition: NutritionProfile) -> [NutritionMacroMetric] {
        [
            NutritionMacroMetric(
                id: "protein",
                title: "Chất đạm",
                symbolName: "bolt.fill",
                color: AppTheme.ColorToken.protein,
                percent: nutrition.macroDistribution.proteinPercent,
                grams: nutrition.proteinGrams
            ),
            NutritionMacroMetric(
                id: "carbs",
                title: "Tinh bột",
                symbolName: "leaf.fill",
                color: AppTheme.ColorToken.carb,
                percent: nutrition.macroDistribution.carbsPercent,
                grams: nutrition.carbsGrams
            ),
            NutritionMacroMetric(
                id: "fat",
                title: "Chất béo",
                symbolName: "drop.fill",
                color: AppTheme.ColorToken.fat,
                percent: nutrition.macroDistribution.fatPercent,
                grams: nutrition.fatGrams
            )
        ]
    }
}
