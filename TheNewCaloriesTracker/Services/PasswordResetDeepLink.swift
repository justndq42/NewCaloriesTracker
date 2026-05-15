import Foundation

struct PasswordResetDeepLink: Identifiable, Equatable {
    let id = UUID()
    let accessToken: String?
    let code: String?

    var hasCredential: Bool {
        accessToken?.isEmpty == false || code?.isEmpty == false
    }

    static func parse(_ url: URL) -> PasswordResetDeepLink? {
        guard url.scheme == "narutocalories", url.host == "password-reset" else {
            return nil
        }

        let values = url.queryValues.merging(url.fragmentValues) { current, _ in current }
        let link = PasswordResetDeepLink(
            accessToken: values["access_token"],
            code: values["code"]
        )

        return link.hasCredential ? link : nil
    }
}

private extension URL {
    var queryValues: [String: String] {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryValues ?? [:]
    }

    var fragmentValues: [String: String] {
        guard let fragment else {
            return [:]
        }

        return URLComponents(string: "narutocalories://password-reset?\(fragment)")?.queryValues ?? [:]
    }
}

private extension URLComponents {
    var queryValues: [String: String] {
        (queryItems ?? []).reduce(into: [:]) { values, item in
            guard let value = item.value, !value.isEmpty else {
                return
            }

            values[item.name] = value
        }
    }
}
