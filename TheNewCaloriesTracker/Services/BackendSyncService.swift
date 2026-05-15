import Foundation

final class BackendSyncService {
    static let shared = BackendSyncService()

    private struct ProfileResponse: Decodable {
        let profile: RemoteProfile?
    }

    private struct NutritionGoalsResponse: Decodable {
        let nutritionGoals: RemoteNutritionGoals?

        private enum CodingKeys: String, CodingKey {
            case nutritionGoals = "nutrition_goals"
        }
    }

    private struct CustomFoodsResponse: Decodable {
        let customFoods: [RemoteCustomFood]

        private enum CodingKeys: String, CodingKey {
            case customFoods = "custom_foods"
        }
    }

    private struct CustomFoodResponse: Decodable {
        let customFood: RemoteCustomFood

        private enum CodingKeys: String, CodingKey {
            case customFood = "custom_food"
        }
    }

    private struct DiaryEntryResponse: Decodable {
        let diaryEntry: RemoteDiaryEntry

        private enum CodingKeys: String, CodingKey {
            case diaryEntry = "diary_entry"
        }
    }

    private struct DiaryEntriesResponse: Decodable {
        let diaryEntries: [RemoteDiaryEntry]

        private enum CodingKeys: String, CodingKey {
            case diaryEntries = "diary_entries"
        }
    }

    private struct WaterLogResponse: Decodable {
        let waterLog: RemoteWaterLog

        private enum CodingKeys: String, CodingKey {
            case waterLog = "water_log"
        }
    }

    private struct WaterLogsResponse: Decodable {
        let waterLogs: [RemoteWaterLog]

        private enum CodingKeys: String, CodingKey {
            case waterLogs = "water_logs"
        }
    }

    private struct WeightLogResponse: Decodable {
        let weightLog: RemoteWeightLog

        private enum CodingKeys: String, CodingKey {
            case weightLog = "weight_log"
        }
    }

    private struct WeightLogsResponse: Decodable {
        let weightLogs: [RemoteWeightLog]

        private enum CodingKeys: String, CodingKey {
            case weightLogs = "weight_logs"
        }
    }

    struct RemoteProfile: Decodable {
        let userID: String
        let displayName: String
        let gender: String
        let age: Int?
        let heightCM: Double?
        let currentWeightKG: Double?
        let targetWeightKG: Double?
        let goalType: String
        let activityLevel: String
        let joinedAt: String

        private enum CodingKeys: String, CodingKey {
            case userID = "user_id"
            case displayName = "display_name"
            case gender
            case age
            case heightCM = "height_cm"
            case currentWeightKG = "current_weight_kg"
            case targetWeightKG = "target_weight_kg"
            case goalType = "goal_type"
            case activityLevel = "activity_level"
            case joinedAt = "joined_at"
        }
    }

    struct ProfilePayload: Encodable {
        let displayName: String
        let gender: String
        let age: Int
        let heightCM: Double
        let currentWeightKG: Double
        let targetWeightKG: Double
        let goalType: String
        let activityLevel: String

        private enum CodingKeys: String, CodingKey {
            case displayName = "display_name"
            case gender
            case age
            case heightCM = "height_cm"
            case currentWeightKG = "current_weight_kg"
            case targetWeightKG = "target_weight_kg"
            case goalType = "goal_type"
            case activityLevel = "activity_level"
        }
    }

    struct RemoteNutritionGoals: Decodable {
        let targetCalories: Int
        let proteinPercent: Int
        let carbsPercent: Int
        let fatPercent: Int
        let bmr: Int?
        let tdee: Int?
        let calorieDelta: Int?

        private enum CodingKeys: String, CodingKey {
            case targetCalories = "target_calories"
            case proteinPercent = "protein_percent"
            case carbsPercent = "carbs_percent"
            case fatPercent = "fat_percent"
            case bmr
            case tdee
            case calorieDelta = "calorie_delta"
        }
    }

    struct NutritionGoalsPayload: Encodable {
        let targetCalories: Int
        let proteinPercent: Int
        let carbsPercent: Int
        let fatPercent: Int
        let bmr: Int
        let tdee: Int
        let calorieDelta: Int

