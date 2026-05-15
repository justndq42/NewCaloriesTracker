import SwiftUI
import SwiftData

struct AccountView: View {
    @Environment(\.modelContext) private var context
    @Environment(AuthSessionStore.self) private var authStore

    let profile: UserProfileModel
    @State private var isShowingChangePassword = false
    @State private var isShowingDeleteAccount = false
    @State private var securityMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.section) {
                    AccountHeaderCard(profile: profile)
                    AccountBodyStats(profile: profile)

                    NavigationLink {
                        PhysicalProfileView(profile: profile)
                    } label: {
                        HStack {
                            Text("Hồ sơ thể chất")
                                .font(.headline.bold())
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .background(AppTheme.ColorToken.primary)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.compactCard, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    AccountNutritionGoalSection(profile: profile)

                    AccountSecuritySection(
                        message: securityMessage,
                        onChangePassword: { isShowingChangePassword = true },
                        onDeleteAccount: { isShowingDeleteAccount = true }
                    )

                    SignOutButton {
                        authStore.signOut()
                    }
                }
                .padding(AppTheme.Spacing.screen)
                .padding(.bottom, 88)
            }
            .appScreenBackground()
            .navigationTitle("Tài khoản")
            .sheet(isPresented: $isShowingChangePassword) {
                ChangePasswordSheet { message in
                    securityMessage = message
                }
                .environment(authStore)
            }
            .sheet(isPresented: $isShowingDeleteAccount) {
                DeleteAccountSheet {
                    deleteLocalAccountData()
                }
                .environment(authStore)
            }
        }
    }

    private func deleteLocalAccountData() {
        guard let userID = profile.userID else {
            return
        }

        if let entries = try? context.fetch(FetchDescriptor<DiaryEntryModel>()) {
            entries
                .filter { $0.userID == userID }
                .forEach(context.delete)
        }

        if let foods = try? context.fetch(FetchDescriptor<CustomFoodModel>()) {
            foods
                .filter { $0.userID == userID }
                .forEach(context.delete)
        }

        context.delete(profile)
        try? context.save()
    }
}

private struct AccountSecuritySection: View {
    let message: String?
    let onChangePassword: () -> Void
    let onDeleteAccount: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bảo mật tài khoản")
                .font(.headline.bold())

            if let message {
                AccountSecurityMessage(message: message)
            }

            AccountSecurityActionRow(
                title: "Đổi mật khẩu",
                subtitle: "Cập nhật mật khẩu đăng nhập",
                systemImage: "key.fill",
                tint: AppTheme.ColorToken.primary,
                action: onChangePassword
            )

            AccountSecurityActionRow(
                title: "Xoá tài khoản",
                subtitle: "Xoá tài khoản và dữ liệu đã đồng bộ",
                systemImage: "trash.fill",
                tint: AppTheme.ColorToken.calories,
                action: onDeleteAccount
            )
        }
        .padding(16)
        .appCard(radius: AppTheme.Radius.card, shadow: true)
    }
}

private struct AccountSecurityMessage: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.ColorToken.protein)
            Text(message)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.ColorToken.protein)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppTheme.ColorToken.protein.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.compactCard, style: .continuous))
    }
}

