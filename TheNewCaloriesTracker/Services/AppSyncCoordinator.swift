import Foundation
import SwiftData

enum AppSyncState: Equatable {
    case idle
    case syncing
    case synced(Date)
    case failed(String)
}

enum AppSyncTrigger {
    case loginRestore
    case appBecameActive
    case networkRestored

    var requiresForce: Bool {
        switch self {
        case .loginRestore:
            return true
        case .appBecameActive, .networkRestored:
            return false
        }
    }
}

@MainActor
@Observable
final class AppSyncCoordinator {
    private let accountDataSyncService: AccountDataSyncService
    private let cooldown: TimeInterval

    private var isSyncing = false
    private var lastSyncStartedAt: Date?
    private var needsSignOut = false

    private(set) var state: AppSyncState = .idle

    init(
        cooldown: TimeInterval = 15
    ) {
        self.accountDataSyncService = .shared
        self.cooldown = cooldown
    }

    init(
        accountDataSyncService: AccountDataSyncService,
        cooldown: TimeInterval
    ) {
        self.accountDataSyncService = accountDataSyncService
        self.cooldown = cooldown
    }

    func syncIfNeeded(
        trigger: AppSyncTrigger,
        user: AuthUser?,
        context: ModelContext,
        accessToken: String?,
        isOnline: Bool
    ) async {
        guard isOnline, let user, let accessToken else {
            return
        }

        guard trigger.requiresForce || shouldSyncNow() else {
            return
        }

        await syncNow(
            user: user,
            context: context,
            accessToken: accessToken
        )
    }

    func reset() {
        state = .idle
        isSyncing = false
        lastSyncStartedAt = nil
        needsSignOut = false
    }

    func consumeSignOutRequest() -> Bool {
        let result = needsSignOut
        needsSignOut = false
        return result
    }

    private func shouldSyncNow() -> Bool {
        guard !isSyncing else {
            return false
        }

        guard let lastSyncStartedAt else {
            return true
        }

        return Date().timeIntervalSince(lastSyncStartedAt) >= cooldown
    }

    private func syncNow(
        user: AuthUser,
        context: ModelContext,
        accessToken: String
    ) async {
        guard !isSyncing else {
            return
        }

        isSyncing = true
        lastSyncStartedAt = Date()
        state = .syncing

        do {
            try await accountDataSyncService.restoreAfterLogin(
                for: user,
                context: context,
                accessToken: accessToken
            )
            state = .synced(Date())
        } catch {
            if let backendError = error as? BackendAPIError,
               backendError.requiresSignOut {
                needsSignOut = true
            }

            // Keep background sync failures internal; user-facing errors stay in direct auth/save flows.
            state = .failed(Self.message(for: error))
        }

        isSyncing = false
    }

    private static func message(for error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let message = localizedError.errorDescription {
            return message
        }

        return "Đồng bộ chưa hoàn tất. Dữ liệu sẽ được thử lại sau."
    }
}
