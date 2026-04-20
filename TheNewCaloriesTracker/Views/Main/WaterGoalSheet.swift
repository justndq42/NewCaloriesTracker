import SwiftUI

struct WaterGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var waterStore = WaterIntakeStore.shared
    @State private var selectedGoal = WaterIntakeStore.shared.dailyGoal
    @State private var customGoalText = ""

    private let options = [2_000, 2_500, 3_000, 3_500, 4_000]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Dùng mốc gợi ý hoặc tự nhập mục tiêu riêng của bạn.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Mục tiêu mỗi ngày") {
                    ForEach(options, id: \.self) { goal in
                        Button {
                            selectedGoal = goal
                            customGoalText = "\(goal)"
                        } label: {
                            HStack {
                                Text(goalLabel(goal))
                                    .foregroundStyle(.primary)
                                Spacer()
                                if resolvedGoal == goal {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }

                Section("Tuỳ chỉnh") {
                    TextField("Nhập mục tiêu nước (ml)", text: $customGoalText)
                        .keyboardType(.numberPad)

                    if let resolvedGoal {
                        Text("Mục tiêu sẽ là \(goalLabel(resolvedGoal)) mỗi ngày")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Nhập tối thiểu 1000 ml")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Mục tiêu nước")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                customGoalText = "\(selectedGoal)"
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Lưu") {
                        guard let resolvedGoal else { return }
                        waterStore.dailyGoal = resolvedGoal
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(resolvedGoal == nil)
                }
            }
        }
    }

    private var resolvedGoal: Int? {
        let trimmed = customGoalText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let goal = Int(trimmed), goal >= 1_000 else {
            return nil
        }
        return goal
    }

    private func goalLabel(_ goal: Int) -> String {
        let liters = Double(goal) / 1_000
        return liters.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(liters))L"
            : String(format: "%.1fL", liters)
    }
}
