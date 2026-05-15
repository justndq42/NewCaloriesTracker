import Foundation
import SwiftData

@MainActor
final class DiaryEntrySyncService {
    static let shared = DiaryEntrySyncService()

    private let backend: BackendSyncService
    private let deletionStore: PendingDeletionStore

    private convenience init() {
        self.init(backend: .shared, deletionStore: .shared)
    }

    private init(
        backend: BackendSyncService,
        deletionStore: PendingDeletionStore
    ) {
        self.backend = backend
        self.deletionStore = deletionStore
    }

    func syncAll(for userID: String, context: ModelContext, accessToken: String) async throws {
        var pendingDeleteError: Error?
        do {
            try await flushPendingDeletions(for: userID, accessToken: accessToken)
        } catch {
            pendingDeleteError = error
        }

        let pendingDeleteIDs = deletionStore.remoteIDs(kind: .diaryEntry, userID: userID)
        let fetchedRemoteEntries = try await backend.fetchDiaryEntries(accessToken: accessToken)
        let remoteEntries = fetchedRemoteEntries.filter {
            !pendingDeleteIDs.contains($0.id)
        }
        var pendingPushError: Error?
        do {
            try await pushDirtyEntries(
                for: userID,
                remoteEntries: remoteEntries,
                context: context,
                accessToken: accessToken
            )
        } catch {
            pendingPushError = error
        }

        try await pullRemoteEntries(for: userID, context: context, accessToken: accessToken)

        if let pendingDeleteError {
            throw pendingDeleteError
        }

        if let pendingPushError {
            throw pendingPushError
        }
    }

    func pullRemoteEntries(for userID: String, context: ModelContext, accessToken: String) async throws {
        let pendingDeleteIDs = deletionStore.remoteIDs(kind: .diaryEntry, userID: userID)
        let fetchedRemoteEntries = try await backend.fetchDiaryEntries(accessToken: accessToken)
        let remoteEntries = fetchedRemoteEntries.filter {
            !pendingDeleteIDs.contains($0.id)
        }
        let remoteIDs = Set(remoteEntries.map(\.id))
        let localEntries = try context.fetch(FetchDescriptor<DiaryEntryModel>()).filter {
            $0.userID == userID
        }
        let customFoods = try context.fetch(FetchDescriptor<CustomFoodModel>()).filter {
            $0.userID == userID
        }

        var localByRemoteID: [String: DiaryEntryModel] = [:]
        var localByClientID: [String: DiaryEntryModel] = [:]
        for entry in localEntries {
            if let remoteID = entry.remoteID {
                localByRemoteID[remoteID] = entry
            }

            localByClientID[entry.resolvedClientID()] = entry
        }

        var localCustomFoodIDByRemoteID: [String: String] = [:]
        for food in customFoods {
            if let remoteID = food.remoteID {
                localCustomFoodIDByRemoteID[remoteID] = food.resolvedCustomFoodID()
            }
        }

        for remoteEntry in remoteEntries {
            let localCustomFoodID = remoteEntry.customFoodID.flatMap {
                localCustomFoodIDByRemoteID[$0]
            }

            if let localEntry = localByRemoteID[remoteEntry.id] {
                if shouldUseRemote(remoteEntry, over: localEntry) {
                    apply(remoteEntry, localCustomFoodID: localCustomFoodID, userID: userID, to: localEntry)
                }
            } else if let clientID = remoteEntry.clientID,
                      let localEntry = localByClientID[clientID] {
                if shouldUseRemote(remoteEntry, over: localEntry) {
                    apply(remoteEntry, localCustomFoodID: localCustomFoodID, userID: userID, to: localEntry)
                }
            } else {
                context.insert(
                    DiaryEntryModel(
                        remoteEntry: remoteEntry,
                        localCustomFoodID: localCustomFoodID,
                        userID: userID
                    )
                )
            }
        }

        for localEntry in localEntries {
            guard let remoteID = localEntry.remoteID else {
                continue
            }

            if !remoteIDs.contains(remoteID), !localEntry.hasUnsyncedChanges {
                context.delete(localEntry)
            }
        }

        try context.save()
    }

