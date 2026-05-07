import Foundation

enum APIEndpoint {
    case searchFood(query: String)

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
        }
    }
}
