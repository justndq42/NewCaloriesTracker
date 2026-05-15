import Foundation
import Network

@MainActor
@Observable
final class NetworkStatusMonitor: @unchecked Sendable {
    static let shared = NetworkStatusMonitor()

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "TheNewCaloriesTracker.NetworkStatusMonitor")
    private var hasStarted = false

    private(set) var isOnline = true
    private(set) var lastChangedAt = Date()

    private init(monitor: NWPathMonitor = NWPathMonitor()) {
        self.monitor = monitor
        start()
    }

    deinit {
        monitor.cancel()
    }

    private func start() {
        guard !hasStarted else { return }
        hasStarted = true

        monitor.pathUpdateHandler = { [weak self] path in
            let isOnline = path.status == .satisfied

            Task { @MainActor [weak self] in
                self?.updateStatus(isOnline: isOnline)
            }
        }

        monitor.start(queue: queue)
    }

    private func updateStatus(isOnline: Bool) {
        guard self.isOnline != isOnline else { return }

        self.isOnline = isOnline
        lastChangedAt = Date()
    }
}
