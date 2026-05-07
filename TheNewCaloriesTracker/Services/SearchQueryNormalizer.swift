import Foundation

enum SearchQueryNormalizer {
    static func normalized(_ text: String) -> String {
        return collapsedWhitespace(in: text)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
    }

    static func localMatches(text: String, query: String) -> Bool {
        let normalizedQuery = normalized(query)
        guard !normalizedQuery.isEmpty else { return true }
        return normalized(text).contains(normalizedQuery)
    }

    static func remoteQueries(for query: String) -> [String] {
        let cleanedQuery = collapsedWhitespace(in: query)
        guard !cleanedQuery.isEmpty else { return [] }

        var queries = [cleanedQuery]
        queries.append(contentsOf: VietnameseFoodCatalog.remoteAliases(for: cleanedQuery))

        return queries.reduce(into: [String]()) { result, candidate in
            let normalizedCandidate = normalized(candidate)
            guard !normalizedCandidate.isEmpty else { return }
            guard !result.contains(where: { normalized($0) == normalizedCandidate }) else { return }
            result.append(candidate)
        }
    }

    private static func collapsedWhitespace(in text: String) -> String {
        text
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}