        private enum CodingKeys: String, CodingKey {
            case targetCalories = "target_calories"
            case proteinPercent = "protein_percent"
            case carbsPercent = "carbs_percent"
            case fatPercent = "fat_percent"
            case bmr
            case tdee
            case calorieDelta = "calorie_delta"
        }
    }

    struct RemoteCustomFood: Decodable, Identifiable {
        let id: String
        let clientID: String?
        let name: String
        let calories: Int
        let protein: Double
        let carbs: Double
        let fat: Double
        let unit: String
        let createdAt: String
        let updatedAt: String

        private enum CodingKeys: String, CodingKey {
            case id
            case clientID = "client_id"
            case name
            case calories
            case protein = "protein_g"
            case carbs = "carbs_g"
            case fat = "fat_g"
            case unit
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }

    struct CustomFoodPayload: Encodable {
        let clientID: String
        let name: String
        let calories: Int
        let protein: Double
        let carbs: Double
        let fat: Double
        let unit: String

        private enum CodingKeys: String, CodingKey {
            case clientID = "client_id"
            case name
            case calories
            case protein = "protein_g"
            case carbs = "carbs_g"
            case fat = "fat_g"
            case unit
        }
    }

    struct RemoteDiaryEntry: Decodable, Identifiable {
        let id: String
        let clientID: String?
        let customFoodID: String?
        let foodName: String
        let calories: Int
        let protein: Double
        let carbs: Double
        let fat: Double
        let unit: String
        let meal: String
        let eatenAt: String
        let updatedAt: String

        private enum CodingKeys: String, CodingKey {
            case id
            case clientID = "client_id"
            case customFoodID = "custom_food_id"
            case foodName = "food_name"
            case calories
            case protein = "protein_g"
            case carbs = "carbs_g"
            case fat = "fat_g"
            case unit
            case meal
            case eatenAt = "eaten_at"
            case updatedAt = "updated_at"
        }
    }

    struct DiaryEntryPayload: Encodable {
        let clientID: String
        let customFoodID: String?
        let foodName: String
        let calories: Int
        let protein: Double
        let carbs: Double
        let fat: Double
        let unit: String
        let meal: String
        let eatenAt: String

        private enum CodingKeys: String, CodingKey {
            case clientID = "client_id"
            case customFoodID = "custom_food_id"
            case foodName = "food_name"
            case calories
            case protein = "protein_g"
            case carbs = "carbs_g"
            case fat = "fat_g"
            case unit
            case meal
            case eatenAt = "eaten_at"
        }
    }

    struct RemoteWaterLog: Decodable, Identifiable {
        let id: String
        let logDate: String
        let consumedML: Int
        let goalML: Int

        private enum CodingKeys: String, CodingKey {
            case id
            case logDate = "log_date"
            case consumedML = "consumed_ml"
            case goalML = "goal_ml"
        }
    }

    struct WaterLogPayload: Encodable {
        let logDate: String
        let consumedML: Int
        let goalML: Int

        private enum CodingKeys: String, CodingKey {
            case logDate = "log_date"
            case consumedML = "consumed_ml"
            case goalML = "goal_ml"
        }
    }

    struct RemoteWeightLog: Decodable, Identifiable {
        let id: String
        let clientID: String?
        let weightKG: Double
        let recordedAt: String

        private enum CodingKeys: String, CodingKey {
            case id
            case clientID = "client_id"
            case weightKG = "weight_kg"
            case recordedAt = "recorded_at"
        }
    }

    struct WeightLogPayload: Encodable {
        let clientID: String
        let weightKG: Double
        let recordedAt: String

        private enum CodingKeys: String, CodingKey {
            case clientID = "client_id"
            case weightKG = "weight_kg"
            case recordedAt = "recorded_at"
        }
    }

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.waitsForConnectivity = true

        session = URLSession(configuration: config)

        decoder = JSONDecoder()
        encoder = JSONEncoder()
    }

    func fetchProfile(accessToken: String) async throws -> RemoteProfile? {
        let request = try makeRequest(path: "me/profile", accessToken: accessToken)
        let response: ProfileResponse = try await send(request)
        return response.profile
    }

