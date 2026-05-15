import Foundation

enum PendingDeletionKind: String, Codable {
    case customFood = "custom_food"
    case diaryEntry = "diary_entry"
}

final class PendingDeletionStore {
    static let shared = PendingDeletionStore()

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let keyPrefix = "TheNewCaloriesTracker.PendingDeletions"

    private convenience init() {
        self.init(defaults: .standard)
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func enqueue(kind: PendingDeletionKind, remoteID: String, userID: String) {
        guard !remoteID.isEmpty else { return }

        var records = recordsByID(kind: kind, userID: userID)
        records[remoteID] = PendingDeletionRecord(remoteID: remoteID, queuedAt: Date())
        save(records, kind: kind, userID: userID)
    }

    func remove(kind: PendingDeletionKind, remoteID: String, userID: String) {
        var records = recordsByID(kind: kind, userID: userID)
        records.removeValue(forKey: remoteID)
        save(records, kind: kind, userID: userID)
    }

    func remoteIDs(kind: PendingDeletionKind, userID: String) -> Set<String> {
        Set(recordsByID(kind: kind, userID: userID).keys)
    }

    private func recordsByID(
        kind: PendingDeletionKind,
        userID: String
    ) -> [String: PendingDeletionRecord] {
        guard let data = defaults.data(forKey: key(kind: kind, userID: userID)),
              let records = try? decoder.decode([String: PendingDeletionRecord].self, from: data) else {
            return [:]
        }

        return records
    }

    private func save(
        _ records: [String: PendingDeletionRecord],
        kind: PendingDeletionKind,
        userID: String
    ) {
        let key = key(kind: kind, userID: userID)

        guard !records.isEmpty else {
            defaults.removeObject(forKey: key)
            return
        }

        if let data = try? encoder.encode(records) {
            defaults.set(data, forKey: key)
        }
    }

    private func key(kind: PendingDeletionKind, userID: String) -> String {
        "\(keyPrefix).\(userID).\(kind.rawValue)"
    }
}

private struct PendingDeletionRecord: Codable {
    let remoteID: String
    let queuedAt: Date
}