private struct AccountSecurityActionRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.subheadline.bold())
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(AppTheme.ColorToken.mutedFill)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.compactCard, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct SignOutButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Đăng xuất")
            }
            .font(.headline.weight(.semibold))
            .foregroundStyle(AppTheme.ColorToken.calories)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(AppTheme.ColorToken.calories.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.compactCard, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct ChangePasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthSessionStore.self) private var authStore

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    let onComplete: (String) -> Void

    private var canSubmit: Bool {
        !currentPassword.isEmpty
            && newPassword.count >= 6
            && newPassword == confirmPassword
            && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                AccountSheetHeader(
                    title: "Đổi mật khẩu",
                    subtitle: "Nhập mật khẩu hiện tại để xác nhận thay đổi."
                )

                VStack(spacing: 12) {
                    AccountPasswordField(title: "Mật khẩu hiện tại", text: $currentPassword)
                    AccountPasswordField(title: "Mật khẩu mới", text: $newPassword)
                    AccountPasswordField(title: "Nhập lại mật khẩu mới", text: $confirmPassword)
                }

                if let validationMessage {
                    AccountInlineError(message: validationMessage)
                } else if let errorMessage {
                    AccountInlineError(message: errorMessage)
                }

                Button {
                    Task { await submit() }
                } label: {
                    HStack(spacing: 10) {
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }

                        Text("Cập nhật mật khẩu")
                    }
                    .appPrimaryButtonStyle(radius: AppTheme.Radius.pill)
                }
                .disabled(!canSubmit)
                .opacity(canSubmit ? 1 : 0.45)

                Spacer()
            }
            .padding(AppTheme.Spacing.screen)
            .appScreenBackground()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
    }

    private var validationMessage: String? {
        guard !newPassword.isEmpty || !confirmPassword.isEmpty else {
            return nil
        }

        if newPassword.count < 6 {
            return "Mật khẩu mới cần ít nhất 6 ký tự."
        }

        if newPassword != confirmPassword {
            return "Mật khẩu nhập lại chưa khớp."
        }

        return nil
    }

    private func submit() async {
        isSubmitting = true
        errorMessage = nil

        do {
            try await authStore.changePassword(
                currentPassword: currentPassword,
                newPassword: newPassword
            )
            onComplete("Mật khẩu đã được cập nhật.")
            dismiss()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Chưa đổi được mật khẩu. Vui lòng thử lại."
        }

        isSubmitting = false
    }
}

private struct DeleteAccountSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthSessionStore.self) private var authStore

    @State private var password = ""
    @State private var isDeleting = false
    @State private var errorMessage: String?

    let onDeleted: () -> Void

    private var canDelete: Bool {
        !password.isEmpty && !isDeleting
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                AccountSheetHeader(
                    title: "Xoá tài khoản",
                    subtitle: "Dữ liệu đã đồng bộ của tài khoản sẽ bị xoá. Hành động này không thể hoàn tác."
                )

                AccountPasswordField(title: "Nhập mật khẩu để xác nhận", text: $password)

                if let errorMessage {
                    AccountInlineError(message: errorMessage)
                }

                Button(role: .destructive) {
                    Task { await deleteAccount() }
                } label: {
                    HStack(spacing: 10) {
                        if isDeleting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "trash.fill")
                        }

                        Text("Xoá tài khoản")
                    }
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.ColorToken.calories)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.pill, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canDelete)
                .opacity(canDelete ? 1 : 0.45)

                Spacer()
            }
            .padding(AppTheme.Spacing.screen)
            .appScreenBackground()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
    }

    private func deleteAccount() async {
        isDeleting = true
        errorMessage = nil

        do {
            try await authStore.deleteAccount(password: password)
            onDeleted()
            dismiss()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Chưa xoá được tài khoản. Vui lòng thử lại."
        }

        isDeleting = false
    }
}

private struct AccountSheetHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.largeTitle.bold())
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AccountPasswordField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            AppIconBadge(systemName: "key.fill", color: AppTheme.ColorToken.primary, size: 34)

            SecureField(title, text: $text)
                .textContentType(.password)
                .font(.headline)
        }
        .padding(14)
        .background(AppTheme.ColorToken.mutedFill)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.compactCard, style: .continuous))
    }
}

private struct AccountInlineError: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.ColorToken.calories)

            Text(message)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.ColorToken.calories)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(AppTheme.ColorToken.calories.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.compactCard, style: .continuous))
    }
}

private struct AccountHeaderCard: View {
    let profile: UserProfileModel

