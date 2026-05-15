import Foundation

@MainActor
final class WaterLogSyncService {
    static let shared = WaterLogSyncService()

    private let backend: BackendSyncService
    private let waterStore: WaterIntakeStore

    private convenience init() {
        self.init(
            backend: .shared,
            waterStore: .shared
        )
    }

    private init(backend: BackendSyncService, waterStore: WaterIntakeStore) {
        self.backend = backend
        self.waterStore = waterStore
    }

    func syncPendingLogs(for userID: String, accessToken: String) async throws {
        var firstError: Error?

        for date in waterStore.pendingSyncDates(for: userID) {
            do {
                try await syncLocalLog(on: date, userID: userID, accessToken: accessToken)
            } catch {
                firstError = firstError ?? error
            }
        }

        if let firstError {
            throw firstError
        }
    }

    func syncLocalLog(on date: Date, userID: String, accessToken: String) async throws {
        let selectedDay = Calendar.current.startOfDay(for: date)
        let payload = BackendSyncService.WaterLogPayload(
            logDate: Self.dateFormatter.string(from: selectedDay),
            consumedML: waterStore.total(for: selectedDay, userID: userID),
            goalML: waterStore.dailyGoal(for: userID)
        )

        _ = try await backend.saveWaterLog(payload, accessToken: accessToken)
        waterStore.markSynced(on: selectedDay, userID: userID)
    }

    func pullRemoteLogs(for userID: String, accessToken: String) async throws {
        let remoteLogs = try await backend.fetchWaterLogs(accessToken: accessToken)

        for (index, remoteLog) in remoteLogs.enumerated() {
            guard let date = Self.dateFormatter.date(from: remoteLog.logDate) else {
                continue
            }

            waterStore.restore(
                consumedML: remoteLog.consumedML,
                goalML: remoteLog.goalML,
                on: date,
                userID: userID,
                updateDailyGoal: index == 0
            )
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
