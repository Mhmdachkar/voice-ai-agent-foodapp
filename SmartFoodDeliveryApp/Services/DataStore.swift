import Foundation

@Observable
final class DataStore {
    var menuItems: [MenuItem] = []
    var orders: [Order] = []
    var notifications: [AppNotification] = []
    var drivers: [AppUser] = []
    var isLoading: Bool = false
    var useSupabase: Bool = true

    let menuService = SupabaseMenuService()
    let orderService = SupabaseOrderService()
    let driverService = SupabaseDriverService()
    let realtimeService = RealtimeService()

    init() {
        loadSeedData()
    }

    private func loadSeedData() {
        menuItems = Self.sampleMenuItems
        drivers = Self.sampleDrivers
    }

    func loadFromSupabase(userId: String, role: UserRole) async {
        isLoading = true
        await menuService.fetchMenuItems()
        if !menuService.menuItems.isEmpty {
            menuItems = menuService.menuItems
        }

        let fetchedOrders = await orderService.fetchOrders(userId: userId, role: role)
        if !fetchedOrders.isEmpty || role == .admin {
            orders = fetchedOrders
        }

        if role == .admin {
            await driverService.fetchDrivers()
            if !driverService.onlineDrivers.isEmpty {
                drivers = driverService.onlineDrivers
            } else {
                let allDrivers = await driverService.fetchAllDriverProfiles()
                if !allDrivers.isEmpty {
                    drivers = allDrivers
                }
            }
        }

        isLoading = false
    }

    func refreshOrders(userId: String, role: UserRole) async {
        let fetchedOrders = await orderService.fetchOrders(userId: userId, role: role)
        orders = fetchedOrders
    }

    func refreshMenu() async {
        await menuService.fetchMenuItems()
        if !menuService.menuItems.isEmpty {
            menuItems = menuService.menuItems
        }
    }

    func placeOrder(_ order: Order) {
        var newOrder = order
        newOrder.timeline = [OrderTimelineEvent(status: .placed)]
        orders.insert(newOrder, at: 0)
        addNotification(AppNotification(
            title: "Order Placed!",
            body: "Your order #\(order.id.prefix(6)) has been placed successfully.",
            type: .orderUpdate,
            orderId: order.id
        ))
        EventBus.shared.publish(.orderPlaced(order.id))
    }

    func placeOrderViaSupabase(
        userId: String, customerName: String, items: [CartItem],
        address: DeliveryAddress, notes: String, promoCode: String?,
        tip: Double, paymentMethod: String
    ) async -> String? {
        let orderId = await orderService.createOrder(
            userId: userId, customerName: customerName, items: items,
            address: address, notes: notes, promoCode: promoCode,
            tip: tip, paymentMethod: paymentMethod
        )
        if let orderId {
            addNotification(AppNotification(
                title: "Order Placed!",
                body: "Your order has been placed successfully.",
                type: .orderUpdate,
                orderId: orderId
            ))
            EventBus.shared.publish(.orderPlaced(orderId))
            await refreshOrders(userId: userId, role: .customer)
        }
        return orderId
    }

    func updateOrderStatus(_ orderId: String, to status: OrderStatus, changedBy: String? = nil) {
        if let changedBy {
            Task {
                let success = await orderService.updateStatus(orderId: orderId, newStatus: status, changedBy: changedBy)
                if success {
                    if let index = orders.firstIndex(where: { $0.id == orderId }) {
                        orders[index].status = status
                        orders[index].timeline.append(OrderTimelineEvent(status: status))
                    }
                    EventBus.shared.publish(.orderStatusChanged(orderId, status))
                }
            }
        } else {
            guard let index = orders.firstIndex(where: { $0.id == orderId }) else { return }
            orders[index].status = status
            orders[index].timeline.append(OrderTimelineEvent(status: status))
            EventBus.shared.publish(.orderStatusChanged(orderId, status))
        }
    }

