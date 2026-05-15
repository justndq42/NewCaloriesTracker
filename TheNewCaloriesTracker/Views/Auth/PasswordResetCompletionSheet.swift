import SwiftUI

struct PasswordResetCompletionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthSessionStore.self) private var authStore

    let deepLink: PasswordResetDeepLink

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSubmitting = false
    @State private var isComplete = false
    @State private var errorMessage: String?

    private var canSubmit: Bool {
        newPassword.count >= 6
            && newPassword == confirmPassword
            && !isSubmitting
            && deepLink.hasCredential
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                VStack(spacing: 14) {
                    AppIconBadge(
                        systemName: isComplete ? "checkmark.circle.fill" : "key.fill",
                        color: isComplete ? AppTheme.ColorToken.protein : AppTheme.ColorToken.primary,
                        size: 58
                    )

                    VStack(spacing: 8) {
                        Text(isComplete ? "Mật khẩu đã cập nhật" : "Đặt mật khẩu mới")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .multilineTextAlignment(.center)

                        Text(isComplete ? "Bạn có thể đăng nhập lại bằng mật khẩu mới." : "Nhập mật khẩu mới cho tài khoản của bạn.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)

                if isComplete {
                    Button("Quay lại đăng nhập") {
                        dismiss()
                    }
                    .appPrimaryButtonStyle(radius: AppTheme.Radius.pill)
                } else {
                    VStack(spacing: 12) {
                        ResetPasswordInput(
                            title: "Mật khẩu mới",
                            icon: "lock.fill",
                            text: $newPassword
                        )

                        ResetPasswordInput(
                            title: "Nhập lại mật khẩu",
                            icon: "checkmark.shield.fill",
                            text: $confirmPassword
                        )
                    }

                    if newPassword.count > 0, newPassword.count < 6 {
                        ResetPasswordMessage(
                            message: "Mật khẩu cần tối thiểu 6 ký tự.",
                            color: AppTheme.ColorToken.calories,
                            icon: "exclamationmark.triangle.fill"
                        )
                    } else if !confirmPassword.isEmpty, newPassword != confirmPassword {
                        ResetPasswordMessage(
                            message: "Hai mật khẩu chưa trùng nhau.",
                            color: AppTheme.ColorToken.calories,
                            icon: "exclamationmark.triangle.fill"
                        )
                    }

                    if let errorMessage {
                        ResetPasswordMessage(
                            message: errorMessage,
                            color: AppTheme.ColorToken.calories,
                            icon: "exclamationmark.triangle.fill"
                        )
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

                            Text("Lưu mật khẩu mới")
                        }
                        .appPrimaryButtonStyle(radius: AppTheme.Radius.pill)
                    }
                    .disabled(!canSubmit)
                    .opacity(canSubmit ? 1 : 0.45)
                }

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

    private func submit() async {
        isSubmitting = true
        errorMessage = nil

        do {
            try await authStore.completePasswordReset(
                accessToken: deepLink.accessToken,
                code: deepLink.code,
                newPassword: newPassword
            )
            isComplete = true
            newPassword = ""
            confirmPassword = ""
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Chưa cập nhật được mật khẩu. Vui lòng thử lại."
        }

        isSubmitting = false
    }
}

private struct ResetPasswordInput: View {
    let title: String
    let icon: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            AppIconBadge(systemName: icon, color: AppTheme.ColorToken.primary, size: 34)

            SecureField(title, text: $text)
                .textContentType(.newPassword)
                .font(.headline)
        }
        .padding(14)
        .background(AppTheme.ColorToken.mutedFill)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.compactCard, style: .continuous))
    }
}

private struct ResetPasswordMessage: View {
    let message: String
    let color: Color
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)

            Text(message)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(color.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.compactCard, style: .continuous))
    }
}

#Preview {
    PasswordResetCompletionSheet(
        deepLink: PasswordResetDeepLink(accessToken: "preview", code: nil)
    )
    .environment(AuthSessionStore())
    .preferredColorScheme(.light)
}
