import Foundation
import SwiftData

@MainActor
final class ProfileSyncService {
    static let shared = ProfileSyncService()

    private let backend: BackendSyncService

    private convenience init() {
        self.init(backend: .shared)
    }

    private init(backend: BackendSyncService) {
        self.backend = backend
    }

    func restoreProfile(
        for user: AuthUser,
        context: ModelContext,
        accessToken: String
    ) async throws {
        guard let remoteProfile = try await backend.fetchProfile(accessToken: accessToken) else {
            if let localProfile = try profile(for: user.id, context: context) {
                try await syncProfile(localProfile, accessToken: accessToken)
            }
            return
        }

        let remoteNutritionGoals = try await backend.fetchNutritionGoals(accessToken: accessToken)
        let localProfile = try profile(for: user.id, context: context)

        if let localProfile {
            apply(remoteProfile, nutritionGoals: remoteNutritionGoals, user: user, to: localProfile)
        } else {
            context.insert(makeLocalProfile(remoteProfile, nutritionGoals: remoteNutritionGoals, user: user))
        }

        try context.save()
    }

    func syncProfile(_ profile: UserProfileModel, accessToken: String) async throws {
        _ = try await backend.saveProfile(
            BackendSyncService.ProfilePayload(profile: profile),
            accessToken: accessToken
        )

        _ = try await backend.saveNutritionGoals(
            BackendSyncService.NutritionGoalsPayload(profile: profile),
            accessToken: accessToken
        )
    }

    private func profile(for userID: String, context: ModelContext) throws -> UserProfileModel? {
        let descriptor = FetchDescriptor<UserProfileModel>(
            predicate: #Predicate { profile in
                profile.userID == userID
            }
        )

        return try context.fetch(descriptor).first
    }

    private func makeLocalProfile(
        _ remoteProfile: BackendSyncService.RemoteProfile,
        nutritionGoals: BackendSyncService.RemoteNutritionGoals?,
        user: AuthUser
    ) -> UserProfileModel {
        let weight = remoteProfile.currentWeightKG ?? 65
        let goal = NutritionGoal(rawValue: remoteProfile.goalType) ?? .maintain
        let defaultMacro = MacroDistribution.default(for: goal)

        return UserProfileModel(
            userID: remoteProfile.userID,
            name: displayName(remoteProfile.displayName, fallback: user),
            joinedAt: parsedDate(remoteProfile.joinedAt) ?? Date(),
            gender: remoteProfile.gender,
            age: remoteProfile.age ?? 25,
            weight: weight,
            targetWeight: remoteProfile.targetWeightKG ?? UserProfileModel.defaultTargetWeight(
                for: remoteProfile.goalType,
                currentWeight: weight
            ),
            height: remoteProfile.heightCM ?? 170,
            activityLevel: ActivityLevelOption(backendValue: remoteProfile.activityLevel).rawValue,
            goal: goal.rawValue,
            proteinMacroPercent: Double(nutritionGoals?.proteinPercent ?? Int(defaultMacro.proteinPercent)),
            carbsMacroPercent: Double(nutritionGoals?.carbsPercent ?? Int(defaultMacro.carbsPercent)),
            fatMacroPercent: Double(nutritionGoals?.fatPercent ?? Int(defaultMacro.fatPercent)),
            isOnboardingDone: true
        )
    }

    private func apply(
        _ remoteProfile: BackendSyncService.RemoteProfile,
        nutritionGoals: BackendSyncService.RemoteNutritionGoals?,
        user: AuthUser,
        to localProfile: UserProfileModel
    ) {
        let weight = remoteProfile.currentWeightKG ?? localProfile.weight
        let goal = NutritionGoal(rawValue: remoteProfile.goalType) ?? .maintain
        let defaultMacro = MacroDistribution.default(for: goal)

        localProfile.userID = remoteProfile.userID
        localProfile.name = displayName(remoteProfile.displayName, fallback: user)
        localProfile.gender = remoteProfile.gender
        localProfile.age = remoteProfile.age ?? localProfile.age
        localProfile.weight = weight
        localProfile.targetWeight = remoteProfile.targetWeightKG ?? UserProfileModel.defaultTargetWeight(
            for: remoteProfile.goalType,
            currentWeight: weight
        )
        localProfile.height = remoteProfile.heightCM ?? localProfile.height
        localProfile.activityLevel = ActivityLevelOption(backendValue: remoteProfile.activityLevel).rawValue
        localProfile.goal = goal.rawValue
        localProfile.proteinMacroPercent = Double(nutritionGoals?.proteinPercent ?? Int(defaultMacro.proteinPercent))
        localProfile.carbsMacroPercent = Double(nutritionGoals?.carbsPercent ?? Int(defaultMacro.carbsPercent))
        localProfile.fatMacroPercent = Double(nutritionGoals?.fatPercent ?? Int(defaultMacro.fatPercent))
        localProfile.isOnboardingDone = true

        if let joinedAt = parsedDate(remoteProfile.joinedAt) {
            localProfile.joinedAt = joinedAt
        }
    }

    private func displayName(_ remoteName: String, fallback user: AuthUser) -> String {
        let cleanedRemoteName = remoteName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanedRemoteName.isEmpty {
            return cleanedRemoteName
        }

        let cleanedAccountName = user.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanedAccountName.isEmpty {
            return cleanedAccountName
        }

        return user.email.split(separator: "@").first.map(String.init) ?? "Người dùng"
    }

    private func parsedDate(_ value: String) -> Date? {
        if let date = ISO8601DateFormatter.full.date(from: value) {
            return date
        }

        return ISO8601DateFormatter.fractional.date(from: value)
    }
}

private extension ISO8601DateFormatter {
    static let full: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static let fractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
