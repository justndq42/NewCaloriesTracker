import Foundation

@Observable
final class WaterIntakeStore {
    static let shared = WaterIntakeStore()

    private let defaults: UserDefaults
    private let calendar: Calendar
    private(set) var revision = 0

    init(
        defaults: UserDefaults = .standard,
        calendar: Calendar = .current
    ) {
        self.defaults = defaults
        self.calendar = calendar
    }

    func dailyGoal(for userID: String) -> Int {
        _ = revision
        let persistedGoal = defaults.integer(forKey: dailyGoalKey(for: userID))
        return persistedGoal > 0 ? persistedGoal : 3_000
    }

    func setDailyGoal(_ newValue: Int, for userID: String) {
        let normalizedGoal = max(1_000, newValue)
        defaults.set(normalizedGoal, forKey: dailyGoalKey(for: userID))
        revision += 1
    }

    func total(for date: Date, userID: String) -> Int {
        normalizedTotal(forKey: storageKey(for: date, userID: userID), userID: userID)
    }

    func increment(volume: Int, on date: Date, userID: String) {
        let key = storageKey(for: date, userID: userID)
        let updatedValue = min(dailyGoal(for: userID), total(for: date, userID: userID) + max(0, volume))
        defaults.set(updatedValue, forKey: key)
        markNeedsSync(on: date, userID: userID)
        revision += 1
    }

    func decrement(volume: Int, on date: Date, userID: String) {
        let key = storageKey(for: date, userID: userID)
        let currentValue = total(for: date, userID: userID)
        defaults.set(max(0, currentValue - max(0, volume)), forKey: key)
        markNeedsSync(on: date, userID: userID)
        revision += 1
    }

    func canIncrement(on date: Date, userID: String) -> Bool {
        total(for: date, userID: userID) < dailyGoal(for: userID)
    }

    func restore(consumedML: Int, goalML: Int, on date: Date, userID: String, updateDailyGoal: Bool) {
        if updateDailyGoal {
            setDailyGoal(goalML, for: userID)
        }

        let normalizedGoal = max(1_000, goalML)
        let normalizedConsumed = min(max(0, consumedML), normalizedGoal)
        defaults.set(normalizedConsumed, forKey: storageKey(for: date, userID: userID))
        revision += 1
    }

    func markNeedsSync(on date: Date, userID: String) {
        var pendingDates = pendingDateKeys(for: userID)
        pendingDates.insert(dateKey(for: date))
        defaults.set(Array(pendingDates), forKey: pendingDatesKey(for: userID))
    }

    func pendingSyncDates(for userID: String) -> [Date] {
        pendingDateKeys(for: userID)
            .compactMap(Self.syncDateFormatter.date(from:))
            .sorted()
    }

    func markSynced(on date: Date, userID: String) {
        var pendingDates = pendingDateKeys(for: userID)
        pendingDates.remove(dateKey(for: date))
        defaults.set(Array(pendingDates), forKey: pendingDatesKey(for: userID))
    }

    private func dailyGoalKey(for userID: String) -> String {
        "water-intake-\(userID)-daily-goal"
    }

    private func pendingDatesKey(for userID: String) -> String {
        "water-intake-\(userID)-pending-dates"
    }

    private func storageKey(for date: Date, userID: String) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return "water-intake-\(userID)-\(year)-\(month)-\(day)"
    }

    private func pendingDateKeys(for userID: String) -> Set<String> {
        Set(defaults.stringArray(forKey: pendingDatesKey(for: userID)) ?? [])
    }

    private func dateKey(for date: Date) -> String {
        Self.syncDateFormatter.string(from: calendar.startOfDay(for: date))
    }

    private func normalizedTotal(forKey key: String, userID: String) -> Int {
        let value = defaults.integer(forKey: key)
        let clampedValue = min(max(0, value), dailyGoal(for: userID))

        if clampedValue != value {
            defaults.set(clampedValue, forKey: key)
            revision += 1
        }

        return clampedValue
    }

    private static let syncDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
