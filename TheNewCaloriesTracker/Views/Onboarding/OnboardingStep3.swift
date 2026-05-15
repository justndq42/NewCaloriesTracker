import SwiftUI

struct OnboardingStep3: View {
    @Bindable var vm: OnboardingViewModel
    let onFinish: () -> Void
    
    private let goals: [OnboardingGoalOption] = [
        OnboardingGoalOption(id: "lose", symbolName: "arrow.down.forward.circle.fill", title: "Giảm cân", subtitle: "Thâm hụt 500 kcal/ngày"),
        OnboardingGoalOption(id: "maintain", symbolName: "equal.circle.fill", title: "Duy trì", subtitle: "Giữ nguyên cân nặng"),
        OnboardingGoalOption(id: "gain", symbolName: "arrow.up.forward.circle.fill", title: "Tăng cân", subtitle: "Thặng dư 500 kcal/ngày"),
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mục tiêu của bạn").font(.largeTitle.bold())
                    Text("Chúng tôi sẽ tính lượng calo phù hợp")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                
                // Goal selection
                VStack(spacing: 12) {
                    ForEach(goals) { goal in
                        Button {
                            withAnimation(.spring()) { vm.goal = goal.id }
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: goal.symbolName)
                                    .font(.title2.weight(.semibold))
                                    .foregroundStyle(vm.goal == goal.id ? .white : AppTheme.ColorToken.primary)
                                    .frame(width: 44, height: 44)
                                    .background(vm.goal == goal.id ? AppTheme.ColorToken.primary : AppTheme.ColorToken.mutedFill)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(goal.title)
                                        .font(.subheadline.bold())
                                    Text(goal.subtitle).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if vm.goal == goal.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppTheme.ColorToken.primary).font(.title3)
                                }
                            }
                            .padding(16)
                            .background(vm.goal == goal.id ? AppTheme.ColorToken.selectedFill : AppTheme.ColorToken.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke(vm.goal == goal.id ? AppTheme.ColorToken.primary : AppTheme.ColorToken.divider, lineWidth: 1.5))
                            .foregroundStyle(AppTheme.ColorToken.primary)
                        }
                    }
                }
                
                // TDEE Result Card
                VStack(spacing: 16) {
                    Text("Chỉ số của bạn").font(.headline).foregroundStyle(.secondary)
                    
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
                .background(AppTheme.ColorToken.primarySoft)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
                
                // Buttons
                HStack(spacing: 12) {
                    Button {
                        withAnimation { vm.currentStep = 2 }
                    } label: {
                        Text("← Quay lại")
                            .appSecondaryButtonStyle()
                    }
                    Button(action: onFinish) {
                        Text("Bắt đầu")
                            .appPrimaryButtonStyle()
                    }
                }
            }
            .padding(24)
        }
    }
}

private struct OnboardingGoalOption: Identifiable {
    let id: String
    let symbolName: String
    let title: String
    let subtitle: String
}

struct TDEEStatItem: View {
    let label: String; let value: String; let unit: String
    var body: some View {
        VStack(spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.white.opacity(0.6))
            Text(value).font(.title2.bold())
            Text(unit).font(.caption2).foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}