    private static let joinedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "'ngày' d 'tháng' M 'năm' yyyy"
        return formatter
    }()

    private var displayName: String {
        profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Người dùng" : profile.name
    }

    var body: some View {
        HStack(spacing: 14) {
            Text(initial)
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(AppTheme.ColorToken.primary)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(displayName)
                    .font(.title3.bold())
                Text("Tham gia \(Self.joinedDateFormatter.string(from: profile.joinedAt))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(18)
        .appCard(radius: AppTheme.Radius.card, shadow: true)
    }

    private var initial: String {
        String(displayName.prefix(1)).uppercased()
    }
}

private struct AccountBodyStats: View {
    let profile: UserProfileModel

    var body: some View {
        HStack(spacing: 10) {
            AccountStatCard(title: "Tuổi", value: "\(profile.age)", unit: "tuổi")
            AccountStatCard(title: "Chiều cao", value: "\(Int(profile.height))", unit: "cm")
            AccountStatCard(title: "Cân nặng", value: formattedWeight, unit: "kg")
        }
    }

    private var formattedWeight: String {
        String(format: "%.1f", profile.weight)
    }
}

private struct AccountStatCard: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.headline.bold())
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .appCard(radius: AppTheme.Radius.compactCard)
    }
}

private struct PhysicalProfileView: View {
    @Bindable var profile: UserProfileModel
    @State private var isShowingGoalSetup = false

    private var nutrition: NutritionProfile {
        NutritionProfile(profile: profile)
    }

    private var activity: ActivityLevelOption {
        ActivityLevelOption(rawValue: profile.activityLevel) ?? .sedentary
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                PhysicalProfileHeader(profile: profile)

                VStack(spacing: 10) {
                    ProfileInfoRow(title: "Giới tính", value: genderLabel, systemImage: "person.fill")
                    ProfileInfoRow(title: "Tuổi", value: "\(profile.age) tuổi", systemImage: "calendar")
                    ProfileInfoRow(title: "Chiều cao", value: "\(Int(profile.height)) cm", systemImage: "ruler")
                }
                .padding(16)
                .appCard(radius: AppTheme.Radius.card)

                PhysicalGoalCard(profile: profile, nutrition: nutrition)
                ActivitySummaryCard(activity: activity)
                CalorieTargetCard(nutrition: nutrition)

                Button {
                    isShowingGoalSetup = true
                } label: {
                    Text("Thiết lập lại mục tiêu mới")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.ColorToken.primary)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.compactCard, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(AppTheme.Spacing.screen)
            .padding(.bottom, 88)
        }
        .appScreenBackground()
        .navigationTitle("Hồ sơ thể chất")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingGoalSetup) {
            GoalSetupSheet(profile: profile)
        }
    }

    private var genderLabel: String {
        profile.gender == "male" ? "Nam" : "Nữ"
    }
}

private struct PhysicalProfileHeader: View {
    let profile: UserProfileModel

    private var displayName: String {
        profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Người dùng" : profile.name
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(displayName)
                .font(.largeTitle.bold())
            Text("Thông tin cơ thể và mục tiêu hiện tại")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ProfileInfoRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.ColorToken.primary)
                .frame(width: 30, height: 30)
                .background(AppTheme.ColorToken.mutedFill)
                .clipShape(Circle())

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline.bold())
        }
    }
}

private struct PhysicalGoalCard: View {
    let profile: UserProfileModel
    let nutrition: NutritionProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Mục tiêu cân nặng", systemImage: profile.nutritionGoal.symbolName)
                .font(.headline.bold())

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(profile.nutritionGoal.title)
                    .font(.title3.bold())
                Spacer()
                Text("\(formatted(profile.weight)) → \(formatted(nutrition.targetWeight)) kg")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .appCard(radius: AppTheme.Radius.card)
    }

    private func formatted(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}

private struct ActivitySummaryCard: View {
    let activity: ActivityLevelOption

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Cường độ vận động", systemImage: "figure.run")
                .font(.headline.bold())

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.shortTitle)
                    .font(.title3.bold())
                Text(activity.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .appCard(radius: AppTheme.Radius.card)
    }
}

