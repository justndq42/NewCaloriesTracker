import SwiftUI

struct OnboardingStep3: View {
    @Bindable var vm: OnboardingViewModel
    let onFinish: () -> Void
    
    let goals: [(String, String, String)] = [
        ("lose",     "🏃 Giảm cân",  "Thâm hụt 500 kcal/ngày"),
        ("maintain", "⚖️ Duy trì",   "Giữ nguyên cân nặng"),
        ("gain",     "💪 Tăng cơ",   "Thặng dư 300 kcal/ngày"),
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mục tiêu của bạn 🎯").font(.largeTitle.bold())
                    Text("Chúng tôi sẽ tính lượng calo phù hợp")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                
                // Goal selection
                VStack(spacing: 12) {
                    ForEach(goals, id: \.0) { goal in
                        Button {
                            withAnimation(.spring()) { vm.goal = goal.0 }
                        } label: {
                            HStack(spacing: 16) {
                                Text(goal.1.components(separatedBy: " ").first ?? "")
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(vm.goal == goal.0 ? Color.black : Color.gray.opacity(0.08))
                                    .cornerRadius(12)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(goal.1.components(separatedBy: " ").dropFirst().joined(separator: " "))
                                        .font(.subheadline.bold())
                                    Text(goal.2).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if vm.goal == goal.0 {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.black).font(.title3)
                                }
                            }
                            .padding(16)
                            .background(vm.goal == goal.0 ? Color.black.opacity(0.05) : Color.white)
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke(vm.goal == goal.0 ? Color.black : Color.gray.opacity(0.15), lineWidth: 1.5))
                            .foregroundColor(.primary)
                        }
                    }
                }
                
                // TDEE Result Card
                VStack(spacing: 16) {
                    Text("Chỉ số của \(vm.name)").font(.headline).foregroundStyle(.secondary)
                    
                    HStack(spacing: 0) {
                        TDEEStatItem(label: "BMR",  value: "\(Int(vm.bmr))",  unit: "kcal")
                        Divider().frame(height: 40)
                        TDEEStatItem(label: "TDEE", value: "\(Int(vm.tdee))", unit: "kcal")
                    }
                    
                    VStack(spacing: 4) {
                        Text("Mục tiêu hàng ngày").font(.caption).foregroundStyle(.secondary)
                        Text("\(Int(vm.targetCalories)) kcal")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(24)
                
                // Buttons
                HStack(spacing: 12) {
                    Button {
                        withAnimation { vm.currentStep = 2 }
                    } label: {
                        Text("← Quay lại")
                            .frame(maxWidth: .infinity).padding(16)
                            .background(Color.gray.opacity(0.1))
                            .foregroundColor(.primary).cornerRadius(16).font(.headline)
                    }
                    Button(action: onFinish) {
                        Text("Bắt đầu! 🚀")
                            .frame(maxWidth: .infinity).padding(16)
                            .background(Color.black)
                            .foregroundColor(.white).cornerRadius(16).font(.headline)
                    }
                }
            }
            .padding(24)
        }
    }
}

struct TDEEStatItem: View {
    let label: String; let value: String; let unit: String
    var body: some View {
        VStack(spacing: 4) {
            Text(label).font(.caption).foregroundColor(.white.opacity(0.6))
            Text(value).font(.title2.bold())
            Text(unit).font(.caption2).foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}
