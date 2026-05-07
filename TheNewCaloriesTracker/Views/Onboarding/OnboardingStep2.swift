import SwiftUI

struct OnboardingStep2: View {
    @Bindable var vm: OnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mức độ vận động").font(.largeTitle.bold())
                    Text("Chọn mức phù hợp với lối sống của bạn")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                
                VStack(spacing: 12) {
                    ForEach(ActivityLevelOption.allCases) { activity in
                        Button {
                            withAnimation(.spring()) { vm.activityLevel = activity.rawValue }
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: activity.symbolName)
                                    .font(.title2.weight(.semibold))
                                    .foregroundStyle(vm.activityLevel == activity.rawValue ? .white : AppTheme.ColorToken.primary)
                                    .frame(width: 44, height: 44)
                                    .background(vm.activityLevel == activity.rawValue ? AppTheme.ColorToken.primary : AppTheme.ColorToken.mutedFill)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(activity.shortTitle).font(.subheadline.bold())
                                    Text(activity.shortDescription).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if vm.activityLevel == activity.rawValue {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppTheme.ColorToken.primary).font(.title3)
                                }
                            }
                            .padding(16)
                            .background(vm.activityLevel == activity.rawValue ? AppTheme.ColorToken.selectedFill : AppTheme.ColorToken.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke(vm.activityLevel == activity.rawValue ? AppTheme.ColorToken.primary : AppTheme.ColorToken.divider, lineWidth: 1.5))
                            .foregroundStyle(AppTheme.ColorToken.primary)
                        }
                    }
                }
                
                HStack(spacing: 12) {
                    Button {
                        withAnimation { vm.currentStep = 1 }
                    } label: {
                        Text("← Quay lại")
                            .appSecondaryButtonStyle()
                    }
                    Button {
                        withAnimation { vm.currentStep = 3 }
                    } label: {
                        Text("Tiếp theo →")
                            .appPrimaryButtonStyle()
                    }
                }
            }
            .padding(24)
        }
    }
}
