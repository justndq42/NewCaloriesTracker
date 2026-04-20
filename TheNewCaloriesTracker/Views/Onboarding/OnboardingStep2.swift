import SwiftUI

struct OnboardingStep2: View {
    @Bindable var vm: OnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mức độ vận động 🏃").font(.largeTitle.bold())
                    Text("Chọn mức phù hợp với lối sống của bạn")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                
                VStack(spacing: 12) {
                    ForEach(ActivityLevelOption.allCases) { activity in
                        Button {
                            withAnimation(.spring()) { vm.activityLevel = activity.rawValue }
                        } label: {
                            HStack(spacing: 16) {
                                Text(activity.icon).font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(vm.activityLevel == activity.rawValue ? Color.black : Color.gray.opacity(0.08))
                                    .cornerRadius(12)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(activity.shortTitle).font(.subheadline.bold())
                                    Text(activity.shortDescription).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if vm.activityLevel == activity.rawValue {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.black).font(.title3)
                                }
                            }
                            .padding(16)
                            .background(vm.activityLevel == activity.rawValue ? Color.black.opacity(0.05) : Color.white)
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke(vm.activityLevel == activity.rawValue ? Color.black : Color.gray.opacity(0.15), lineWidth: 1.5))
                            .foregroundColor(.primary)
                        }
                    }
                }
                
                HStack(spacing: 12) {
                    Button {
                        withAnimation { vm.currentStep = 1 }
                    } label: {
                        Text("← Quay lại")
                            .frame(maxWidth: .infinity).padding(16)
                            .background(Color.gray.opacity(0.1))
                            .foregroundColor(.primary).cornerRadius(16).font(.headline)
                    }
                    Button {
                        withAnimation { vm.currentStep = 3 }
                    } label: {
                        Text("Tiếp theo →")
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
