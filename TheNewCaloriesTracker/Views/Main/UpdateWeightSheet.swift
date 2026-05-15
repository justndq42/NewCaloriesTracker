import SwiftUI
import SwiftData

struct UpdateWeightSheet: View {
    let profile: UserProfileModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AuthSessionStore.self) private var authStore

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
            ScrollView {
                VStack(spacing: AppTheme.Spacing.section) {
                    VStack(spacing: 8) {
                        AppIconBadge(systemName: "scalemass.fill", color: AppTheme.ColorToken.primary, size: 42)
                        Text("Cân nặng hiện tại")
                            .font(.title3.bold())
                        Text("Dùng +/- để chỉnh nhanh 0.1kg hoặc chạm vào số cân để nhập.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(AppTheme.Spacing.card)
                    .appCard(radius: AppTheme.Radius.card, shadow: true)

                    HStack(spacing: 18) {
                        adjustmentButton(symbol: "minus", action: decrementWeight)

                        VStack(spacing: 10) {
                            Button(action: beginManualEditing) {
                                VStack(spacing: 4) {
                                    Text(weightDisplay)
                                        .font(.system(size: 46, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppTheme.ColorToken.primary)
                                        .contentTransition(.numericText())
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
                                    .multilineTextAlignment(.center)
                                    .font(.headline)
                                    .focused($isWeightFieldFocused)
                                    .padding(12)
                                    .frame(maxWidth: 180)
                                    .background(AppTheme.ColorToken.mutedFill)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .onChange(of: weightText) { _, newValue in
                                        syncDraftWeight(from: newValue)
                                    }
                            } else {
                                Text("Chạm để nhập trực tiếp")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        adjustmentButton(symbol: "plus", action: incrementWeight)
                    }
                    .padding(AppTheme.Spacing.card)
                    .appCard(radius: AppTheme.Radius.card, shadow: true)

                    VStack(spacing: 6) {
                        Text("Ngày cập nhật")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(weightUpdatedLabel)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.ColorToken.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.ColorToken.mutedFill)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.compactCard, style: .continuous))
                }
                .padding(AppTheme.Spacing.screen)
            }
            .appScreenBackground()
            .navigationTitle("Cập nhật cân nặng")
            .navigationBarTitleDisplayMode(.inline)
            .presentationBackground(AppTheme.ColorToken.screenBackground)
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
                .foregroundStyle(AppTheme.ColorToken.primary)
                .frame(width: 48, height: 48)
                .background(AppTheme.ColorToken.mutedFill)
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
        guard let parsedWeight = DecimalTextParser.double(from: text) else { return }
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
        let updatedAt = Date()
        profile.weightUpdatedAt = updatedAt
        try? context.save()
        syncWeightLog(weight: draftWeight, recordedAt: updatedAt)
        syncProfile()
        dismiss()
    }

    private func syncWeightLog(weight: Double, recordedAt: Date) {
        Task {
            guard let userID = authStore.user?.id,
                  let accessToken = await authStore.accessToken() else {
                return
            }

            try? await WeightLogSyncService.shared.syncWeight(
                weight,
                recordedAt: recordedAt,
                userID: userID,
                accessToken: accessToken
            )
        }
    }

    private func syncProfile() {
        Task {
            guard let accessToken = await authStore.accessToken() else {
                return
            }

            try? await ProfileSyncService.shared.syncProfile(profile, accessToken: accessToken)
        }
    }
}
