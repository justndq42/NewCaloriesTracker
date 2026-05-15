import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Environment(AuthSessionStore.self) private var authStore
    @State private var vm = OnboardingViewModel()
    @State private var isSavingProfile = false
    
    var body: some View {
        ZStack {
            AppTheme.ColorToken.screenBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress bar
                HStack(spacing: 8) {
                    ForEach(1...3, id: \.self) { step in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(step <= vm.currentStep ? AppTheme.ColorToken.primary : AppTheme.ColorToken.disabledFill)
                            .frame(height: 4)
                            .animation(.easeInOut, value: vm.currentStep)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Steps
                TabView(selection: $vm.currentStep) {
                    OnboardingStep1(vm: vm).tag(1)
                    OnboardingStep2(vm: vm).tag(2)
                    OnboardingStep3(vm: vm) {
                        Task {
                            await finishOnboarding()
                        }
                    }.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: vm.currentStep)
            }
        }
    }

    private func finishOnboarding() async {
        guard !isSavingProfile else {
            return
        }

        isSavingProfile = true
        defer {
            isSavingProfile = false
        }

        guard let userID = authStore.user?.id else {
            return
        }

        let profile = vm.saveProfile(
            userID: userID,
            displayName: accountDisplayName,
            context: context
        )

        guard let accessToken = await authStore.accessToken() else {
            return
        }

        try? await ProfileSyncService.shared.syncProfile(profile, accessToken: accessToken)
    }

    private var accountDisplayName: String {
        guard let user = authStore.user else {
            return "Người dùng"
        }

        let displayName = user.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !displayName.isEmpty {
            return displayName
        }

        return user.email.split(separator: "@").first.map(String.init) ?? "Người dùng"
    }
}
