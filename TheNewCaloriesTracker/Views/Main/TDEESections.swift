import SwiftUI

struct TDEEGenderSection: View {
    @Bindable var profile: UserProfileModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Giới tính", systemImage: "person").font(.subheadline.bold())
            HStack(spacing: 10) {
                Button { profile.gender = "male" } label: {
                    Text("👨 Nam")
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(profile.gender == "male" ? Color.black : Color.gray.opacity(0.1))
                        .foregroundColor(profile.gender == "male" ? .white : .primary)
                        .cornerRadius(14)
                        .font(.subheadline.bold())
                }
                Button { profile.gender = "female" } label: {
                    Text("👩 Nữ")
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(profile.gender == "female" ? Color.black : Color.gray.opacity(0.1))
                        .foregroundColor(profile.gender == "female" ? .white : .primary)
                        .cornerRadius(14)
                        .font(.subheadline.bold())
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
    }
}

struct TDEESlidersSection: View {
    @Bindable var profile: UserProfileModel

    var body: some View {
        VStack(spacing: 16) {
            TDEESliderRow(title: "Tuổi", valueText: "\(profile.age) tuổi") {
                Slider(
                    value: Binding(
                        get: { Double(profile.age) },
                        set: { profile.age = Int($0) }
                    ),
                    in: 10...80
                )
                .tint(.black)
            }

            Divider()

            TDEESliderRow(title: "Cân nặng", valueText: String(format: "%.1f kg", profile.weight)) {
                Slider(value: $profile.weight, in: 30...200)
                    .tint(.black)
            }

            Divider()

            TDEESliderRow(title: "Chiều cao", valueText: String(format: "%.0f cm", profile.height)) {
                Slider(value: $profile.height, in: 100...220)
                    .tint(.black)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
    }
}

private struct TDEESliderRow<Control: View>: View {
    let title: String
    let valueText: String
    @ViewBuilder let control: Control

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title).font(.subheadline.bold())
                Spacer()
                Text(valueText).font(.subheadline).foregroundStyle(.secondary)
            }
            control
        }
    }
}

struct TDEEActivitySection: View {
    @Bindable var profile: UserProfileModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Mức độ vận động", systemImage: "figure.run").font(.subheadline.bold())
            ForEach(ActivityLevelOption.allCases) { activity in
                Button { profile.activityLevel = activity.rawValue } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(activity.label).font(.subheadline.bold())
                            Text(activity.description).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if profile.activityLevel == activity.rawValue {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.black)
                        }
                    }
                    .padding(12)
                    .background(profile.activityLevel == activity.rawValue ? Color.gray.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(profile.activityLevel == activity.rawValue ? Color.black : Color.gray.opacity(0.2), lineWidth: 1.5)
                    )
                    .cornerRadius(14)
                    .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
    }
}

struct TDEEGoalSection: View {
    @Bindable var profile: UserProfileModel

    private let goals = [("lose", "🏃 Giảm"), ("maintain", "⚖️ Duy trì"), ("gain", "💪 Tăng")]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Mục tiêu", systemImage: "target").font(.subheadline.bold())
            HStack(spacing: 8) {
                ForEach(goals, id: \.0) { goal in
                    Button { profile.goal = goal.0 } label: {
                        Text(goal.1)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(profile.goal == goal.0 ? Color.black : Color.gray.opacity(0.1))
                            .foregroundColor(profile.goal == goal.0 ? .white : .primary)
                            .cornerRadius(14)
                            .font(.caption.bold())
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
    }
}

struct TDEEResultSection: View {
    let nutrition: NutritionProfile

    var body: some View {
        VStack(spacing: 12) {
            TDEEResultRow(title: "BMR", value: "\(Int(nutrition.bmr)) kcal")
            Divider()
            TDEEResultRow(title: "TDEE", value: "\(Int(nutrition.tdee)) kcal")
            Divider()
            HStack {
                Text("Mục tiêu hàng ngày").font(.subheadline)
                Spacer()
                Text("\(Int(nutrition.targetCalories)) kcal").font(.title3.bold())
            }
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(20)
    }
}

private struct TDEEResultRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.subheadline.bold())
        }
    }
}

struct TDEEMacroSection: View {
    let nutrition: NutritionProfile
    let goal: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Phân bổ Macro").font(.headline.bold())

            VStack(spacing: 10) {
                MacroLevelRow(
                    level: "🔴 High Protein",
                    description: "Tăng cơ tối đa • \(String(format: "%.1f", 2.2))g/kg",
                    protein: nutrition.highProteinGrams,
                    carbs: nutrition.carbs(forProteinGrams: nutrition.highProteinGrams),
                    fat: nutrition.fatGrams,
                    isSelected: goal == "gain"
                )
                MacroLevelRow(
                    level: "🟡 Medium Protein",
                    description: "Duy trì cơ bắp • \(String(format: "%.1f", 1.6))g/kg",
                    protein: nutrition.mediumProteinGrams,
                    carbs: nutrition.carbs(forProteinGrams: nutrition.mediumProteinGrams),
                    fat: nutrition.fatGrams,
                    isSelected: goal == "maintain"
                )
                MacroLevelRow(
                    level: "🟢 Low Protein",
                    description: "Giảm cân • \(String(format: "%.1f", 1.2))g/kg",
                    protein: nutrition.lowProteinGrams,
                    carbs: nutrition.carbs(forProteinGrams: nutrition.lowProteinGrams),
                    fat: nutrition.fatGrams,
                    isSelected: goal == "lose"
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Khuyến nghị cho bạn").font(.subheadline.bold())
                MacroBar(
                    protein: nutrition.proteinGrams,
                    carbs: nutrition.carbsGrams,
                    fat: nutrition.fatGrams,
                    totalCalories: nutrition.targetCalories
                )
            }
            .padding(16)
            .background(Color.black)
            .cornerRadius(16)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
    }
}