    private func pushDirtyEntries(
        for userID: String,
        remoteEntries: [BackendSyncService.RemoteDiaryEntry],
        context: ModelContext,
        accessToken: String
    ) async throws {
        let localEntries = try context.fetch(FetchDescriptor<DiaryEntryModel>()).filter {
            $0.userID == userID
        }
        guard !localEntries.isEmpty else {
            return
        }

        let remoteByID = Dictionary(uniqueKeysWithValues: remoteEntries.map { ($0.id, $0) })
        let remoteByClientID = Dictionary(
            uniqueKeysWithValues: remoteEntries.compactMap { remoteEntry in
                remoteEntry.clientID.map { ($0, remoteEntry) }
            }
        )
        let customFoods = try context.fetch(FetchDescriptor<CustomFoodModel>()).filter {
            $0.userID == userID
        }
        var remoteCustomFoodIDByLocalID: [String: String] = [:]
        var localCustomFoodIDByRemoteID: [String: String] = [:]
        for food in customFoods {
            guard let remoteID = food.remoteID else {
                continue
            }

            let localID = food.resolvedCustomFoodID()
            remoteCustomFoodIDByLocalID[localID] = remoteID
            localCustomFoodIDByRemoteID[remoteID] = localID
        }

        var firstError: Error?
        for entry in localEntries {
            let clientID = entry.resolvedClientID()
            let matchingRemoteEntry = entry.remoteID.flatMap { remoteByID[$0] } ?? remoteByClientID[clientID]

            if let matchingRemoteEntry,
               shouldUseRemote(matchingRemoteEntry, over: entry) {
                let localCustomFoodID = matchingRemoteEntry.customFoodID.flatMap {
                    localCustomFoodIDByRemoteID[$0]
                }
                apply(matchingRemoteEntry, localCustomFoodID: localCustomFoodID, userID: userID, to: entry)
                continue
            }

            guard entry.hasUnsyncedChanges else {
                continue
            }

            if matchingRemoteEntry == nil, entry.remoteID != nil {
                entry.remoteID = nil
            }

            let remoteCustomFoodID = entry.customFoodID.flatMap {
                remoteCustomFoodIDByLocalID[$0]
            }

            do {
                try await push(
                    entry: entry,
                    remoteCustomFoodID: remoteCustomFoodID,
                    userID: userID,
                    context: context,
                    accessToken: accessToken
                )
            } catch {
                firstError = firstError ?? error
            }
        }

        if let firstError {
            throw firstError
        }
    }

    func push(
        entry: DiaryEntryModel,
        remoteCustomFoodID: String?,
        userID: String,
        context: ModelContext,
        accessToken: String
    ) async throws {
        try ensureEntry(entry, belongsTo: userID)

        let payload = BackendSyncService.DiaryEntryPayload(
            entry: entry,
            remoteCustomFoodID: remoteCustomFoodID
        )
        let remoteEntry: BackendSyncService.RemoteDiaryEntry

        if let remoteID = entry.remoteID {
            remoteEntry = try await backend.updateDiaryEntry(
                id: remoteID,
                payload: payload,
                accessToken: accessToken
            )
        } else {
            remoteEntry = try await backend.createDiaryEntry(
                payload,
                accessToken: accessToken
            )
        }

        apply(remoteEntry, localCustomFoodID: entry.customFoodID, userID: userID, to: entry)
        try context.save()
    }

    func delete(
        entry: DiaryEntryModel,
        userID: String,
        context: ModelContext,
        accessToken: String?
    ) async throws {
        try ensureEntry(entry, belongsTo: userID)

        if let accessToken, let remoteID = entry.remoteID {
            do {
                try await backend.deleteDiaryEntry(id: remoteID, accessToken: accessToken)
            } catch {
                deletionStore.enqueue(kind: .diaryEntry, remoteID: remoteID, userID: userID)
            }
        } else if let remoteID = entry.remoteID {
            deletionStore.enqueue(kind: .diaryEntry, remoteID: remoteID, userID: userID)
        }

        context.delete(entry)
        try context.save()
    }

