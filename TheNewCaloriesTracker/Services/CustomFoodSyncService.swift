import Foundation
import SwiftData

@MainActor
final class CustomFoodSyncService {
    static let shared = CustomFoodSyncService()

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

        let pendingDeleteIDs = deletionStore.remoteIDs(kind: .customFood, userID: userID)
        let fetchedRemoteFoods = try await backend.fetchCustomFoods(accessToken: accessToken)
        let remoteFoods = fetchedRemoteFoods.filter {
            !pendingDeleteIDs.contains($0.id)
        }
        let remoteByID = Dictionary(uniqueKeysWithValues: remoteFoods.map { ($0.id, $0) })
        let remoteByClientID = Dictionary(
            uniqueKeysWithValues: remoteFoods.compactMap { remoteFood in
                remoteFood.clientID.map { ($0, remoteFood) }
            }
        )
        let localFoods = try context.fetch(FetchDescriptor<CustomFoodModel>()).filter {
            $0.userID == userID
        }

        var pendingPushError: Error?
        for food in localFoods {
            let clientID = food.resolvedCustomFoodID()
            let matchingRemoteFood = food.remoteID.flatMap { remoteByID[$0] } ?? remoteByClientID[clientID]

            if let matchingRemoteFood,
               shouldUseRemote(matchingRemoteFood, over: food) {
                apply(matchingRemoteFood, userID: userID, to: food)
                continue
            }

            guard food.hasUnsyncedChanges else {
                continue
            }

            if matchingRemoteFood == nil, food.remoteID != nil {
                food.remoteID = nil
            }

            do {
                try await push(food: food, userID: userID, accessToken: accessToken)
            } catch {
                pendingPushError = pendingPushError ?? error
            }
        }

        try context.save()
        try await pullRemoteFoods(for: userID, context: context, accessToken: accessToken)

        if let pendingDeleteError {
            throw pendingDeleteError
        }

