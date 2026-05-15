import Foundation

struct AuthUser: Codable, Equatable {
    let id: String
    let email: String
    let displayName: String

    private enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
    }
}

struct AuthSession: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Int
    let expiresIn: Int
    let tokenType: String

    var shouldRefresh: Bool {
        Date(timeIntervalSince1970: TimeInterval(expiresAt - 60)) <= Date()
    }

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

struct AuthStateSnapshot: Codable, Equatable {
    let user: AuthUser
    let session: AuthSession
}

struct AuthResponse: Decodable {
    let user: AuthUser?
    let session: AuthSession?
    let requiresEmailConfirmation: Bool

    private enum CodingKeys: String, CodingKey {
        case user
        case session
        case requiresEmailConfirmation = "requires_email_confirmation"
    }
}

enum BackendAuthError: LocalizedError {
    case missingSession
    case server(String)

    var errorDescription: String? {
        switch self {
        case .missingSession:
            return "Không thể tạo phiên đăng nhập. Vui lòng thử lại."
        case .server(let message):
            return message
        }
    }
}

final class BackendAuthService {
    static let shared = BackendAuthService()

    private struct AuthRequest: Encodable {
        let email: String
        let password: String
        let displayName: String?

        private enum CodingKeys: String, CodingKey {
            case email
            case password
            case displayName = "display_name"
        }
    }

    private struct RefreshRequest: Encodable {
        let refreshToken: String

        private enum CodingKeys: String, CodingKey {
            case refreshToken = "refresh_token"
        }
    }

    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)
    }

    func signUp(email: String, password: String, displayName: String) async throws -> AuthResponse {
        try await send(
            path: "auth/signup",
            payload: AuthRequest(email: email, password: password, displayName: displayName)
        )
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        try await send(
            path: "auth/login",
            payload: AuthRequest(email: email, password: password, displayName: nil)
        )
    }

    func refreshSession(refreshToken: String) async throws -> AuthResponse {
        try await send(
            path: "auth/refresh",
            payload: RefreshRequest(refreshToken: refreshToken)
        )
    }

    private func send<T: Encodable>(
        path: String,
        payload: T
    ) async throws -> AuthResponse {
        var request = URLRequest(url: url(for: path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(payload)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if 200..<300 ~= httpResponse.statusCode {
            return try decoder.decode(AuthResponse.self, from: data)
        }

        if let backendError = BackendAPIError.decode(from: data, statusCode: httpResponse.statusCode) {
            throw backendError
        }

        throw BackendAPIError.fallback(statusCode: httpResponse.statusCode)
    }

    private func url(for path: String) -> URL {
        path
            .split(separator: "/")
            .reduce(BackendAPIConfiguration.baseURL) { partialURL, component in
                partialURL.appendingPathComponent(String(component))
            }
    }
}
