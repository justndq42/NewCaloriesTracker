import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query private var profiles: [UserProfileModel]
    @State private var vm = AppViewModel()
    @State private var authStore = AuthSessionStore()
    @State private var networkMonitor = NetworkStatusMonitor.shared
    @State private var syncCoordinator = AppSyncCoordinator()
    @State private var isRestoringProfile = false
    @State private var restoredUserID: String?

    private var currentProfile: UserProfileModel? {
        guard let userID = authStore.user?.id else {
            return nil
        }

        return profiles.first {
            $0.userID == userID && $0.isOnboardingDone
        }
    }

    private var shouldShowRestoreState: Bool {
        guard let userID = authStore.user?.id else {
            return false
        }

        return isRestoringProfile || restoredUserID != userID
    }
    
    var body: some View {
        Group {
            if authStore.isAuthenticated {
                if shouldShowRestoreState {
                    AccountRestoreView(message: authStore.lastEntryPoint?.restoreMessage ?? "Đang tải dữ liệu tài khoản")
                } else if let profile = currentProfile {
                    MainTabView(profile: profile)
                } else {
                    OnboardingView()
                }
            } else {
                AuthView()
            }
        }
        .environment(vm)
        .environment(authStore)
        .environment(networkMonitor)
        .environment(syncCoordinator)
        .task {
            await authStore.refreshIfNeeded()
        }
        .task(id: authStore.user?.id) {
            await restoreProfileForCurrentUser()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }

            Task {
                await syncCurrentUserIfNeeded(trigger: .appBecameActive)
            }
        }
        .onChange(of: networkMonitor.isOnline) { wasOnline, isOnline in
            guard !wasOnline, isOnline else { return }

            Task {
                await syncCurrentUserIfNeeded(trigger: .networkRestored)
            }
        }
    }

    private func restoreProfileForCurrentUser() async {
        guard let user = authStore.user else {
            restoredUserID = nil
            isRestoringProfile = false
            return
        }

        guard restoredUserID != user.id else {
            return
        }

        isRestoringProfile = true
        defer {
            restoredUserID = user.id
            isRestoringProfile = false
        }

        guard let accessToken = await authStore.accessToken() else {
            return
        }

        await syncCoordinator.syncIfNeeded(
            trigger: .loginRestore,
            user: user,
            context: context,
            accessToken: accessToken,
            isOnline: networkMonitor.isOnline
        )
        signOutIfSyncRejectedSession()
    }

    private func syncCurrentUserIfNeeded(trigger: AppSyncTrigger) async {
        guard authStore.isAuthenticated else {
            syncCoordinator.reset()
            return
        }

        let accessToken = await authStore.accessToken()
        await syncCoordinator.syncIfNeeded(
            trigger: trigger,
            user: authStore.user,
            context: context,
            accessToken: accessToken,
            isOnline: networkMonitor.isOnline
        )
        signOutIfSyncRejectedSession()
    }

    private func signOutIfSyncRejectedSession() {
        guard syncCoordinator.consumeSignOutRequest() else {
            return
        }

        authStore.signOut()
    }
}

private struct AccountRestoreView: View {
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(AppTheme.ColorToken.primary)

            Text(message)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .appScreenBackground()
    }
}
