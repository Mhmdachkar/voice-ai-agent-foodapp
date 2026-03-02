import Foundation

@Observable
final class FoodMemoryService {
    private static let storageKey = "food_memory_v1"
    var memory: FoodMemory

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode(FoodMemory.self, from: data) {
            memory = decoded
        } else {
            memory = FoodMemory()
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(memory) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    func addDislikedIngredient(_ ingredient: String) {
        let normalized = ingredient.lowercased().trimmingCharacters(in: .whitespaces)
        guard !memory.dislikedIngredients.contains(normalized) else { return }
        memory.dislikedIngredients.append(normalized)
        save()
    }

    func removeDislikedIngredient(_ ingredient: String) {
        memory.dislikedIngredients.removeAll { $0 == ingredient.lowercased() }
        save()
    }

    func setSpiceLevel(_ level: SpiceLevel) {
        memory.spiceLevel = level
        save()
    }

    func setDefaultDrink(_ drink: String?) {
        memory.defaultDrink = drink
        save()
    }

    func setCommonNotes(_ notes: String?) {
        memory.commonNotes = notes
        save()
    }

    func contextString() -> String {
        var parts: [String] = []
        if !memory.dislikedIngredients.isEmpty {
            parts.append("Dislikes: \(memory.dislikedIngredients.joined(separator: ", "))")
        }
        parts.append("Spice level: \(memory.spiceLevel.rawValue)")
        if let drink = memory.defaultDrink {
            parts.append("Default drink: \(drink)")
        }
        if let notes = memory.commonNotes {
            parts.append("Usual notes: \(notes)")
        }
        if !memory.preferredCuisines.isEmpty {
            parts.append("Preferred cuisines: \(memory.preferredCuisines.joined(separator: ", "))")
        }
        return parts.isEmpty ? "No preferences saved yet." : parts.joined(separator: "\n")
    }
}
