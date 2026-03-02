import Foundation

nonisolated struct AppUser: Codable, Sendable, Identifiable, Equatable {
    let id: String
    var name: String
    var email: String
    var phone: String
    var role: UserRole
    var avatarURL: String?
    var address: DeliveryAddress?
    var foodMemory: FoodMemory
    var createdAt: Date

    init(id: String = UUID().uuidString, name: String, email: String, phone: String = "", role: UserRole, avatarURL: String? = nil, address: DeliveryAddress? = nil, foodMemory: FoodMemory = FoodMemory(), createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.role = role
        self.avatarURL = avatarURL
        self.address = address
        self.foodMemory = foodMemory
        self.createdAt = createdAt
    }
}

nonisolated struct DeliveryAddress: Codable, Sendable, Equatable {
    var street: String
    var city: String
    var state: String
    var zip: String
    var notes: String

    init(street: String = "", city: String = "", state: String = "", zip: String = "", notes: String = "") {
        self.street = street
        self.city = city
        self.state = state
        self.zip = zip
        self.notes = notes
    }

    var formatted: String {
        [street, city, state, zip].filter { !$0.isEmpty }.joined(separator: ", ")
    }
}

nonisolated struct FoodMemory: Codable, Sendable, Equatable {
    var dislikedIngredients: [String]
    var spiceLevel: SpiceLevel
    var defaultDrink: String?
    var commonNotes: String?
    var preferredCuisines: [String]

    init(dislikedIngredients: [String] = [], spiceLevel: SpiceLevel = .medium, defaultDrink: String? = nil, commonNotes: String? = nil, preferredCuisines: [String] = []) {
        self.dislikedIngredients = dislikedIngredients
        self.spiceLevel = spiceLevel
        self.defaultDrink = defaultDrink
        self.commonNotes = commonNotes
        self.preferredCuisines = preferredCuisines
    }
}

nonisolated enum SpiceLevel: String, Codable, Sendable, CaseIterable {
    case none = "No Spice"
    case mild = "Mild"
    case medium = "Medium"
    case hot = "Hot"
    case extraHot = "Extra Hot"
}
