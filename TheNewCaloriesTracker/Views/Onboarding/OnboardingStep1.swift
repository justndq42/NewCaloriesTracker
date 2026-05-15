import SwiftUI

struct OnboardingStep1: View {
    @Bindable var vm: OnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Thông tin thể chất").font(.largeTitle.bold())
                    Text("Nhập các chỉ số cơ bản để tính mục tiêu phù hợp")
                        .font(.subheadline).foregroundStyle(.secondary)
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
                    StepperValueCard(
                        value: Binding(
                            get: { Double(vm.age) },
                            set: { vm.age = Int($0.rounded()) }
                        ),
                        range: 10...80,
                        step: 1,
                        unit: "tuổi",
                        decimalPlaces: 0
                    )
                }
                
                // Weight
                VStack(alignment: .leading, spacing: 10) {
                    Label("Cân nặng", systemImage: "scalemass").font(.subheadline.bold())
                    StepperValueCard(
                        value: $vm.weight,
                        range: 30...200,
                        step: 0.1,
                        unit: "kg",
                        decimalPlaces: 1
                    )
                }
                
                // Height
                VStack(alignment: .leading, spacing: 10) {
                    Label("Chiều cao", systemImage: "ruler").font(.subheadline.bold())
                    StepperValueCard(
                        value: $vm.height,
                        range: 100...220,
                        step: 1,
                        unit: "cm",
                        decimalPlaces: 0
                    )
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
                        .background(AppTheme.ColorToken.primary)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.compactCard, style: .continuous))
                }
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

struct StepperValueCard: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    let decimalPlaces: Int
    @State private var inputText: String
    @FocusState private var isEditing: Bool

    init(
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        unit: String,
        decimalPlaces: Int
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.unit = unit
        self.decimalPlaces = decimalPlaces
        self._inputText = State(initialValue: Self.formatted(value.wrappedValue, decimalPlaces: decimalPlaces))
    }
    
    var body: some View {
        HStack(spacing: 14) {
            stepButton(systemName: "minus") {
                updateValue(by: -step)
            }
            .disabled(value <= range.lowerBound)

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                TextField("0", text: $inputText)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .keyboardType(decimalPlaces == 0 ? .numberPad : .decimalPad)
                    .multilineTextAlignment(.center)
                    .focused($isEditing)
                    .frame(width: decimalPlaces == 0 ? 64 : 84)
                    .padding(.vertical, 6)
                    .background(AppTheme.ColorToken.selectedFill)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .onChange(of: inputText) { _, newValue in
                        updateFromInput(newValue)
                    }
                    .onChange(of: value) { _, newValue in
                        guard !isEditing else { return }
                        inputText = Self.formatted(newValue, decimalPlaces: decimalPlaces)
                    }
                    .onChange(of: isEditing) { _, editing in
                        if editing {
                            inputText = Self.editingText(value, decimalPlaces: decimalPlaces)
                        } else {
                            commitInput()
                        }
                    }
                Text(unit)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            stepButton(systemName: "plus") {
                updateValue(by: step)
            }
            .disabled(value >= range.upperBound)
        }
        .padding(16)
        .background(AppTheme.ColorToken.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(AppTheme.ColorToken.divider, lineWidth: 1))
    }

    private func stepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: 38, height: 38)
                .background(AppTheme.ColorToken.mutedFill)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func updateValue(by amount: Double) {
        let nextValue = min(max(value + amount, range.lowerBound), range.upperBound)
        value = roundedForStep(nextValue)
        inputText = Self.formatted(value, decimalPlaces: decimalPlaces)
    }

    private func updateFromInput(_ text: String) {
        guard isEditing, let parsedValue = parsedValue(text), range.contains(parsedValue) else {
            return
        }

        value = roundedForStep(parsedValue)
    }

    private func commitInput() {
        guard let parsedValue = parsedValue(inputText) else {
            inputText = Self.formatted(value, decimalPlaces: decimalPlaces)
            return
        }

        value = roundedForStep(min(max(parsedValue, range.lowerBound), range.upperBound))
        inputText = Self.formatted(value, decimalPlaces: decimalPlaces)
    }

    private func parsedValue(_ text: String) -> Double? {
        let normalizedText = text
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return Double(normalizedText)
    }

    private func roundedForStep(_ rawValue: Double) -> Double {
        let scaledValue = (rawValue / step).rounded() * step
        return min(max(scaledValue, range.lowerBound), range.upperBound)
    }

    private static func formatted(_ value: Double, decimalPlaces: Int) -> String {
        String(format: "%.\(decimalPlaces)f", value)
    }

    private static func editingText(_ value: Double, decimalPlaces: Int) -> String {
        decimalPlaces == 0 ? String(Int(value.rounded())) : formatted(value, decimalPlaces: decimalPlaces)
    }
}