    func saveProfile(_ payload: ProfilePayload, accessToken: String) async throws -> RemoteProfile {
        var request = try makeRequest(path: "me/profile", method: "POST", accessToken: accessToken)
        request.httpBody = try encoder.encode(payload)

        let response: ProfileResponse = try await send(request)
        guard let profile = response.profile else {
            throw URLError(.badServerResponse)
        }

        return profile
    }

    func fetchNutritionGoals(accessToken: String) async throws -> RemoteNutritionGoals? {
        let request = try makeRequest(path: "me/nutrition-goals", accessToken: accessToken)
        let response: NutritionGoalsResponse = try await send(request)
        return response.nutritionGoals
    }

    func saveNutritionGoals(_ payload: NutritionGoalsPayload, accessToken: String) async throws -> RemoteNutritionGoals {
        var request = try makeRequest(path: "me/nutrition-goals", method: "POST", accessToken: accessToken)
        request.httpBody = try encoder.encode(payload)

        let response: NutritionGoalsResponse = try await send(request)
        guard let nutritionGoals = response.nutritionGoals else {
            throw URLError(.badServerResponse)
        }

        return nutritionGoals
    }

    func fetchCustomFoods(accessToken: String) async throws -> [RemoteCustomFood] {
        let request = try makeRequest(path: "me/custom-foods", accessToken: accessToken)
        let response: CustomFoodsResponse = try await send(request)
        return response.customFoods
    }

    func createCustomFood(_ payload: CustomFoodPayload, accessToken: String) async throws -> RemoteCustomFood {
        var request = try makeRequest(path: "me/custom-foods", method: "POST", accessToken: accessToken)
        request.httpBody = try encoder.encode(payload)

        let response: CustomFoodResponse = try await send(request)
        return response.customFood
    }

    func updateCustomFood(id: String, payload: CustomFoodPayload, accessToken: String) async throws -> RemoteCustomFood {
        var request = try makeRequest(path: "me/custom-foods/\(id)", method: "PUT", accessToken: accessToken)
        request.httpBody = try encoder.encode(payload)

        let response: CustomFoodResponse = try await send(request)
        return response.customFood
    }

    func deleteCustomFood(id: String, accessToken: String) async throws {
        let request = try makeRequest(path: "me/custom-foods/\(id)", method: "DELETE", accessToken: accessToken)
        let _: EmptyResponse = try await send(request)
    }

    func createDiaryEntry(_ payload: DiaryEntryPayload, accessToken: String) async throws -> RemoteDiaryEntry {
        var request = try makeRequest(path: "me/diary-entries", method: "POST", accessToken: accessToken)
        request.httpBody = try encoder.encode(payload)

        let response: DiaryEntryResponse = try await send(request)
        return response.diaryEntry
    }

    func updateDiaryEntry(id: String, payload: DiaryEntryPayload, accessToken: String) async throws -> RemoteDiaryEntry {
        var request = try makeRequest(path: "me/diary-entries/\(id)", method: "PUT", accessToken: accessToken)
        request.httpBody = try encoder.encode(payload)

        let response: DiaryEntryResponse = try await send(request)
        return response.diaryEntry
    }

    func fetchDiaryEntries(accessToken: String) async throws -> [RemoteDiaryEntry] {
        let request = try makeRequest(path: "me/diary-entries", accessToken: accessToken)
        let response: DiaryEntriesResponse = try await send(request)
        return response.diaryEntries
    }

    func deleteDiaryEntry(id: String, accessToken: String) async throws {
        let request = try makeRequest(path: "me/diary-entries/\(id)", method: "DELETE", accessToken: accessToken)
        let _: EmptyResponse = try await send(request)
    }

    func fetchWaterLogs(accessToken: String) async throws -> [RemoteWaterLog] {
        let request = try makeRequest(path: "me/water-logs", accessToken: accessToken)
        let response: WaterLogsResponse = try await send(request)
        return response.waterLogs
    }

