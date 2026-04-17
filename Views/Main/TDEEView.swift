import SwiftUI
import SwiftData

struct TDEEView: View {
    @Bindable var profile: UserProfileModel
    @Environment(\.modelContext) private var context
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    genderSection
                    slidersSection
                    activitySection
                    goalSection
                    resultSection
                    macroSection
                }
                .padding()
            }
            .navigationTitle("Chỉ số TDEE")
            .background(Color.gray.opacity(0.07))
            .onChange(of: profile.gender)        { try? context.save() }
            .onChange(of: profile.age)           { try? context.save() }
            .onChange(of: profile.weight)        { try? context.save() }
            .onChange(of: profile.height)        { try? context.save() }
            .onChange(of: profile.activityLevel) { try? context.save() }
            .onChange(of: profile.goal)          { try? context.save() }
        }
    }
    
    var genderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Giới tính", systemImage: "person").font(.subheadline.bold())
            HStack(spacing: 10) {
                Button { profile.gender = "male" } label: {
                    Text("👨 Nam").frame(maxWidth: .infinity).padding(12)
                        .background(profile.gender == "male" ? Color.black : Color.gray.opacity(0.1))
                        .foregroundColor(profile.gender == "male" ? .white : .primary)
                        .cornerRadius(14).font(.subheadline.bold())
                }
                Button { profile.gender = "female" } label: {
                    Text("👩 Nữ").frame(maxWidth: .infinity).padding(12)
                        .background(profile.gender == "female" ? Color.black : Color.gray.opacity(0.1))
                        .foregroundColor(profile.gender == "female" ? .white : .primary)
                        .cornerRadius(14).font(.subheadline.bold())
                }
            }
        }
        .padding().background(Color.white).cornerRadius(20)
    }
    
    var slidersSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                HStack {
                    Text("Tuổi").font(.subheadline.bold())
                    Spacer()
                    Text("\(profile.age) tuổi").font(.subheadline).foregroundStyle(.secondary)
                }
                Slider(value: Binding(get: { Double(profile.age) }, set: { profile.age = Int($0) }),
                       in: 10...80).tint(.black)
            }
            Divider()
            VStack(spacing: 8) {
                HStack {
                    Text("Cân nặng").font(.subheadline.bold())
                    Spacer()
                    Text(String(format: "%.1f kg", profile.weight)).font(.subheadline).foregroundStyle(.secondary)
                }
                Slider(value: $profile.weight, in: 30...200).tint(.black)
            }
            Divider()
            VStack(spacing: 8) {
                HStack {
                    Text("Chiều cao").font(.subheadline.bold())
                    Spacer()
                    Text(String(format: "%.0f cm", profile.height)).font(.subheadline).foregroundStyle(.secondary)
                }
                Slider(value: $profile.height, in: 100...220).tint(.black)
            }
        }
        .padding().background(Color.white).cornerRadius(20)
    }
    
    var activitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Mức độ vận động", systemImage: "figure.run").font(.subheadline.bold())
            ForEach(0..<UserProfileModel.activityLabels.count, id: \.self) { i in
                Button { profile.activityLevel = i } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(UserProfileModel.activityLabels[i]).font(.subheadline.bold())
                            Text(UserProfileModel.activityDescriptions[i]).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if profile.activityLevel == i {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.black)
                        }
                    }
                    .padding(12)
                    .background(profile.activityLevel == i ? Color.gray.opacity(0.1) : Color.clear)
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(profile.activityLevel == i ? Color.black : Color.gray.opacity(0.2), lineWidth: 1.5))
                    .cornerRadius(14).foregroundColor(.primary)
                }
            }
        }
        .padding().background(Color.white).cornerRadius(20)
    }
    
    var goalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Mục tiêu", systemImage: "target").font(.subheadline.bold())
            HStack(spacing: 8) {
                ForEach([("lose","🏃 Giảm"),("maintain","⚖️ Duy trì"),("gain","💪 Tăng")], id: \.0) { g in
                    Button { profile.goal = g.0 } label: {
                        Text(g.1).frame(maxWidth: .infinity).padding(12)
                            .background(profile.goal == g.0 ? Color.black : Color.gray.opacity(0.1))
                            .foregroundColor(profile.goal == g.0 ? .white : .primary)
                            .cornerRadius(14).font(.caption.bold())
                    }
                }
            }
        }
        .padding().background(Color.white).cornerRadius(20)
    }
    
    var resultSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("BMR").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(profile.bmr)) kcal").font(.subheadline.bold())
            }
            Divider()
            HStack {
                Text("TDEE").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(profile.tdee)) kcal").font(.subheadline.bold())
            }
            Divider()
            HStack {
                Text("Mục tiêu hàng ngày").font(.subheadline)
                Spacer()
                Text("\(Int(profile.targetCalories)) kcal").font(.title3.bold())
            }
        }
        .padding().background(Color.gray.opacity(0.08)).cornerRadius(20)
    }
    
    var macroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
                Text("Phân bổ Macro").font(.headline.bold())

                // 3 mức protein
                VStack(spacing: 10) {
                    MacroLevelRow(
                        level: "🔴 High Protein",
                        description: "Tăng cơ tối đa • \(String(format: "%.1f", 2.2))g/kg",
                        protein: profile.highProteinGrams,
                        carbs:   profile.carbsForProtein(profile.highProteinGrams),
                        fat:     profile.fatGrams,
                        isSelected: profile.goal == "gain"
                    )
                    MacroLevelRow(
                        level: "🟡 Medium Protein",
                        description: "Duy trì cơ bắp • \(String(format: "%.1f", 1.6))g/kg",
                        protein: profile.medProteinGrams,
                        carbs:   profile.carbsForProtein(profile.medProteinGrams),
                        fat:     profile.fatGrams,
                        isSelected: profile.goal == "maintain"
                    )
                    MacroLevelRow(
                        level: "🟢 Low Protein",
                        description: "Giảm cân • \(String(format: "%.1f", 1.2))g/kg",
                        protein: profile.lowProteinGrams,
                        carbs:   profile.carbsForProtein(profile.lowProteinGrams),
                        fat:     profile.fatGrams,
                        isSelected: profile.goal == "lose"
                    )
                }

                // Recommended macro bar
                VStack(alignment: .leading, spacing: 8) {
                    Text("Khuyến nghị cho bạn").font(.subheadline.bold())
                    MacroBar(
                        protein: profile.proteinGrams,
                        carbs: profile.carbsGrams,
                        fat: profile.fatGrams,
                        totalCalories: profile.targetCalories
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

        // Helper
        var weight: Double { profile.weight }

        func carbsFor(proteinMultiplier: Double) -> Double {
            let proteinCal = (weight * proteinMultiplier) * 4
            let fatCal = profile.fatGrams * 9
            let carbsCal = profile.targetCalories - proteinCal - fatCal
            return max(0, carbsCal / 4)
        }
    }

