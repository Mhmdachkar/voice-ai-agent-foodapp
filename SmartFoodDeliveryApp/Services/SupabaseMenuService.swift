import Foundation
import Supabase

nonisolated struct MenuAvailabilityUpdate: Encodable, Sendable {
    let is_available: Bool
}

@Observable
final class SupabaseMenuService {
    var menuItems: [MenuItem] = []
    var categories: [DBCategory] = []
    var isLoading: Bool = false
    var errorMessage: String?

    private var client: SupabaseClient { SupabaseManager.shared.client }

    private let categoryMap: [String: MenuCategory] = [
        "Burgers": .burgers, "Pizza": .pizza, "Sushi": .sushi,
        "Salads": .salads, "Pasta": .pasta, "Chicken": .chicken,
        "Seafood": .seafood, "Desserts": .desserts, "Drinks": .drinks,
        "Sides": .sides, "Breakfast": .breakfast, "Bowls": .bowls
    ]

    func fetchCategories() async {
        do {
            categories = try await client.from("categories")
                .select()
                .order("sort_order")
                .execute()
                .value
        } catch {}
    }

    func fetchMenuItems() async {
        isLoading = true
        do {
            await fetchCategories()

            let dbItems: [DBMenuItem] = try await client.from("menu_items")
                .select()
                .execute()
                .value

            var catIdToEnum: [String: MenuCategory] = [:]
            for cat in categories {
                if let mc = categoryMap[cat.name] {
                    catIdToEnum[cat.id] = mc
                }
            }

            let dbGroups: [DBModifierGroup] = try await client.from("modifier_groups")
                .select()
                .execute()
                .value

            let dbOptions: [DBModifierOption] = try await client.from("modifier_options")
                .select()
                .execute()
                .value

            let dbLinks: [DBItemModifierGroup] = try await client.from("item_modifier_groups")
                .select()
                .execute()
                .value

            let optionsByGroup = Dictionary(grouping: dbOptions, by: { $0.groupId })
            let groupMap = Dictionary(uniqueKeysWithValues: dbGroups.map { ($0.id, $0) })
            let linksByItem = Dictionary(grouping: dbLinks, by: { $0.itemId })

            menuItems = dbItems.map { dbItem in
                var item = dbItem.toMenuItem(categoryMap: catIdToEnum)

                if let links = linksByItem[dbItem.id] {
                    item.modifierGroups = links.compactMap { link in
                        guard let group = groupMap[link.groupId] else { return nil }
                        let options = (optionsByGroup[group.id] ?? []).map { opt in
                            ModifierOption(id: opt.id, name: opt.name, priceAdjustment: opt.priceDelta ?? 0)
                        }
                        return ModifierGroup(
                            id: group.id,
                            name: group.name,
                            required: group.required ?? false,
                            maxSelections: group.maxSelect ?? 1,
                            options: options
                        )
                    }
                }
                return item
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func toggleAvailability(itemId: String, isAvailable: Bool) async {
        do {
            let update = MenuAvailabilityUpdate(is_available: isAvailable)
            try await client.from("menu_items")
                .update(update)
                .eq("id", value: itemId)
                .execute()

            if let idx = menuItems.firstIndex(where: { $0.id == itemId }) {
                menuItems[idx].isAvailable = isAvailable
            }
        } catch {}
    }
}
