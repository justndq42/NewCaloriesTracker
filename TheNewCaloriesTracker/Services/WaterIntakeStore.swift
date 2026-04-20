import Foundation

@Observable
final class WaterIntakeStore {
    static let shared = WaterIntakeStore()
    private let dailyGoalKey = "water-intake-daily-goal"

    private let defaults: UserDefaults
    private let calendar: Calendar
    private var storedDailyGoal: Int

    init(
        defaults: UserDefaults = .standard,
        calendar: Calendar = .current
    ) {
        self.defaults = defaults
        self.calendar = calendar
        let persistedGoal = defaults.integer(forKey: dailyGoalKey)
        self.storedDailyGoal = persistedGoal > 0 ? persistedGoal : 3_000
    }

    var dailyGoal: Int {
        get { storedDailyGoal }
        set {
            let normalizedGoal = max(1_000, newValue)
            storedDailyGoal = normalizedGoal
            defaults.set(normalizedGoal, forKey: dailyGoalKey)
        }
    }

    func total(for date: Date) -> Int {
        migrateLegacyDataIfNeeded(for: date)
        return normalizedTotal(forKey: storageKey(for: date))
    }

    func increment(volume: Int, on date: Date) {
        let key = storageKey(for: date)
        let updatedValue = min(dailyGoal, total(for: date) + max(0, volume))
        defaults.set(updatedValue, forKey: key)
    }

    func decrement(volume: Int, on date: Date) {
        let key = storageKey(for: date)
        let currentValue = total(for: date)
        defaults.set(max(0, currentValue - max(0, volume)), forKey: key)
    }

    func canIncrement(on date: Date) -> Bool {
        total(for: date) < dailyGoal
    }

    private func storageKey(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return "water-intake-\(year)-\(month)-\(day)"
    }

    private func migrateLegacyDataIfNeeded(for date: Date) {
        let currentKey = storageKey(for: date)
        guard defaults.object(forKey: currentKey) == nil else { return }

        let legacy200Key = legacyStorageKey(for: date, volume: 200)
        let legacy500Key = legacyStorageKey(for: date, volume: 500)
        let legacyTotal = defaults.integer(forKey: legacy200Key) + defaults.integer(forKey: legacy500Key)

        if legacyTotal > 0 {
            defaults.set(legacyTotal, forKey: currentKey)
        }

        defaults.removeObject(forKey: legacy200Key)
        defaults.removeObject(forKey: legacy500Key)
    }

    private func normalizedTotal(forKey key: String) -> Int {
        let value = defaults.integer(forKey: key)
        let clampedValue = min(max(0, value), dailyGoal)

        if clampedValue != value {
            defaults.set(clampedValue, forKey: key)
        }

        return clampedValue
    }

    private func legacyStorageKey(for date: Date, volume: Int) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return "water-intake-\(year)-\(month)-\(day)-\(volume)"
    }
}
