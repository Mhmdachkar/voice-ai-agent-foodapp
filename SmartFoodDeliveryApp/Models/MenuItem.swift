import Foundation

nonisolated struct MenuItem: Codable, Sendable, Identifiable, Equatable, Hashable {
    let id: String
    var name: String
    var description: String
    var price: Double
    var imageURL: String
    var category: MenuCategory
    var tags: [String]
    var calories: Int
    var prepTimeMinutes: Int
    var rating: Double
    var reviewCount: Int
    var isAvailable: Bool
    var isLimitedTime: Bool
    var limitedTimeEnd: Date?
    var modifierGroups: [ModifierGroup]
    var nutritionInfo: NutritionInfo
    var ingredients: [String]
    var allergens: [String]

    init(id: String = UUID().uuidString, name: String, description: String, price: Double, imageURL: String, category: MenuCategory, tags: [String] = [], calories: Int = 0, prepTimeMinutes: Int = 15, rating: Double = 4.5, reviewCount: Int = 0, isAvailable: Bool = true, isLimitedTime: Bool = false, limitedTimeEnd: Date? = nil, modifierGroups: [ModifierGroup] = [], nutritionInfo: NutritionInfo = NutritionInfo(), ingredients: [String] = [], allergens: [String] = []) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.imageURL = imageURL
        self.category = category
        self.tags = tags
        self.calories = calories
        self.prepTimeMinutes = prepTimeMinutes
        self.rating = rating
        self.reviewCount = reviewCount
        self.isAvailable = isAvailable
        self.isLimitedTime = isLimitedTime
        self.limitedTimeEnd = limitedTimeEnd
        self.modifierGroups = modifierGroups
        self.nutritionInfo = nutritionInfo
        self.ingredients = ingredients
        self.allergens = allergens
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

nonisolated enum MenuCategory: String, Codable, Sendable, CaseIterable, Identifiable {
    case burgers = "Burgers"
    case pizza = "Pizza"
    case sushi = "Sushi"
    case salads = "Salads"
    case pasta = "Pasta"
    case chicken = "Chicken"
    case seafood = "Seafood"
    case desserts = "Desserts"
    case drinks = "Drinks"
    case sides = "Sides"
    case breakfast = "Breakfast"
    case bowls = "Bowls"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .burgers: "🍔"
        case .pizza: "🍕"
        case .sushi: "🍣"
        case .salads: "🥗"
        case .pasta: "🍝"
        case .chicken: "🍗"
        case .seafood: "🦐"
        case .desserts: "🍰"
        case .drinks: "🥤"
        case .sides: "🍟"
        case .breakfast: "🥞"
        case .bowls: "🥙"
        }
    }
}

nonisolated struct ModifierGroup: Codable, Sendable, Identifiable, Equatable, Hashable {
    let id: String
    var name: String
    var required: Bool
    var maxSelections: Int
    var options: [ModifierOption]

    init(id: String = UUID().uuidString, name: String, required: Bool = false, maxSelections: Int = 1, options: [ModifierOption] = []) {
        self.id = id
        self.name = name
        self.required = required
        self.maxSelections = maxSelections
        self.options = options
    }
}

nonisolated struct ModifierOption: Codable, Sendable, Identifiable, Equatable, Hashable {
    let id: String
    var name: String
    var priceAdjustment: Double

    init(id: String = UUID().uuidString, name: String, priceAdjustment: Double = 0) {
        self.id = id
        self.name = name
        self.priceAdjustment = priceAdjustment
    }
}

nonisolated struct NutritionInfo: Codable, Sendable, Equatable, Hashable {
    var calories: Int
    var protein: Int
    var carbs: Int
    var fat: Int
    var fiber: Int
    var sugar: Int

    init(calories: Int = 0, protein: Int = 0, carbs: Int = 0, fat: Int = 0, fiber: Int = 0, sugar: Int = 0) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
    }
}
