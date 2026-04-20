import Foundation

enum MealPeriod: String, CaseIterable {
    case breakfast = "Sáng"
    case lunch = "Trưa"
    case snack = "Snack"
    case dinner = "Tối"

    static func from(hour: Int) -> MealPeriod {
        switch hour {
        case 7...10:
            return .breakfast
        case 11...13:
            return .lunch
        case 14...17:
            return .snack
        default:
            return .dinner
        }
    }

    static func from(date: Date, calendar: Calendar = .current) -> MealPeriod {
        from(hour: calendar.component(.hour, from: date))
    }

    var title: String { rawValue }
}
