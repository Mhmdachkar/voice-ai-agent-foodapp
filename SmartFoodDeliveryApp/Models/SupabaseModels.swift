import Foundation

nonisolated struct DBProfile: Codable, Sendable {
    let id: String
    let role: String
    let fullName: String
    let email: String?
    let phone: String?
    let avatarUrl: String?
    let foodMemory: FoodMemoryJSON?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, role, email, phone
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case foodMemory = "food_memory"
        case createdAt = "created_at"
    }

    func toAppUser() -> AppUser {
        let userRole: UserRole = UserRole(rawValue: role) ?? .customer
        let memory: FoodMemory
        if let fm = foodMemory {
            memory = FoodMemory(
                dislikedIngredients: fm.dislikedIngredients ?? [],
                spiceLevel: SpiceLevel(rawValue: fm.spiceLevel ?? "Medium") ?? .medium,
                defaultDrink: fm.defaultDrink,
                commonNotes: fm.commonNotes,
                preferredCuisines: fm.preferredCuisines ?? []
            )
        } else {
            memory = FoodMemory()
        }
        return AppUser(
            id: id,
            name: fullName,
            email: email ?? "",
            phone: phone ?? "",
            role: userRole,
            avatarURL: avatarUrl,
            foodMemory: memory
        )
    }
}

nonisolated struct FoodMemoryJSON: Codable, Sendable {
    let dislikedIngredients: [String]?
    let spiceLevel: String?
    let defaultDrink: String?
    let commonNotes: String?
    let preferredCuisines: [String]?

    enum CodingKeys: String, CodingKey {
        case dislikedIngredients = "disliked_ingredients"
        case spiceLevel = "spice_level"
        case defaultDrink = "default_drink"
        case commonNotes = "common_notes"
        case preferredCuisines = "preferred_cuisines"
    }
}

nonisolated struct DBCategory: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let icon: String?
    let sortOrder: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, icon
        case sortOrder = "sort_order"
    }
}

nonisolated struct DBMenuItem: Codable, Sendable, Identifiable {
    let id: String
    let categoryId: String?
    let name: String
    let description: String?
    let price: Double
    let imageUrl: String?
    let tags: [String]?
    let calories: Int?
    let prepTimeMinutes: Int?
    let rating: Double?
    let reviewCount: Int?
    let isAvailable: Bool?
    let isLimitedTime: Bool?
    let limitedTimeEnd: String?
    let nutritionInfo: NutritionInfoJSON?
    let ingredients: [String]?
    let allergens: [String]?

    enum CodingKeys: String, CodingKey {
        case id, name, description, price, tags, calories, rating, ingredients, allergens
        case categoryId = "category_id"
        case imageUrl = "image_url"
        case prepTimeMinutes = "prep_time_minutes"
        case reviewCount = "review_count"
        case isAvailable = "is_available"
        case isLimitedTime = "is_limited_time"
        case limitedTimeEnd = "limited_time_end"
        case nutritionInfo = "nutrition_info"
    }

    func toMenuItem(categoryMap: [String: MenuCategory]) -> MenuItem {
        let cat = categoryMap[categoryId ?? ""] ?? .bowls
        let ni = nutritionInfo ?? NutritionInfoJSON()
        var endDate: Date? = nil
        if let lte = limitedTimeEnd {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            endDate = formatter.date(from: lte)
        }
        return MenuItem(
            id: id,
            name: name,
            description: description ?? "",
            price: price,
            imageURL: imageUrl ?? "",
            category: cat,
            tags: tags ?? [],
            calories: calories ?? 0,
            prepTimeMinutes: prepTimeMinutes ?? 15,
            rating: rating ?? 4.5,
            reviewCount: reviewCount ?? 0,
            isAvailable: isAvailable ?? true,
            isLimitedTime: isLimitedTime ?? false,
            limitedTimeEnd: endDate,
            nutritionInfo: NutritionInfo(
                calories: ni.calories ?? 0, protein: ni.protein ?? 0,
                carbs: ni.carbs ?? 0, fat: ni.fat ?? 0,
                fiber: ni.fiber ?? 0, sugar: ni.sugar ?? 0
            ),
            ingredients: ingredients ?? [],
            allergens: allergens ?? []
        )
    }
}

nonisolated struct NutritionInfoJSON: Codable, Sendable {
    let calories: Int?
    let protein: Int?
    let carbs: Int?
    let fat: Int?
    let fiber: Int?
    let sugar: Int?

    init(calories: Int? = nil, protein: Int? = nil, carbs: Int? = nil, fat: Int? = nil, fiber: Int? = nil, sugar: Int? = nil) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
    }
}

nonisolated struct DBModifierGroup: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let minSelect: Int?
    let maxSelect: Int?
    let required: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, required
        case minSelect = "min_select"
        case maxSelect = "max_select"
    }
}

nonisolated struct DBModifierOption: Codable, Sendable, Identifiable {
    let id: String
    let groupId: String
    let name: String
    let priceDelta: Double?
    let isAvailable: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name
        case groupId = "group_id"
        case priceDelta = "price_delta"
        case isAvailable = "is_available"
    }
}

nonisolated struct DBItemModifierGroup: Codable, Sendable {
    let itemId: String
    let groupId: String

    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case groupId = "group_id"
    }
}

