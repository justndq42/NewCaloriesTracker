import Foundation
import Security

enum AuthEntryPoint {
    case login
    case signup

    var restoreMessage: String {
        switch self {
        case .login:
            return "Đang tải dữ liệu tài khoản"
        case .signup:
            return "Đang tạo tài khoản"
        }
    }
}

@MainActor
@Observable
final class AuthSessionStore {
    private static let installMarkerKey = "TheNewCaloriesTracker.Auth.hasCurrentInstall"

    private let authService: BackendAuthService
    private let keychain: AuthKeychainStore
    private let defaults: UserDefaults

    private(set) var user: AuthUser?
    private(set) var session: AuthSession?
    private(set) var lastEntryPoint: AuthEntryPoint?
    var isLoading = false
    var errorMessage: String?

    var isAuthenticated: Bool {
        session?.accessToken.isEmpty == false
    }

    convenience init() {
        self.init(
            authService: .shared,
            keychain: .shared,
            defaults: .standard
        )
    }

    init(
        authService: BackendAuthService,
        keychain: AuthKeychainStore,
        defaults: UserDefaults = .standard
    ) {
        self.authService = authService
        self.keychain = keychain
        self.defaults = defaults
        resetStaleSessionAfterFreshInstallIfNeeded()
        restoreSession()
    }

    func login(email: String, password: String) async {
        await runAuthAction(entryPoint: .login) {
            try await authService.login(email: email, password: password)
        }
    }

    func signUp(email: String, password: String, displayName: String) async {
        await runAuthAction(entryPoint: .signup) {
            try await authService.signUp(
                email: email,
                password: password,
                displayName: displayName
            )
        }
    }

    func refreshIfNeeded() async {
        guard let session, session.shouldRefresh else {
            return
        }

        do {
            let response = try await authService.refreshSession(refreshToken: session.refreshToken)
            try apply(response)
        } catch {
            signOut()
        }
    }

    func accessToken() async -> String? {
        await refreshIfNeeded()
        return session?.accessToken
    }

    func signOut() {
        user = nil
        session = nil
        lastEntryPoint = nil
        errorMessage = nil
        keychain.delete()
    }

    private func runAuthAction(entryPoint: AuthEntryPoint, _ action: () async throws -> AuthResponse) async {
        isLoading = true
        errorMessage = nil
        lastEntryPoint = entryPoint

        do {
            let response = try await action()
            try apply(response)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Đăng nhập thất bại. Vui lòng thử lại."
            lastEntryPoint = nil
        }

        isLoading = false
    }

    private func apply(_ response: AuthResponse) throws {
        guard let user = response.user, let session = response.session else {
            if response.requiresEmailConfirmation {
                throw BackendAuthError.server("Vui lòng xác nhận email trước khi đăng nhập.")
            }

            throw BackendAuthError.missingSession
        }

        self.user = user
        self.session = session
        try keychain.save(AuthStateSnapshot(user: user, session: session))
    }

    private func restoreSession() {
        guard let snapshot = try? keychain.load() else {
            return
        }

        user = snapshot.user
        session = snapshot.session
    }

    private func resetStaleSessionAfterFreshInstallIfNeeded() {
        guard !defaults.bool(forKey: Self.installMarkerKey) else {
            return
        }

        keychain.delete()
        defaults.set(true, forKey: Self.installMarkerKey)
    }
}

final class AuthKeychainStore {
    static let shared = AuthKeychainStore()

    private let service = "TheNewCaloriesTracker.Auth"
    private let account = "current-session"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    func save(_ snapshot: AuthStateSnapshot) throws {
        let data = try encoder.encode(snapshot)
        delete()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw BackendAuthError.server("Không thể lưu phiên đăng nhập.")
        }
    }

    func load() throws -> AuthStateSnapshot? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status != errSecItemNotFound else {
            return nil
        }

        guard status == errSecSuccess, let data = result as? Data else {
            throw BackendAuthError.server("Không thể đọc phiên đăng nhập.")
        }

        return try decoder.decode(AuthStateSnapshot.self, from: data)
    }

    func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)
    }
}
