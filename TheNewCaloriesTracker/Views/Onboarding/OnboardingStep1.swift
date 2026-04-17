import SwiftUI

struct OnboardingStep1: View {
    @Bindable var vm: OnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Xin chào! 👋").font(.largeTitle.bold())
                    Text("Hãy cho chúng tôi biết một chút về bạn")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                
                // Name
                VStack(alignment: .leading, spacing: 10) {
                    Label("Tên của bạn", systemImage: "person").font(.subheadline.bold())
                    TextField("Nhập tên...", text: $vm.name)
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1))
                }
                
                // Gender
                VStack(alignment: .leading, spacing: 10) {
                    Label("Giới tính", systemImage: "person.2").font(.subheadline.bold())
                    HStack(spacing: 12) {
                        GenderButton(title: "👨 Nam", value: "male",   selected: $vm.gender)
                        GenderButton(title: "👩 Nữ", value: "female", selected: $vm.gender)
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
                        .frame(maxWidth: .infinity).padding(16)
                        .background(vm.isStep1Valid ? Color.black : Color.gray.opacity(0.3))
                        .foregroundColor(.white).cornerRadius(16).font(.headline)
                }
                .disabled(!vm.isStep1Valid)
            }
            .padding(24)
        }
    }
}

struct GenderButton: View {
    let title: String
    let value: String
    @Binding var selected: String
    
    var body: some View {
        Button { selected = value } label: {
            Text(title).frame(maxWidth: .infinity).padding(14)
                .background(selected == value ? Color.black : Color.white)
                .foregroundColor(selected == value ? .white : .primary)
                .cornerRadius(14).font(.subheadline.bold())
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(selected == value ? Color.black : Color.gray.opacity(0.2), lineWidth: 1.5))
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
            Slider(value: $value, in: range).tint(.black)
        }
        .padding(16).background(Color.white).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }
}
