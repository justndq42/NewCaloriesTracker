import Foundation
import SwiftData

@MainActor
final class WeightLogSyncService {
    static let shared = WeightLogSyncService()

    private let backend: BackendSyncService

    private convenience init() {
        self.init(backend: .shared)
    }

    private init(backend: BackendSyncService) {
        self.backend = backend
    }

    func syncLocalWeightIfNeeded(
        for userID: String,
        context: ModelContext,
        accessToken: String
    ) async throws {
        let descriptor = FetchDescriptor<UserProfileModel>(
            predicate: #Predicate { profile in
                profile.userID == userID
            }
        )

        guard let profile = try context.fetch(descriptor).first,
              let recordedAt = profile.weightUpdatedAt else {
            return
        }

        try await syncWeight(
            profile.weight,
            recordedAt: recordedAt,
            userID: userID,
            accessToken: accessToken
        )
    }

    func syncWeight(
        _ weight: Double,
        recordedAt: Date,
        userID: String,
        accessToken: String
    ) async throws {
        let payload = BackendSyncService.WeightLogPayload(
            clientID: clientID(for: userID, recordedAt: recordedAt),
            weightKG: weight,
            recordedAt: recordedAt.ISO8601Format()
        )

        _ = try await backend.createWeightLog(payload, accessToken: accessToken)
    }

    func restoreLatestWeight(
        for userID: String,
        context: ModelContext,
        accessToken: String
    ) async throws {
        guard let latestLog = try await backend.fetchWeightLogs(accessToken: accessToken).first else {
            return
        }

        let descriptor = FetchDescriptor<UserProfileModel>(
            predicate: #Predicate { profile in
                profile.userID == userID
            }
        )

        guard let profile = try context.fetch(descriptor).first else {
            return
        }

        profile.weight = latestLog.weightKG
        profile.weightUpdatedAt = Self.remoteDate(from: latestLog.recordedAt) ?? profile.weightUpdatedAt
        try context.save()
    }

    private static func remoteDate(from value: String) -> Date? {
        if let date = ISO8601DateFormatter.weightLogFractional.date(from: value) {
            return date
        }

        return ISO8601DateFormatter.weightLogFull.date(from: value)
    }

    private func clientID(for userID: String, recordedAt: Date) -> String {
        let timestamp = Int(recordedAt.timeIntervalSince1970.rounded())
        return "weight-\(userID)-\(timestamp)"
    }
}

private extension ISO8601DateFormatter {
    static let weightLogFull: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static let weightLogFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
