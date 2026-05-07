import Foundation

enum DecimalTextParser {
    static func double(from text: String) -> Double? {
        let normalizedDecimalSeparator = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        return Double(normalizedDecimalSeparator)
    }
}