nonisolated struct DBOrder: Codable, Sendable, Identifiable {
    let id: String
    let userId: String
    let customerName: String?
    let deliveryMethod: String?
    let status: String
    let paymentMethod: String?
    let subtotal: Double?
    let deliveryFee: Double?
    let tax: Double?
    let discount: Double?
    let tip: Double?
    let total: Double?
    let addressSnapshot: AddressSnapshotJSON?
    let notes: String?
    let promoCode: String?
    let assignedDriverId: String?
    let driverName: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, status, subtotal, tax, tip, total, notes, discount
        case userId = "user_id"
        case customerName = "customer_name"
        case deliveryMethod = "delivery_method"
        case paymentMethod = "payment_method"
        case deliveryFee = "delivery_fee"
        case addressSnapshot = "address_snapshot"
        case promoCode = "promo_code"
        case assignedDriverId = "assigned_driver_id"
        case driverName = "driver_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func toOrder(lines: [DBOrderLine] = []) -> Order {
        let orderStatus = OrderStatus(rawValue: status) ?? .placed
        let addr = addressSnapshot ?? AddressSnapshotJSON()
        let deliveryAddr = DeliveryAddress(
            street: addr.street ?? "",
            city: addr.city ?? "",
            state: addr.state ?? "",
            zip: addr.zip ?? "",
            notes: addr.notes ?? ""
        )
        let cartItems: [CartItem] = lines.map { line in
            let mi = MenuItem(
                id: line.itemId ?? line.id,
                name: line.nameSnapshot,
                description: "",
                price: line.unitPrice ?? 0,
                imageURL: line.imageUrlSnapshot ?? "",
                category: .bowls
            )
            return CartItem(
                id: line.id,
                menuItem: mi,
                quantity: line.qty ?? 1,
                specialInstructions: line.notes ?? ""
            )
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let created = formatter.date(from: createdAt ?? "") ?? Date()
        return Order(
            id: id,
            customerId: userId,
            customerName: customerName ?? "",
            items: cartItems,
            status: orderStatus,
            subtotal: subtotal ?? 0,
            tax: tax ?? 0,
            deliveryFee: deliveryFee ?? 0,
            tip: tip ?? 0,
            deliveryAddress: deliveryAddr,
            deliveryNotes: notes ?? "",
            promoCode: promoCode,
            promoDiscount: discount ?? 0,
            driverId: assignedDriverId,
            driverName: driverName,
            createdAt: created
        )
    }
}

nonisolated struct AddressSnapshotJSON: Codable, Sendable {
    let street: String?
    let city: String?
    let state: String?
    let zip: String?
    let notes: String?

    init(street: String? = nil, city: String? = nil, state: String? = nil, zip: String? = nil, notes: String? = nil) {
        self.street = street
        self.city = city
        self.state = state
        self.zip = zip
        self.notes = notes
    }
}

nonisolated struct DBOrderLine: Codable, Sendable, Identifiable {
    let id: String
    let orderId: String
    let itemId: String?
    let nameSnapshot: String
    let imageUrlSnapshot: String?
    let qty: Int?
    let unitPrice: Double?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id, notes, qty
        case orderId = "order_id"
        case itemId = "item_id"
        case nameSnapshot = "name_snapshot"
        case imageUrlSnapshot = "image_url_snapshot"
        case unitPrice = "unit_price"
    }
}

nonisolated struct DBOrderStatusEvent: Codable, Sendable, Identifiable {
    let id: String
    let orderId: String
    let status: String
    let note: String?
    let changedBy: String?
    let changedByRole: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, status, note
        case orderId = "order_id"
        case changedBy = "changed_by"
        case changedByRole = "changed_by_role"
        case createdAt = "created_at"
    }

    func toTimelineEvent() -> OrderTimelineEvent {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let ts = formatter.date(from: createdAt ?? "") ?? Date()
        return OrderTimelineEvent(
            id: id,
            status: OrderStatus(rawValue: status) ?? .placed,
            timestamp: ts,
            note: note
        )
    }
}

nonisolated struct DBDriverStatus: Codable, Sendable {
    let driverId: String
    let isOnline: Bool?
    let currentOrderId: String?
    let lastSeen: String?

    enum CodingKeys: String, CodingKey {
        case driverId = "driver_id"
        case isOnline = "is_online"
        case currentOrderId = "current_order_id"
        case lastSeen = "last_seen"
    }
}

nonisolated struct DBAddress: Codable, Sendable, Identifiable {
    let id: String
    let userId: String?
    let label: String?
    let addressText: String?
    let street: String?
    let city: String?
    let state: String?
    let zip: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id, label, street, city, state, zip, notes
        case userId = "user_id"
        case addressText = "address_text"
    }
}

nonisolated struct CreateOrderItemJSON: Codable, Sendable {
    let itemId: String
    let name: String
    let imageUrl: String
    let qty: Int
    let notes: String
    let modifiers: [CreateOrderModifierJSON]?

    enum CodingKeys: String, CodingKey {
        case name, qty, notes, modifiers
        case itemId = "item_id"
        case imageUrl = "image_url"
    }
}

nonisolated struct CreateOrderModifierJSON: Codable, Sendable {
    let name: String
    let priceDelta: Double

    enum CodingKeys: String, CodingKey {
        case name
        case priceDelta = "price_delta"
    }
}
