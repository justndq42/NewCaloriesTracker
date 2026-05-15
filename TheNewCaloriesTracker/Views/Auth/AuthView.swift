import SwiftUI

struct AuthView: View {
    @Environment(AuthSessionStore.self) private var authStore

    @State private var mode: AuthMode = .login
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""

    private var canSubmit: Bool {
        let hasCredentials = email.trimmingCharacters(in: .whitespacesAndNewlines).contains("@")
            && password.count >= 6

        switch mode {
        case .login:
            return hasCredentials
        case .signup:
            return hasCredentials && !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                AuthHeader(mode: mode)

                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        if mode == .signup {
                            AuthTextField(
                                title: "Tên của bạn",
                                icon: "person.fill",
                                text: $displayName,
                                keyboardType: .default,
                                textContentType: .name
                            )
                        }

                        AuthTextField(
                            title: "Email",
                            icon: "envelope.fill",
                            text: $email,
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress
                        )

                        AuthSecureInput(password: $password)
                    }

                    if let errorMessage = authStore.errorMessage {
                        AuthMessageView(message: errorMessage)
                    }

                    Button {
                        Task {
                            await submit()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            if authStore.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: mode.buttonIcon)
                            }

                            Text(mode.buttonTitle)
                        }
                        .appPrimaryButtonStyle(radius: AppTheme.Radius.pill)
                    }
                    .disabled(!canSubmit || authStore.isLoading)
                    .opacity(canSubmit ? 1 : 0.45)

                    AuthModeSwitch(mode: $mode)
                }
                .padding(18)
                .appCard(radius: 28, shadow: true)
            }
            .padding(.horizontal, AppTheme.Spacing.screen)
            .padding(.top, 72)
            .padding(.bottom, 32)
        }
        .appScreenBackground()
    }

    private func submit() async {
        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        switch mode {
        case .login:
            await authStore.login(email: cleanedEmail, password: password)
        case .signup:
            await authStore.signUp(
                email: cleanedEmail,
                password: password,
                displayName: cleanedName
            )
        }
    }
}

private enum AuthMode: String, CaseIterable, Identifiable {
    case login
    case signup

    var id: String { rawValue }

    var title: String {
        switch self {
        case .login:
            return "Đăng nhập"
        case .signup:
            return "Đăng ký"
        }
    }

    var headline: String {
        switch self {
        case .login:
            return "Đăng nhập"
        case .signup:
            return "Tạo tài khoản"
        }
    }

    var subtitle: String {
        switch self {
        case .login:
            return "Chào mừng trở lại với NarutoCalories"
        case .signup:
            return "Chào mừng đến với NarutoCalories"
        }
    }

    var buttonTitle: String {
        switch self {
        case .login:
            return "Đăng nhập"
        case .signup:
            return "Tạo tài khoản"
        }
    }

    var buttonIcon: String {
        switch self {
        case .login:
            return "arrow.right.circle.fill"
        case .signup:
            return "person.badge.plus.fill"
        }
    }

    var switchPrompt: String {
        switch self {
        case .login:
            return "Chưa có tài khoản?"
        case .signup:
            return "Đã có tài khoản?"
        }
    }

    var switchTitle: String {
        switch self {
        case .login:
            return "Đăng ký"
        case .signup:
            return "Đăng nhập"
        }
    }

    var alternateMode: AuthMode {
        switch self {
        case .login:
            return .signup
        case .signup:
            return .login
        }
    }
}

private struct AuthHeader: View {
    let mode: AuthMode

    var body: some View {
        VStack(spacing: 18) {
            AppIconBadge(
                systemName: "flame.fill",
                color: AppTheme.ColorToken.primary,
                size: 58
            )

            VStack(spacing: 8) {
                Text(mode.headline)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.primary)

                Text(mode.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct AuthModeSwitch: View {
    @Binding var mode: AuthMode

    var body: some View {
        HStack(spacing: 6) {
            Text(mode.switchPrompt)
                .foregroundStyle(.secondary)

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                    mode = mode.alternateMode
                }
            } label: {
                Text(mode.switchTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.ColorToken.primary)
            }
            .buttonStyle(.plain)
        }
        .font(.footnote)
        .frame(maxWidth: .infinity)
    }
}

private struct AuthTextField: View {
    let title: String
    let icon: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let textContentType: UITextContentType

    var body: some View {
        HStack(spacing: 12) {
            AppIconBadge(systemName: icon, color: AppTheme.ColorToken.primary, size: 34)

            TextField(title, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .font(.headline)
        }
        .padding(14)
        .background(AppTheme.ColorToken.mutedFill)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.compactCard, style: .continuous))
    }
}

private struct AuthSecureInput: View {
    @Binding var password: String

    var body: some View {
        HStack(spacing: 12) {
            AppIconBadge(systemName: "key.fill", color: AppTheme.ColorToken.primary, size: 34)

            SecureField("Mật khẩu", text: $password)
                .textContentType(.password)
                .font(.headline)
        }
        .padding(14)
        .background(AppTheme.ColorToken.mutedFill)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.compactCard, style: .continuous))
    }
}

private struct AuthMessageView: View {
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

#Preview {
    AuthView()
        .environment(AuthSessionStore())
        .preferredColorScheme(.light)
}