    func saveWaterLog(_ payload: WaterLogPayload, accessToken: String) async throws -> RemoteWaterLog {
        var request = try makeRequest(path: "me/water-logs", method: "POST", accessToken: accessToken)
        request.httpBody = try encoder.encode(payload)

        let response: WaterLogResponse = try await send(request)
        return response.waterLog
    }

    func createWeightLog(_ payload: WeightLogPayload, accessToken: String) async throws -> RemoteWeightLog {
        var request = try makeRequest(path: "me/weight-logs", method: "POST", accessToken: accessToken)
        request.httpBody = try encoder.encode(payload)

        let response: WeightLogResponse = try await send(request)
        return response.weightLog
    }

    func fetchWeightLogs(accessToken: String) async throws -> [RemoteWeightLog] {
        let request = try makeRequest(path: "me/weight-logs", accessToken: accessToken)
        let response: WeightLogsResponse = try await send(request)
        return response.weightLogs
    }

    private func makeRequest(
        path: String,
        method: String = "GET",
        accessToken: String
    ) throws -> URLRequest {
        let url = path
            .split(separator: "/")
            .reduce(BackendAPIConfiguration.baseURL) { partialURL, component in
                partialURL.appendingPathComponent(String(component))
            }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if method != "GET" {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return request
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            if let backendError = BackendAPIError.decode(from: data, statusCode: httpResponse.statusCode) {
                throw backendError
            }

            throw BackendAPIError.fallback(statusCode: httpResponse.statusCode)
        }

        return try decoder.decode(T.self, from: data)
    }
}

extension BackendSyncService.CustomFoodPayload {
    init(food: CustomFoodModel) {
        self.init(
            clientID: food.resolvedCustomFoodID(),
            name: food.name,
            calories: food.calories,
            protein: food.protein,
            carbs: food.carbs,
            fat: food.fat,
            unit: food.unit
        )
    }
}

extension BackendSyncService.DiaryEntryPayload {
    init(entry: DiaryEntryModel, remoteCustomFoodID: String? = nil) {
        self.init(
            clientID: entry.resolvedClientID(),
            customFoodID: remoteCustomFoodID,
            foodName: entry.foodName,
            calories: entry.calories,
            protein: entry.protein,
            carbs: entry.carbs,
            fat: entry.fat,
            unit: entry.unit,
            meal: entry.meal,
            eatenAt: entry.date.ISO8601Format()
        )
    }
}

extension BackendSyncService.ProfilePayload {
    init(profile: UserProfileModel) {
        self.init(
            displayName: profile.name,
            gender: profile.gender,
            age: profile.age,
            heightCM: profile.height,
            currentWeightKG: profile.weight,
            targetWeightKG: profile.targetWeight,
            goalType: profile.goal,
            activityLevel: (ActivityLevelOption(rawValue: profile.activityLevel) ?? .sedentary).backendValue
        )
    }
}

extension BackendSyncService.NutritionGoalsPayload {
    init(profile: UserProfileModel) {
        let nutrition = NutritionProfile(profile: profile)

        self.init(
            targetCalories: Int(nutrition.targetCalories.rounded()),
            proteinPercent: Int(profile.proteinMacroPercent.rounded()),
            carbsPercent: Int(profile.carbsMacroPercent.rounded()),
            fatPercent: Int(profile.fatMacroPercent.rounded()),
            bmr: Int(nutrition.bmr.rounded()),
            tdee: Int(nutrition.tdee.rounded()),
            calorieDelta: Int((nutrition.targetCalories - nutrition.tdee).rounded())
        )
    }
}

extension ActivityLevelOption {
    var backendValue: String {
        switch self {
        case .sedentary:
            return "sedentary"
        case .light:
            return "light"
        case .moderate:
            return "moderate"
        case .active:
            return "active"
        case .athlete:
            return "athlete"
        }
    }

    init(backendValue: String) {
        switch backendValue {
        case "light":
            self = .light
        case "moderate":
            self = .moderate
        case "active":
            self = .active
        case "athlete":
            self = .athlete
        default:
            self = .sedentary
        }
    }
}

private struct EmptyResponse: Decodable {
    let ok: Bool
}
