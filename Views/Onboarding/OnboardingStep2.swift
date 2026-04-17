import SwiftUI

struct OnboardingStep2: View {
    @Bindable var vm: OnboardingViewModel
    
    let activities = [
        ("🪑", "Ít vận động",  "Ngồi văn phòng, ít đi lại"),
        ("🚶", "Nhẹ",          "Tập 1–3 ngày/tuần"),
        ("🏃", "Vừa",          "Tập 3–5 ngày/tuần"),
        ("💪", "Cao",          "Tập 6–7 ngày/tuần"),
        ("🏋️", "Rất cao",     "VĐV, lao động nặng"),
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mức độ vận động 🏃").font(.largeTitle.bold())
                    Text("Chọn mức phù hợp với lối sống của bạn")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                
                VStack(spacing: 12) {
                    ForEach(0..<activities.count, id: \.self) { i in
                        let act = activities[i]
                        Button {
                            withAnimation(.spring()) { vm.activityLevel = i }
                        } label: {
                            HStack(spacing: 16) {
                                Text(act.0).font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(vm.activityLevel == i ? Color.black : Color.gray.opacity(0.08))
                                    .cornerRadius(12)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(act.1).font(.subheadline.bold())
                                    Text(act.2).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if vm.activityLevel == i {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.black).font(.title3)
                                }
                            }
                            .padding(16)
                            .background(vm.activityLevel == i ? Color.black.opacity(0.05) : Color.white)
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke(vm.activityLevel == i ? Color.black : Color.gray.opacity(0.15), lineWidth: 1.5))
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