        if let pendingPushError {
            throw pendingPushError
        }
    }

    func restoreRemoteFoods(for userID: String, context: ModelContext, accessToken: String) async throws {
        try await pullRemoteFoods(for: userID, context: context, accessToken: accessToken)
    }

    func push(food: CustomFoodModel, userID: String, accessToken: String) async throws {
        try ensureFood(food, belongsTo: userID)

        let payload = BackendSyncService.CustomFoodPayload(food: food)
        let remoteFood: BackendSyncService.RemoteCustomFood

        if let remoteID = food.remoteID {
            remoteFood = try await backend.updateCustomFood(
                id: remoteID,
                payload: payload,
                accessToken: accessToken
            )
        } else {
            remoteFood = try await backend.createCustomFood(
                payload,
                accessToken: accessToken
            )
        }

        apply(remoteFood, userID: userID, to: food)
    }

    func delete(food: CustomFoodModel, userID: String, context: ModelContext, accessToken: String?) async throws {
        try ensureFood(food, belongsTo: userID)

        if let accessToken, let remoteID = food.remoteID {
            do {
                try await backend.deleteCustomFood(id: remoteID, accessToken: accessToken)
            } catch {
                deletionStore.enqueue(kind: .customFood, remoteID: remoteID, userID: userID)
            }
        } else if let remoteID = food.remoteID {
            deletionStore.enqueue(kind: .customFood, remoteID: remoteID, userID: userID)
        }

        context.delete(food)
        try context.save()
    }

    private func flushPendingDeletions(for userID: String, accessToken: String) async throws {
        let remoteIDs = deletionStore.remoteIDs(kind: .customFood, userID: userID)
        var firstError: Error?

        for remoteID in remoteIDs {
            do {
                try await backend.deleteCustomFood(id: remoteID, accessToken: accessToken)
                deletionStore.remove(kind: .customFood, remoteID: remoteID, userID: userID)
            } catch {
                firstError = firstError ?? error
            }
        }

        if let firstError {
            throw firstError
        }
    }

    private func pullRemoteFoods(for userID: String, context: ModelContext, accessToken: String) async throws {
        let pendingDeleteIDs = deletionStore.remoteIDs(kind: .customFood, userID: userID)
        let fetchedRemoteFoods = try await backend.fetchCustomFoods(accessToken: accessToken)
        let remoteFoods = fetchedRemoteFoods.filter {
            !pendingDeleteIDs.contains($0.id)
        }
        let remoteIDs = Set(remoteFoods.map(\.id))
        let localFoods = try context.fetch(FetchDescriptor<CustomFoodModel>()).filter {
            $0.userID == userID
        }
        var localByRemoteID: [String: CustomFoodModel] = [:]
        var localByClientID: [String: CustomFoodModel] = [:]
        for food in localFoods {
            if let remoteID = food.remoteID {
                localByRemoteID[remoteID] = food
            }

            localByClientID[food.resolvedCustomFoodID()] = food
        }

        for remoteFood in remoteFoods {
            if let localFood = localByRemoteID[remoteFood.id] {
                if shouldUseRemote(remoteFood, over: localFood) {
                    apply(remoteFood, userID: userID, to: localFood)
                }
            } else if let clientID = remoteFood.clientID,
                      let localFood = localByClientID[clientID] {
                if shouldUseRemote(remoteFood, over: localFood) {
                    apply(remoteFood, userID: userID, to: localFood)
                }
            } else {
                context.insert(CustomFoodModel(remoteFood: remoteFood, userID: userID))
            }
        }

        for localFood in localFoods {
            guard let remoteID = localFood.remoteID else {
                continue
            }

            if !remoteIDs.contains(remoteID), !localFood.hasUnsyncedChanges {
                context.delete(localFood)
            }
        }

        try context.save()
    }

    private func apply(
        _ remoteFood: BackendSyncService.RemoteCustomFood,
        userID: String,
        to localFood: CustomFoodModel
    ) {
        localFood.name = remoteFood.name
        localFood.calories = remoteFood.calories
        localFood.protein = remoteFood.protein
        localFood.carbs = remoteFood.carbs
        localFood.fat = remoteFood.fat
        localFood.unit = remoteFood.unit
        localFood.customFoodID = remoteFood.clientID ?? localFood.customFoodID ?? remoteFood.id
        localFood.remoteID = remoteFood.id
        localFood.userID = userID

        let syncedAt = Date.remoteSyncDate(from: remoteFood.updatedAt) ?? Date()
        localFood.updatedAt = syncedAt
        localFood.lastSyncedAt = syncedAt
    }

    private func ensureFood(_ food: CustomFoodModel, belongsTo userID: String) throws {
        if let ownerID = food.userID, ownerID != userID {
            throw SyncOwnershipError.mismatchedUser
        }

        food.userID = userID
    }

    private func shouldUseRemote(
        _ remoteFood: BackendSyncService.RemoteCustomFood,
        over localFood: CustomFoodModel
    ) -> Bool {
        guard localFood.hasUnsyncedChanges else {
            return true
        }

        guard let lastSyncedAt = localFood.lastSyncedAt else {
            return true
        }

        guard let remoteUpdatedAt = Date.remoteSyncDate(from: remoteFood.updatedAt) else {
            return false
        }

        return remoteUpdatedAt > lastSyncedAt && remoteUpdatedAt > localFood.updatedAt
    }
}

extension CustomFoodModel {
    convenience init(remoteFood: BackendSyncService.RemoteCustomFood, userID: String) {
        let syncedAt = Date.remoteSyncDate(from: remoteFood.updatedAt) ?? Date()

        self.init(
            name: remoteFood.name,
            calories: remoteFood.calories,
            protein: remoteFood.protein,
            carbs: remoteFood.carbs,
            fat: remoteFood.fat,
            unit: remoteFood.unit,
            updatedAt: syncedAt,
            lastSyncedAt: syncedAt,
            customFoodID: remoteFood.clientID ?? remoteFood.id,
            remoteID: remoteFood.id,
            userID: userID
        )
    }
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
