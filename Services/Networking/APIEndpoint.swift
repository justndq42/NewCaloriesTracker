import Foundation

enum APIEndpoint {
    case searchFood(query: String)
    case mealPlan(goal: String, calories: Int)

    var url: URL? {
        switch self {
        case .searchFood(let query):
            var c = URLComponents(string: "https://world.openfoodfacts.org/cgi/search.pl")
            c?.queryItems = [
                URLQueryItem(name: "search_terms",  value: query),
                URLQueryItem(name: "search_simple", value: "1"),
                URLQueryItem(name: "action",        value: "process"),
                URLQueryItem(name: "json",          value: "1"),
                URLQueryItem(name: "page_size",     value: "20"),
                URLQueryItem(name: "sort_by",       value: "unique_scans_n"),
                URLQueryItem(name: "fields",        value: "product_name,product_name_en,nutriments,serving_size,quantity"),
            ]
            return c?.url

        case .mealPlan(let goal, let calories):
            var c = URLComponents(string: "https://api.spoonacular.com/mealplanner/generate")
            let mealCount = goal == "gain" ? 5 : 3
            c?.queryItems = [
                URLQueryItem(name: "apiKey",         value: "40fb1118a4714ca296a1c7b42a6f7cfb"),
                URLQueryItem(name: "timeFrame",      value: "day"),
                URLQueryItem(name: "targetCalories", value: "\(calories)"),
                URLQueryItem(name: "number",         value: "\(mealCount)"),
            ]
            return c?.url
        }
    }
}
