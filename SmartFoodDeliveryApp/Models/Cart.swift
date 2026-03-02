import Foundation

nonisolated struct CartItem: Codable, Sendable, Identifiable, Equatable {
    let id: String
    let menuItem: MenuItem
    var quantity: Int
    var selectedModifiers: [String: [String]]
    var specialInstructions: String

    init(id: String = UUID().uuidString, menuItem: MenuItem, quantity: Int = 1, selectedModifiers: [String: [String]] = [:], specialInstructions: String = "") {
        self.id = id
        self.menuItem = menuItem
        self.quantity = quantity
        self.selectedModifiers = selectedModifiers
        self.specialInstructions = specialInstructions
    }

    var itemTotal: Double {
        var modifierTotal = 0.0
        for (groupName, optionNames) in selectedModifiers {
            if let group = menuItem.modifierGroups.first(where: { $0.name == groupName }) {
                for optionName in optionNames {
                    if let option = group.options.first(where: { $0.name == optionName }) {
                        modifierTotal += option.priceAdjustment
                    }
                }
            }
        }
        return (menuItem.price + modifierTotal) * Double(quantity)
    }
}

nonisolated enum Mood: String, Codable, Sendable, CaseIterable, Identifiable {
    case comfort = "Comfort"
    case light = "Light"
    case energizing = "Energizing"
    case spicy = "Spicy"
    case healthy = "Healthy"
    case indulgent = "Indulgent"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .comfort: "cup.and.saucer.fill"
        case .light: "leaf.fill"
        case .energizing: "bolt.fill"
        case .spicy: "flame.fill"
        case .healthy: "heart.fill"
        case .indulgent: "birthday.cake.fill"
        }
    }

    var emoji: String {
        switch self {
        case .comfort: "🫖"
        case .light: "🥗"
        case .energizing: "⚡️"
        case .spicy: "🌶️"
        case .healthy: "💚"
        case .indulgent: "🎂"
        }
    }
}
