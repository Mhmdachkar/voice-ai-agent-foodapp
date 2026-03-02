import Foundation

@Observable
final class AIClient {
    var isProcessing: Bool = false
    var lastResponse: String = ""

    func processVoiceCommand(_ transcript: String, menuItems: [MenuItem]) async -> AIOrderResponse {
        isProcessing = true
        defer { isProcessing = false }

        try? await Task.sleep(for: .seconds(1.5))

        let lowered = transcript.lowercased()

        var suggestedItems: [MenuItem] = []

        for item in menuItems {
            if lowered.contains(item.name.lowercased()) ||
               lowered.contains(item.category.rawValue.lowercased()) {
                suggestedItems.append(item)
            }
        }

        if suggestedItems.isEmpty {
            if lowered.contains("burger") || lowered.contains("hungry") {
                suggestedItems = menuItems.filter { $0.category == .burgers }.prefix(2).map { $0 }
            } else if lowered.contains("healthy") || lowered.contains("light") || lowered.contains("salad") {
                suggestedItems = menuItems.filter { $0.tags.contains("Healthy") }.prefix(3).map { $0 }
            } else if lowered.contains("spicy") {
                suggestedItems = menuItems.filter { $0.tags.contains("Spicy") || $0.category == .sushi }.prefix(2).map { $0 }
            } else if lowered.contains("comfort") || lowered.contains("warm") {
                suggestedItems = menuItems.filter { $0.tags.contains("Comfort") || $0.category == .pasta }.prefix(2).map { $0 }
            } else {
                suggestedItems = Array(menuItems.sorted { $0.rating > $1.rating }.prefix(3))
            }
        }

        let itemNames = suggestedItems.map { $0.name }.joined(separator: ", ")
        let response = "Based on your request, I'd suggest: \(itemNames). Shall I add these to your cart?"

        lastResponse = response
        return AIOrderResponse(message: response, suggestedItems: suggestedItems)
    }

    func getMoodSuggestions(mood: Mood, menuItems: [MenuItem]) -> [MenuItem] {
        switch mood {
        case .comfort:
            return menuItems.filter { $0.category == .burgers || $0.category == .pasta || $0.tags.contains("Comfort") }
        case .light:
            return menuItems.filter { $0.calories < 500 || $0.category == .salads }
        case .energizing:
            return menuItems.filter { $0.tags.contains("Energizing") || $0.category == .bowls }
        case .spicy:
            return menuItems.filter { $0.tags.contains("Spicy") || $0.category == .sushi }
        case .healthy:
            return menuItems.filter { $0.tags.contains("Healthy") || $0.nutritionInfo.protein > 25 }
        case .indulgent:
            return menuItems.filter { $0.tags.contains("Indulgent") || $0.category == .desserts }
        }
    }

    func getBudgetSuggestions(maxBudget: Double, menuItems: [MenuItem]) -> [MenuItem] {
        menuItems.filter { $0.price <= maxBudget }.sorted { $0.rating > $1.rating }
    }

    func getNutritionSuggestions(filter: NutritionFilter, menuItems: [MenuItem]) -> [MenuItem] {
        switch filter {
        case .highProtein:
            return menuItems.filter { $0.nutritionInfo.protein >= 25 }.sorted { $0.nutritionInfo.protein > $1.nutritionInfo.protein }
        case .lowCalorie:
            return menuItems.filter { $0.calories <= 500 }.sorted { $0.calories < $1.calories }
        case .lowSugar:
            return menuItems.filter { $0.nutritionInfo.sugar <= 10 }.sorted { $0.nutritionInfo.sugar < $1.nutritionInfo.sugar }
        case .vegetarian:
            return menuItems.filter { !$0.ingredients.contains("Beef") && !$0.ingredients.contains("Chicken") && !$0.ingredients.contains("Shrimp") && !$0.ingredients.contains("Salmon") && !$0.ingredients.contains("Tuna") }
        }
    }
}

nonisolated struct AIOrderResponse: Sendable {
    let message: String
    let suggestedItems: [MenuItem]
}

nonisolated enum NutritionFilter: String, CaseIterable, Sendable {
    case highProtein = "High Protein"
    case lowCalorie = "Low Calorie"
    case lowSugar = "Low Sugar"
    case vegetarian = "Vegetarian"

    var icon: String {
        switch self {
        case .highProtein: "figure.strengthtraining.traditional"
        case .lowCalorie: "flame"
        case .lowSugar: "leaf"
        case .vegetarian: "carrot"
        }
    }
}
