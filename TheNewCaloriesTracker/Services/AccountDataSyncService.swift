import Foundation
import SwiftData

@MainActor
final class AccountDataSyncService {
    static let shared = AccountDataSyncService()

    private let profileSyncService: ProfileSyncService
    private let customFoodSyncService: CustomFoodSyncService
    private let diaryEntrySyncService: DiaryEntrySyncService
    private let waterLogSyncService: WaterLogSyncService
    private let weightLogSyncService: WeightLogSyncService

    private convenience init() {
        self.init(
            profileSyncService: .shared,
            customFoodSyncService: .shared,
            diaryEntrySyncService: .shared,
            waterLogSyncService: .shared,
            weightLogSyncService: .shared
        )
    }

    private init(
        profileSyncService: ProfileSyncService,
        customFoodSyncService: CustomFoodSyncService,
        diaryEntrySyncService: DiaryEntrySyncService,
        waterLogSyncService: WaterLogSyncService,
        weightLogSyncService: WeightLogSyncService
    ) {
        self.profileSyncService = profileSyncService
        self.customFoodSyncService = customFoodSyncService
        self.diaryEntrySyncService = diaryEntrySyncService
        self.waterLogSyncService = waterLogSyncService
        self.weightLogSyncService = weightLogSyncService
    }

    func restoreAfterLogin(
        for user: AuthUser,
        context: ModelContext,
        accessToken: String
    ) async throws {
        var firstError: Error?

        do {
            try await weightLogSyncService.syncLocalWeightIfNeeded(
                for: user.id,
                context: context,
                accessToken: accessToken
            )
        } catch {
            firstError = firstError ?? error
        }

        do {
            try await profileSyncService.restoreProfile(
                for: user,
                context: context,
                accessToken: accessToken
            )
        } catch {
            firstError = firstError ?? error
        }

        do {
            try await customFoodSyncService.syncAll(
                for: user.id,
                context: context,
                accessToken: accessToken
            )
        } catch {
            firstError = firstError ?? error
        }

        do {
            try await diaryEntrySyncService.syncAll(
                for: user.id,
                context: context,
                accessToken: accessToken
            )
        } catch {
            firstError = firstError ?? error
        }

        do {
            try await waterLogSyncService.syncPendingLogs(for: user.id, accessToken: accessToken)
            try await waterLogSyncService.pullRemoteLogs(for: user.id, accessToken: accessToken)
        } catch {
            firstError = firstError ?? error
        }

        do {
            try await weightLogSyncService.restoreLatestWeight(
                for: user.id,
                context: context,
                accessToken: accessToken
            )
        } catch {
            firstError = firstError ?? error
        }

        if let firstError {
            throw firstError
        }
    }
}
