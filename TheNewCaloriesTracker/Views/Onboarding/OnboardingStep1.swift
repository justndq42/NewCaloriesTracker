import SwiftUI

struct OnboardingStep1: View {
    @Bindable var vm: OnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Xin chào!").font(.largeTitle.bold())
                    Text("Hãy cho chúng tôi biết một chút về bạn")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                
                // Name
                VStack(alignment: .leading, spacing: 10) {
                    Label("Tên của bạn", systemImage: "person").font(.subheadline.bold())
                    TextField("Nhập tên...", text: $vm.name)
                        .padding(14)
                        .background(AppTheme.ColorToken.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(AppTheme.ColorToken.divider, lineWidth: 1))
                }
                
                // Gender
                VStack(alignment: .leading, spacing: 10) {
                    Label("Giới tính", systemImage: "person.2").font(.subheadline.bold())
                    HStack(spacing: 12) {
                        GenderButton(title: "Nam", systemName: "person.fill", value: "male", selected: $vm.gender)
                        GenderButton(title: "Nữ", systemName: "person.fill", value: "female", selected: $vm.gender)
                    }
                }
                
                // Age
                VStack(alignment: .leading, spacing: 10) {
                    Label("Tuổi", systemImage: "calendar").font(.subheadline.bold())
                    SliderCard(value: Binding(get: { Double(vm.age) }, set: { vm.age = Int($0) }),
                               range: 10...80, display: "\(vm.age) tuổi")
                }
                
                // Weight
                VStack(alignment: .leading, spacing: 10) {
                    Label("Cân nặng", systemImage: "scalemass").font(.subheadline.bold())
                    SliderCard(value: $vm.weight, range: 30...200,
                               display: String(format: "%.1f kg", vm.weight))
                }
                
                // Height
                VStack(alignment: .leading, spacing: 10) {
                    Label("Chiều cao", systemImage: "ruler").font(.subheadline.bold())
                    SliderCard(value: $vm.height, range: 100...220,
                               display: String(format: "%.0f cm", vm.height))
                }
                
                // Next button
                Button {
                    withAnimation { vm.currentStep = 2 }
                } label: {
                    Text("Tiếp theo →")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(vm.isStep1Valid ? AppTheme.ColorToken.primary : AppTheme.ColorToken.disabledFill)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.compactCard, style: .continuous))
                }
                .disabled(!vm.isStep1Valid)
            }
            .padding(24)
        }
    }
}

struct GenderButton: View {
    let title: String
    let systemName: String
    let value: String
    @Binding var selected: String
    
    var body: some View {
        Button { selected = value } label: {
            HStack(spacing: 6) {
                Image(systemName: systemName)
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(selected == value ? AppTheme.ColorToken.primary : AppTheme.ColorToken.card)
            .foregroundStyle(selected == value ? .white : AppTheme.ColorToken.primary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .font(.subheadline.bold())
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(selected == value ? AppTheme.ColorToken.primary : AppTheme.ColorToken.divider, lineWidth: 1.5))
        }
    }
}

struct SliderCard: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let display: String
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Spacer()
                Text(display).font(.title3.bold())
            }
            Slider(value: $value, in: range).tint(AppTheme.ColorToken.primary)
        }
        .padding(16)
        .background(AppTheme.ColorToken.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(AppTheme.ColorToken.divider, lineWidth: 1))
    }
}