    private func flushPendingDeletions(for userID: String, accessToken: String) async throws {
        let remoteIDs = deletionStore.remoteIDs(kind: .diaryEntry, userID: userID)
        var firstError: Error?

        for remoteID in remoteIDs {
            do {
                try await backend.deleteDiaryEntry(id: remoteID, accessToken: accessToken)
                deletionStore.remove(kind: .diaryEntry, remoteID: remoteID, userID: userID)
            } catch {
                firstError = firstError ?? error
            }
        }

        if let firstError {
            throw firstError
        }
    }

    private func apply(
        _ remoteEntry: BackendSyncService.RemoteDiaryEntry,
        localCustomFoodID: String?,
        userID: String,
        to localEntry: DiaryEntryModel
    ) {
        localEntry.foodName = remoteEntry.foodName
        localEntry.calories = remoteEntry.calories
        localEntry.protein = remoteEntry.protein
        localEntry.carbs = remoteEntry.carbs
        localEntry.fat = remoteEntry.fat
        localEntry.unit = remoteEntry.unit
        localEntry.meal = remoteEntry.meal
        localEntry.date = Date.remoteSyncDate(from: remoteEntry.eatenAt) ?? localEntry.date
        localEntry.clientID = remoteEntry.clientID ?? localEntry.clientID ?? remoteEntry.id
        localEntry.customFoodID = localCustomFoodID
        localEntry.remoteID = remoteEntry.id
        localEntry.userID = userID

        let syncedAt = Date.remoteSyncDate(from: remoteEntry.updatedAt) ?? Date()
        localEntry.updatedAt = syncedAt
        localEntry.lastSyncedAt = syncedAt
    }

    private func ensureEntry(_ entry: DiaryEntryModel, belongsTo userID: String) throws {
        if let ownerID = entry.userID, ownerID != userID {
            throw SyncOwnershipError.mismatchedUser
        }

        entry.userID = userID
    }

    private func shouldUseRemote(
        _ remoteEntry: BackendSyncService.RemoteDiaryEntry,
        over localEntry: DiaryEntryModel
    ) -> Bool {
        guard localEntry.hasUnsyncedChanges else {
            return true
        }

        guard let lastSyncedAt = localEntry.lastSyncedAt else {
            return true
        }

        guard let remoteUpdatedAt = Date.remoteSyncDate(from: remoteEntry.updatedAt) else {
            return false
        }

        return remoteUpdatedAt > lastSyncedAt && remoteUpdatedAt > localEntry.updatedAt
    }
}

extension DiaryEntryModel {
    convenience init(
        remoteEntry: BackendSyncService.RemoteDiaryEntry,
        localCustomFoodID: String?,
        userID: String
    ) {
        let syncedAt = Date.remoteSyncDate(from: remoteEntry.updatedAt) ?? Date()

        self.init(
            foodName: remoteEntry.foodName,
            calories: remoteEntry.calories,
            protein: remoteEntry.protein,
            carbs: remoteEntry.carbs,
            fat: remoteEntry.fat,
            unit: remoteEntry.unit,
            meal: remoteEntry.meal,
            date: Date.remoteSyncDate(from: remoteEntry.eatenAt) ?? Date(),
            updatedAt: syncedAt,
            lastSyncedAt: syncedAt,
            clientID: remoteEntry.clientID ?? remoteEntry.id,
            customFoodID: localCustomFoodID,
            remoteID: remoteEntry.id,
            userID: userID
        )
    }
}

enum SyncOwnershipError: Error {
    case mismatchedUser
}

private extension Date {
    static func remoteSyncDate(from value: String) -> Date? {
        if let date = ISO8601DateFormatter.remoteSyncFractional.date(from: value) {
            return date
        }

        return ISO8601DateFormatter.remoteSyncFull.date(from: value)
    }
}

private extension ISO8601DateFormatter {
    static let remoteSyncFull: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static let remoteSyncFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