    func assignDriver(_ orderId: String, driverId: String, driverName: String, assignedBy: String? = nil) {
        if let assignedBy {
            Task {
                let success = await orderService.assignDriver(orderId: orderId, driverId: driverId, assignedBy: assignedBy)
                if success {
                    if let index = orders.firstIndex(where: { $0.id == orderId }) {
                        orders[index].driverId = driverId
                        orders[index].driverName = driverName
                    }
                    EventBus.shared.publish(.driverAssigned(orderId, driverId))
                }
            }
        } else {
            guard let index = orders.firstIndex(where: { $0.id == orderId }) else { return }
            guard orders[index].driverId == nil else { return }
            orders[index].driverId = driverId
            orders[index].driverName = driverName
            orders[index].status = .outForDelivery
            orders[index].timeline.append(OrderTimelineEvent(status: .outForDelivery, note: "Driver \(driverName) assigned"))
            EventBus.shared.publish(.driverAssigned(orderId, driverId))
        }
    }

    func driverAcceptOrder(_ orderId: String, driverId: String) {
        Task {
            let success = await orderService.driverAcceptOrder(orderId: orderId, driverId: driverId)
            if success {
                if let index = orders.firstIndex(where: { $0.id == orderId }) {
                    orders[index].driverId = driverId
                    orders[index].status = .outForDelivery
                    orders[index].timeline.append(OrderTimelineEvent(status: .outForDelivery, note: "Driver accepted"))
                }
                EventBus.shared.publish(.driverAssigned(orderId, driverId))
            }
        }
    }

    func toggleMenuItemAvailability(_ itemId: String) {
        guard let index = menuItems.firstIndex(where: { $0.id == itemId }) else { return }
        let newValue = !menuItems[index].isAvailable
        menuItems[index].isAvailable = newValue
        Task {
            await menuService.toggleAvailability(itemId: itemId, isAvailable: newValue)
        }
    }

    func addNotification(_ notification: AppNotification) {
        notifications.insert(notification, at: 0)
    }

    func ordersForCustomer(_ customerId: String) -> [Order] {
        orders.filter { $0.customerId == customerId }
    }

    func ordersForDriver(_ driverId: String) -> [Order] {
        orders.filter { $0.driverId == driverId }
    }

    func availableOrders() -> [Order] {
        orders.filter { $0.status == .ready && $0.driverId == nil }
    }

    func activeOrders() -> [Order] {
        orders.filter { $0.status.isActive }
    }

    func subscribeToRealtimeUpdates() {
        Task {
            await realtimeService.subscribeToOrders { [weak self] dbOrder in
                guard let self else { return }
                let updated = dbOrder.toOrder()
                if let idx = self.orders.firstIndex(where: { $0.id == updated.id }) {
                    self.orders[idx].status = updated.status
                    self.orders[idx].driverId = updated.driverId
                    self.orders[idx].driverName = updated.driverName
                }
            }
        }
    }

    func unsubscribeFromRealtime() {
        Task {
            await realtimeService.unsubscribe()
        }
    }

    static let sampleDrivers: [AppUser] = [
        AppUser(id: "driver1", name: "Marcus Johnson", email: "marcus@delivery.com", phone: "555-0101", role: .driver),
        AppUser(id: "driver2", name: "Sarah Chen", email: "sarah@delivery.com", phone: "555-0102", role: .driver),
        AppUser(id: "driver3", name: "David Williams", email: "david@delivery.com", phone: "555-0103", role: .driver),
    ]

