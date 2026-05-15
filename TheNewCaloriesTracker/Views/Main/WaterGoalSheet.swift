import SwiftUI

struct WaterGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthSessionStore.self) private var authStore
    @State private var waterStore = WaterIntakeStore.shared
    @State private var selectedGoal = 3_000
    @State private var customGoalText = ""

    private let options = [2_000, 2_500, 3_000, 3_500, 4_000]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.section) {
                    VStack(alignment: .leading, spacing: 6) {
                        AppIconBadge(systemName: "drop.circle.fill", color: AppTheme.ColorToken.water, size: 42)
                        Text("Mục tiêu nước mỗi ngày")
                            .font(.title3.bold())
                        Text("Dùng mốc gợi ý hoặc tự nhập mục tiêu riêng của bạn.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppTheme.Spacing.card)
                    .appCard(radius: AppTheme.Radius.card, shadow: true)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Gợi ý nhanh")
                            .font(.headline.bold())

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(options, id: \.self) { goal in
                                goalOptionButton(goal)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tùy chỉnh")
                            .font(.headline.bold())

                        TextField("Nhập mục tiêu nước (ml)", text: $customGoalText)
                            .keyboardType(.numberPad)
                            .font(.headline)
                            .padding(14)
                            .background(AppTheme.ColorToken.mutedFill)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        Text(goalHelperText)
                            .font(.caption)
                            .foregroundStyle(resolvedGoal == nil ? AppTheme.ColorToken.calories : .secondary)
                    }
                    .padding(AppTheme.Spacing.card)
                    .appCard(radius: AppTheme.Radius.card, shadow: true)
                }
                .padding(AppTheme.Spacing.screen)
            }
            .appScreenBackground()
            .navigationTitle("Mục tiêu nước")
            .navigationBarTitleDisplayMode(.inline)
            .presentationBackground(AppTheme.ColorToken.screenBackground)
            .onAppear {
                if let userID = authStore.user?.id {
                    selectedGoal = waterStore.dailyGoal(for: userID)
                }
                customGoalText = "\(selectedGoal)"
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Lưu") {
                        guard let resolvedGoal, let userID = authStore.user?.id else { return }
                        waterStore.setDailyGoal(resolvedGoal, for: userID)
                        waterStore.markNeedsSync(on: Date(), userID: userID)
                        syncTodayWaterGoal(for: userID)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(resolvedGoal == nil)
                }
            }
        }
    }

    private var goalHelperText: String {
        if let resolvedGoal {
            return "Mục tiêu sẽ là \(goalLabel(resolvedGoal)) mỗi ngày"
        }

        return "Nhập tối thiểu 1000 ml"
    }

    private func goalOptionButton(_ goal: Int) -> some View {
        let isSelected = resolvedGoal == goal

        return Button {
            selectedGoal = goal
            customGoalText = "\(goal)"
        } label: {
            HStack {
                Text(goalLabel(goal))
                    .font(.subheadline.bold())
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.subheadline.bold())
                }
            }
            .foregroundStyle(isSelected ? .white : AppTheme.ColorToken.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(isSelected ? AppTheme.ColorToken.primary : AppTheme.ColorToken.card)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.compactCard, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.compactCard, style: .continuous)
                    .stroke(isSelected ? AppTheme.ColorToken.primary : AppTheme.ColorToken.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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

    private func syncTodayWaterGoal(for userID: String) {
        Task {
            guard let accessToken = await authStore.accessToken() else {
                return
            }

            try? await WaterLogSyncService.shared.syncLocalLog(
                on: Date(),
                userID: userID,
                accessToken: accessToken
            )
        }
    }
}
