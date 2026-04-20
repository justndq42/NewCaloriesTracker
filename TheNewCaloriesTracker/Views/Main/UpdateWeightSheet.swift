import SwiftUI
import SwiftData

struct UpdateWeightSheet: View {
    let profile: UserProfileModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var weightText: String
    @State private var draftWeight: Double
    @State private var isEditingManually = false
    @FocusState private var isWeightFieldFocused: Bool

    private var isDraftWeightValid: Bool {
        (20...300).contains(draftWeight)
    }

    private var weightDisplay: String {
        formattedWeight(draftWeight)
    }

    private var weightUpdatedLabel: String {
        let date = profile.weightUpdatedAt ?? Date()
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    init(profile: UserProfileModel) {
        self.profile = profile
        _weightText = State(initialValue: String(format: "%.1f", profile.weight))
        _draftWeight = State(initialValue: profile.weight)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer(minLength: 8)

                Text("Cân nặng hiện tại")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 18) {
                    adjustmentButton(symbol: "minus", action: decrementWeight)

                    VStack(spacing: 10) {
                        Button(action: beginManualEditing) {
                            VStack(spacing: 4) {
                                Text(weightDisplay)
                                    .font(.system(size: 42, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                                Text("kg")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)

                        if isEditingManually {
                            TextField("Nhập cân nặng", text: $weightText)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .multilineTextAlignment(.center)
                                .font(.headline)
                                .focused($isWeightFieldFocused)
                                .frame(maxWidth: 180)
                                .onChange(of: weightText) { _, newValue in
                                    syncDraftWeight(from: newValue)
                                }
                        } else {
                            Text("Chạm vào số cân để nhập trực tiếp")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    adjustmentButton(symbol: "plus", action: incrementWeight)
                }
                .padding(.horizontal, 20)

                VStack(spacing: 6) {
                    Text("Ngày cập nhật")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(weightUpdatedLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.gray.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 20)

                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("Cập nhật cân nặng")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Lưu", action: saveWeight)
                        .fontWeight(.semibold)
                        .disabled(!isDraftWeightValid)
                }
            }
            .onAppear {
                weightText = formattedWeight(draftWeight)
            }
        }
    }

    @ViewBuilder
    private func adjustmentButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: 48, height: 48)
                .background(Color.gray.opacity(0.1))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func beginManualEditing() {
        isEditingManually = true
        isWeightFieldFocused = true
    }

    private func incrementWeight() {
        draftWeight = normalizedWeight(draftWeight + 0.1)
        weightText = formattedWeight(draftWeight)
        isEditingManually = false
    }

    private func decrementWeight() {
        draftWeight = normalizedWeight(draftWeight - 0.1)
        weightText = formattedWeight(draftWeight)
        isEditingManually = false
    }

    private func syncDraftWeight(from text: String) {
        let normalizedText = text.replacingOccurrences(of: ",", with: ".")
        guard let parsedWeight = Double(normalizedText) else { return }
        draftWeight = normalizedWeight(parsedWeight)
    }

    private func normalizedWeight(_ value: Double) -> Double {
        let clampedValue = min(max(value, 20), 300)
        return (clampedValue * 10).rounded() / 10
    }

    private func formattedWeight(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private func saveWeight() {
        guard isDraftWeightValid else { return }
        profile.weight = draftWeight
        profile.weightUpdatedAt = Date()
        try? context.save()
        dismiss()
    }
}