    static let sampleMenuItems: [MenuItem] = [
        MenuItem(name: "Smash Burger Deluxe", description: "Double smashed beef patties with melted American cheese, caramelized onions, pickles, and our signature sauce on a brioche bun.", price: 14.99, imageURL: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800", category: .burgers, tags: ["Popular", "Best Seller"], calories: 850, prepTimeMinutes: 12, rating: 4.8, reviewCount: 342, modifierGroups: [
            ModifierGroup(name: "Patty", required: true, options: [
                ModifierOption(name: "Single", priceAdjustment: -2),
                ModifierOption(name: "Double"),
                ModifierOption(name: "Triple", priceAdjustment: 3),
            ]),
            ModifierGroup(name: "Add-ons", maxSelections: 5, options: [
                ModifierOption(name: "Bacon", priceAdjustment: 2),
                ModifierOption(name: "Avocado", priceAdjustment: 1.5),
                ModifierOption(name: "Fried Egg", priceAdjustment: 1.5),
            ]),
        ], nutritionInfo: NutritionInfo(calories: 850, protein: 45, carbs: 52, fat: 48, fiber: 3, sugar: 12), ingredients: ["Beef", "Cheese", "Onions", "Pickles", "Brioche Bun"], allergens: ["Gluten", "Dairy"]),
        MenuItem(name: "Truffle Mushroom Pizza", description: "Wood-fired pizza with truffle cream, wild mushrooms, mozzarella, and fresh thyme.", price: 18.99, imageURL: "https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=800", category: .pizza, tags: ["Chef's Special"], calories: 720, prepTimeMinutes: 18, rating: 4.7, reviewCount: 218, nutritionInfo: NutritionInfo(calories: 720, protein: 28, carbs: 68, fat: 38, fiber: 4, sugar: 6), ingredients: ["Flour", "Truffle Oil", "Mushrooms", "Mozzarella", "Thyme"], allergens: ["Gluten", "Dairy"]),
        MenuItem(name: "Dragon Roll Platter", description: "Shrimp tempura roll topped with avocado, eel sauce, spicy mayo, and tobiko.", price: 22.99, imageURL: "https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=800", category: .sushi, tags: ["Premium"], calories: 480, prepTimeMinutes: 20, rating: 4.9, reviewCount: 156, nutritionInfo: NutritionInfo(calories: 480, protein: 22, carbs: 58, fat: 18, fiber: 5, sugar: 8), ingredients: ["Rice", "Shrimp", "Avocado", "Nori", "Tobiko"], allergens: ["Shellfish", "Gluten"]),
        MenuItem(name: "Mediterranean Power Bowl", description: "Quinoa base with grilled chicken, hummus, feta, roasted vegetables, and lemon tahini dressing.", price: 15.99, imageURL: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800", category: .bowls, tags: ["Healthy", "High Protein"], calories: 520, prepTimeMinutes: 10, rating: 4.6, reviewCount: 289, nutritionInfo: NutritionInfo(calories: 520, protein: 38, carbs: 45, fat: 22, fiber: 8, sugar: 6), ingredients: ["Quinoa", "Chicken", "Hummus", "Feta", "Vegetables"], allergens: ["Dairy"]),
        MenuItem(name: "Spicy Tuna Poke Bowl", description: "Fresh ahi tuna, sushi rice, edamame, mango, avocado, with sriracha aioli.", price: 17.99, imageURL: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800", category: .bowls, tags: ["Spicy", "Fresh"], calories: 450, prepTimeMinutes: 8, rating: 4.7, reviewCount: 198, nutritionInfo: NutritionInfo(calories: 450, protein: 32, carbs: 48, fat: 16, fiber: 6, sugar: 10), ingredients: ["Tuna", "Rice", "Edamame", "Mango", "Avocado"], allergens: ["Fish", "Soy"]),
        MenuItem(name: "Crispy Chicken Sandwich", description: "Buttermilk-brined crispy chicken thigh with coleslaw, pickles, and chipotle mayo.", price: 13.99, imageURL: "https://images.unsplash.com/photo-1606755962773-d324e0a13086?w=800", category: .chicken, tags: ["Popular"], calories: 680, prepTimeMinutes: 14, rating: 4.5, reviewCount: 412, nutritionInfo: NutritionInfo(calories: 680, protein: 35, carbs: 55, fat: 32, fiber: 3, sugar: 8), ingredients: ["Chicken", "Buttermilk", "Coleslaw", "Pickles", "Brioche"], allergens: ["Gluten", "Dairy", "Eggs"]),
        MenuItem(name: "Caesar Salad Supreme", description: "Crisp romaine, shaved parmesan, garlic croutons, and house-made caesar dressing.", price: 12.99, imageURL: "https://images.unsplash.com/photo-1550304943-4f24f54ddde9?w=800", category: .salads, tags: ["Light", "Classic"], calories: 380, prepTimeMinutes: 6, rating: 4.3, reviewCount: 167, nutritionInfo: NutritionInfo(calories: 380, protein: 18, carbs: 22, fat: 26, fiber: 4, sugar: 4), ingredients: ["Romaine", "Parmesan", "Croutons", "Anchovies"], allergens: ["Gluten", "Dairy", "Fish"]),
        MenuItem(name: "Garlic Butter Shrimp Pasta", description: "Al dente linguine with sautéed shrimp, garlic butter, white wine, cherry tomatoes, and fresh basil.", price: 19.99, imageURL: "https://images.unsplash.com/photo-1563379926898-05f4575a45d8?w=800", category: .pasta, tags: ["Indulgent"], calories: 720, prepTimeMinutes: 16, rating: 4.6, reviewCount: 234, nutritionInfo: NutritionInfo(calories: 720, protein: 32, carbs: 65, fat: 34, fiber: 4, sugar: 6), ingredients: ["Linguine", "Shrimp", "Garlic", "White Wine", "Tomatoes"], allergens: ["Gluten", "Shellfish", "Dairy"]),
        MenuItem(name: "Matcha Latte", description: "Ceremonial grade matcha whisked with oat milk and a touch of vanilla.", price: 5.99, imageURL: "https://images.unsplash.com/photo-1536256263959-770b48d82b0a?w=800", category: .drinks, tags: ["Healthy", "Energizing"], calories: 180, prepTimeMinutes: 3, rating: 4.4, reviewCount: 521, nutritionInfo: NutritionInfo(calories: 180, protein: 4, carbs: 28, fat: 6, fiber: 1, sugar: 16), ingredients: ["Matcha", "Oat Milk", "Vanilla"], allergens: []),
        MenuItem(name: "Tiramisu", description: "Classic Italian dessert with layers of espresso-soaked ladyfingers, mascarpone cream, and cocoa.", price: 9.99, imageURL: "https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=800", category: .desserts, tags: ["Classic", "Indulgent"], calories: 420, prepTimeMinutes: 5, rating: 4.8, reviewCount: 312, nutritionInfo: NutritionInfo(calories: 420, protein: 8, carbs: 48, fat: 22, fiber: 1, sugar: 32), ingredients: ["Mascarpone", "Espresso", "Ladyfingers", "Cocoa"], allergens: ["Gluten", "Dairy", "Eggs"]),
        MenuItem(name: "Loaded Sweet Potato Fries", description: "Crispy sweet potato fries topped with queso, jalapeños, bacon bits, and sour cream.", price: 8.99, imageURL: "https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=800", category: .sides, tags: ["Comfort"], calories: 520, prepTimeMinutes: 10, rating: 4.5, reviewCount: 278, nutritionInfo: NutritionInfo(calories: 520, protein: 12, carbs: 58, fat: 28, fiber: 6, sugar: 14), ingredients: ["Sweet Potato", "Queso", "Jalapeños", "Bacon"], allergens: ["Dairy"]),
        MenuItem(name: "Avocado Toast Deluxe", description: "Sourdough toast with smashed avocado, poached eggs, everything seasoning, microgreens, and chili flakes.", price: 11.99, imageURL: "https://images.unsplash.com/photo-1541519227354-08fa5d50c44d?w=800", category: .breakfast, tags: ["Healthy", "Popular"], calories: 420, prepTimeMinutes: 8, rating: 4.6, reviewCount: 345, nutritionInfo: NutritionInfo(calories: 420, protein: 16, carbs: 35, fat: 26, fiber: 8, sugar: 4), ingredients: ["Sourdough", "Avocado", "Eggs", "Microgreens"], allergens: ["Gluten", "Eggs"]),
        MenuItem(name: "Grilled Salmon Plate", description: "Atlantic salmon with lemon herb butter, roasted asparagus, and wild rice pilaf.", price: 24.99, imageURL: "https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800", category: .seafood, tags: ["Premium", "Healthy"], calories: 580, prepTimeMinutes: 22, rating: 4.8, reviewCount: 189, nutritionInfo: NutritionInfo(calories: 580, protein: 42, carbs: 35, fat: 28, fiber: 5, sugar: 3), ingredients: ["Salmon", "Asparagus", "Wild Rice", "Lemon", "Herbs"], allergens: ["Fish"]),
        MenuItem(name: "Mango Smoothie Bowl", description: "Thick mango smoothie base topped with granola, coconut flakes, chia seeds, and fresh berries.", price: 10.99, imageURL: "https://images.unsplash.com/photo-1590301157890-4810ed352733?w=800", category: .breakfast, tags: ["Healthy", "Vegan"], calories: 380, prepTimeMinutes: 5, rating: 4.5, reviewCount: 234, isLimitedTime: true, limitedTimeEnd: Date().addingTimeInterval(86400 * 3), nutritionInfo: NutritionInfo(calories: 380, protein: 8, carbs: 62, fat: 12, fiber: 8, sugar: 38), ingredients: ["Mango", "Banana", "Granola", "Coconut", "Chia Seeds"], allergens: ["Tree Nuts"]),
    ]
}
