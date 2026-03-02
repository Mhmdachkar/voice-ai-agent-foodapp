import Foundation

nonisolated struct MenuIndexEntry: Sendable {
    let id: String
    let name: String
    let category: String
    let tags: [String]
    let price: Double
    let calories: Int
    let protein: Int
    let prepTime: Int
    let isAvailable: Bool
    let ingredients: [String]
    let keywords: [String]
}

nonisolated struct MenuSearchFilters: Sendable {
    var maxPrice: Double?
    var maxCalories: Int?
    var minProtein: Int?
    var category: String?
    var tags: [String]?
    var excludeIngredients: [String]?

    init(maxPrice: Double? = nil, maxCalories: Int? = nil, minProtein: Int? = nil, category: String? = nil, tags: [String]? = nil, excludeIngredients: [String]? = nil) {
        self.maxPrice = maxPrice
        self.maxCalories = maxCalories
        self.minProtein = minProtein
        self.category = category
        self.tags = tags
        self.excludeIngredients = excludeIngredients
    }
}

@Observable
final class MenuSearchService {
    private var index: [MenuIndexEntry] = []

    func buildIndex(from items: [MenuItem]) {
        index = items.map { item in
            var keywords = [item.name.lowercased()]
            keywords.append(item.category.rawValue.lowercased())
            keywords.append(contentsOf: item.tags.map { $0.lowercased() })
            keywords.append(contentsOf: item.ingredients.map { $0.lowercased() })
            return MenuIndexEntry(
                id: item.id,
                name: item.name,
                category: item.category.rawValue,
                tags: item.tags,
                price: item.price,
                calories: item.calories,
                protein: item.nutritionInfo.protein,
                prepTime: item.prepTimeMinutes,
                isAvailable: item.isAvailable,
                ingredients: item.ingredients.map { $0.lowercased() },
                keywords: keywords
            )
        }
    }

    func search(query: String, filters: MenuSearchFilters = MenuSearchFilters(), maxResults: Int = 10) -> [MenuIndexEntry] {
        let terms = query.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        var candidates = index.filter { $0.isAvailable }

        if let maxPrice = filters.maxPrice {
            candidates = candidates.filter { $0.price <= maxPrice }
        }
        if let maxCal = filters.maxCalories {
            candidates = candidates.filter { $0.calories <= maxCal }
        }
        if let minProt = filters.minProtein {
            candidates = candidates.filter { $0.protein >= minProt }
        }
        if let cat = filters.category {
            candidates = candidates.filter { $0.category.lowercased() == cat.lowercased() }
        }
        if let tags = filters.tags, !tags.isEmpty {
            candidates = candidates.filter { entry in
                tags.contains { tag in entry.tags.contains(where: { $0.lowercased() == tag.lowercased() }) }
            }
        }
        if let excludes = filters.excludeIngredients, !excludes.isEmpty {
            candidates = candidates.filter { entry in
                !excludes.contains { excluded in entry.ingredients.contains(excluded.lowercased()) }
            }
        }

        guard !terms.isEmpty else { return Array(candidates.prefix(maxResults)) }

        let scored = candidates.map { entry -> (MenuIndexEntry, Int) in
            var score = 0
            for term in terms {
                if entry.name.lowercased().contains(term) { score += 10 }
                if entry.category.lowercased().contains(term) { score += 5 }
                for keyword in entry.keywords {
                    if keyword.contains(term) { score += 3 }
                }
                if term.contains("cheap") || term.contains("budget") || term.contains("affordable") {
                    score += entry.price < 15 ? 5 : 0
                }
                if term.contains("healthy") || term.contains("light") || term.contains("diet") {
                    score += entry.calories < 500 ? 5 : 0
                }
                if term.contains("protein") || term.contains("muscle") || term.contains("gym") {
                    score += entry.protein > 25 ? 5 : 0
                }
                if term.contains("quick") || term.contains("fast") {
                    score += entry.prepTime < 10 ? 5 : 0
                }
                if term.contains("spicy") || term.contains("hot") {
                    score += entry.tags.contains(where: { $0.lowercased() == "spicy" }) ? 5 : 0
                }
                if term.contains("comfort") || term.contains("hearty") || term.contains("warm") {
                    score += entry.tags.contains(where: { $0.lowercased() == "comfort" }) ? 5 : 0
                }
            }
            return (entry, score)
        }
        .filter { $0.1 > 0 }
        .sorted { $0.1 > $1.1 }

        return Array(scored.prefix(maxResults).map { $0.0 })
    }

    func findItem(byName name: String) -> MenuIndexEntry? {
        let lowered = name.lowercased()
        return index.first { $0.name.lowercased() == lowered } ??
               index.first { $0.name.lowercased().contains(lowered) || lowered.contains($0.name.lowercased()) }
    }

    func findItem(byId id: String) -> MenuIndexEntry? {
        index.first { $0.id == id }
    }

    func contextString(for entries: [MenuIndexEntry]) -> String {
        guard !entries.isEmpty else { return "No matching items found." }
        return entries.map { entry in
            "- \(entry.name) (\(entry.category)) $\(String(format: "%.2f", entry.price)), \(entry.calories)cal, \(entry.protein)g protein, ~\(entry.prepTime)min, tags: \(entry.tags.joined(separator: ", ")), ingredients: \(entry.ingredients.joined(separator: ", "))"
        }.joined(separator: "\n")
    }

    func fullContextString(limit: Int = 15) -> String {
        let available = index.filter { $0.isAvailable }
        return contextString(for: Array(available.prefix(limit)))
    }
}