private struct CalorieTargetCard: View {
    let nutrition: NutritionProfile

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Label("Calo mục tiêu", systemImage: "flame.fill")
                    .font(.headline.bold())
                Text("Dựa trên TDEE và mục tiêu hiện tại")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(Int(nutrition.targetCalories))")
                .font(.title2.bold())
            Text("kcal")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .appCard(radius: AppTheme.Radius.card)
    }
}

private struct GoalSetupSheet: View {
    @Bindable var profile: UserProfileModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AuthSessionStore.self) private var authStore

    @State private var selectedGoal: NutritionGoal
    @State private var currentWeight: Double
    @State private var targetWeight: Double

    private var isValid: Bool {
        (20...300).contains(currentWeight) && (20...300).contains(targetWeight)
    }

    init(profile: UserProfileModel) {
        self.profile = profile
        _selectedGoal = State(initialValue: profile.nutritionGoal)
        _currentWeight = State(initialValue: profile.weight)
        _targetWeight = State(initialValue: profile.targetWeight)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    GoalPickerSection(selectedGoal: $selectedGoal)

                    VStack(spacing: 12) {
                        WeightAdjustRow(title: "Cân nặng hiện tại", value: $currentWeight)
                        Divider()
                        WeightAdjustRow(title: "Cân nặng mong muốn", value: $targetWeight)
                    }
                    .padding(16)
                    .appCard(radius: AppTheme.Radius.card)

                    Text("Cập nhật mục tiêu sẽ đồng bộ lại macro mặc định theo mục tiêu mới. Bạn vẫn có thể chỉnh macro thủ công trong phần TDEE.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(AppTheme.Spacing.screen)
            }
            .appScreenBackground()
            .navigationTitle("Mục tiêu mới")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Lưu", action: save)
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
            .onChange(of: selectedGoal) { _, newGoal in
                targetWeight = UserProfileModel.defaultTargetWeight(for: newGoal.rawValue, currentWeight: currentWeight)
            }
        }
    }

    private func save() {
        guard isValid else { return }

        profile.goal = selectedGoal.rawValue
        profile.weight = normalized(currentWeight)
        profile.targetWeight = normalized(targetWeight)
        profile.weightUpdatedAt = Date()
        profile.applyDefaultMacroDistribution()

        try? context.save()
        syncProfile()
        dismiss()
    }

    private func syncProfile() {
        Task {
            guard let accessToken = await authStore.accessToken() else {
                return
            }

            try? await ProfileSyncService.shared.syncProfile(profile, accessToken: accessToken)
        }
    }

    private func normalized(_ value: Double) -> Double {
        (min(max(value, 20), 300) * 10).rounded() / 10
    }
}

private struct GoalPickerSection: View {
    @Binding var selectedGoal: NutritionGoal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mục tiêu")
                .font(.headline.bold())

            HStack(spacing: 8) {
                ForEach(NutritionGoal.allCases) { goal in
                    Button {
                        selectedGoal = goal
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: goal.symbolName)
                                .font(.headline)
                            Text(goal.shortTitle)
                                .font(.caption.bold())
                        }
                        .foregroundStyle(selectedGoal == goal ? .white : AppTheme.ColorToken.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(selectedGoal == goal ? AppTheme.ColorToken.primary : AppTheme.ColorToken.mutedFill)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .appCard(radius: AppTheme.Radius.card)
    }
}

private struct WeightAdjustRow: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text("\(formattedValue) kg")
                    .font(.title3.bold())
            }

            Spacer()

            HStack(spacing: 8) {
                weightButton(symbol: "minus") {
                    value = normalized(value - 0.1)
                }
                weightButton(symbol: "plus") {
                    value = normalized(value + 0.1)
                }
            }
        }
    }

    private var formattedValue: String {
        String(format: "%.1f", value)
    }

    private func weightButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.caption.bold())
                .foregroundStyle(AppTheme.ColorToken.primary)
                .frame(width: 34, height: 34)
                .background(AppTheme.ColorToken.mutedFill)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func normalized(_ value: Double) -> Double {
        (min(max(value, 20), 300) * 10).rounded() / 10
    }
}
