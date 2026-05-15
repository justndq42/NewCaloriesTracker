import Foundation

struct BackendAPIError: LocalizedError, Equatable {
    let statusCode: Int
    let code: String
    let message: String

    var errorDescription: String? {
        message
    }

    var requiresSignOut: Bool {
        code == "auth_missing_token" || code == "auth_invalid_token"
    }

    static func decode(from data: Data, statusCode: Int) -> BackendAPIError? {
        guard !data.isEmpty else {
            return nil
        }

        if let envelope = try? JSONDecoder().decode(BackendErrorEnvelope.self, from: data) {
            switch envelope.error {
            case .structured(let payload):
                return BackendAPIError(
                    statusCode: statusCode,
                    code: payload.code,
                    message: localizedMessage(for: payload.message)
                )
            case .legacyString(let message):
                return BackendAPIError(
                    statusCode: statusCode,
                    code: code(for: statusCode),
                    message: localizedMessage(for: message)
                )
            }
        }

        return nil
    }

    static func fallback(statusCode: Int) -> BackendAPIError {
        BackendAPIError(
            statusCode: statusCode,
            code: code(for: statusCode),
            message: "Máy chủ chưa phản hồi đúng. Vui lòng thử lại."
        )
    }

    private static func code(for statusCode: Int) -> String {
        switch statusCode {
        case 400:
            return "validation_error"
        case 401:
            return "auth_invalid_token"
        case 404:
            return "not_found"
        default:
            return "server_error"
        }
    }

    private static func localizedMessage(for rawMessage: String) -> String {
        let normalizedMessage = rawMessage.lowercased()

        if normalizedMessage.contains("already registered") {
            return "Email này đã được đăng ký. Hãy chuyển sang đăng nhập hoặc dùng email khác."
        }

        if normalizedMessage.contains("email not confirmed") {
            return "Email chưa được xác nhận. Vui lòng kiểm tra hộp thư trước khi đăng nhập."
        }

        if normalizedMessage.contains("invalid login credentials") {
            return "Email hoặc mật khẩu không chính xác."
        }

        if normalizedMessage.contains("invalid bearer") || normalizedMessage.contains("missing bearer") {
            return "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại."
        }

        return rawMessage
    }
}

private struct BackendErrorEnvelope: Decodable {
    let error: BackendErrorValue
}

private enum BackendErrorValue: Decodable {
    case structured(BackendErrorPayload)
    case legacyString(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let payload = try? container.decode(BackendErrorPayload.self) {
            self = .structured(payload)
            return
        }

        self = .legacyString(try container.decode(String.self))
    }
}

private struct BackendErrorPayload: Decodable {
    let code: String
    let message: String
}
