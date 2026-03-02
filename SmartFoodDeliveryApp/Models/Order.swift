import Foundation

nonisolated struct Order: Codable, Sendable, Identifiable, Equatable {
    let id: String
    var customerId: String
    var customerName: String
    var items: [CartItem]
    var status: OrderStatus
    var timeline: [OrderTimelineEvent]
    var subtotal: Double
    var tax: Double
    var deliveryFee: Double
    var tip: Double
    var total: Double
    var deliveryAddress: DeliveryAddress
    var deliveryNotes: String
    var promoCode: String?
    var promoDiscount: Double
    var driverId: String?
    var driverName: String?
    var estimatedDeliveryTime: Date?
    var scheduledFor: Date?
    var createdAt: Date

    init(id: String = UUID().uuidString, customerId: String, customerName: String, items: [CartItem], status: OrderStatus = .placed, timeline: [OrderTimelineEvent] = [], subtotal: Double, tax: Double, deliveryFee: Double = 3.99, tip: Double = 0, deliveryAddress: DeliveryAddress, deliveryNotes: String = "", promoCode: String? = nil, promoDiscount: Double = 0, driverId: String? = nil, driverName: String? = nil, estimatedDeliveryTime: Date? = nil, scheduledFor: Date? = nil, createdAt: Date = Date()) {
        self.id = id
        self.customerId = customerId
        self.customerName = customerName
        self.items = items
        self.status = status
        self.subtotal = subtotal
        self.tax = tax
        self.deliveryFee = deliveryFee
        self.tip = tip
        self.total = subtotal + tax + deliveryFee + tip - promoDiscount
        self.deliveryAddress = deliveryAddress
        self.deliveryNotes = deliveryNotes
        self.promoCode = promoCode
        self.promoDiscount = promoDiscount
        self.driverId = driverId
        self.driverName = driverName
        self.estimatedDeliveryTime = estimatedDeliveryTime
        self.scheduledFor = scheduledFor
        self.createdAt = createdAt

        if timeline.isEmpty {
            self.timeline = [OrderTimelineEvent(status: .placed, timestamp: createdAt)]
        } else {
            self.timeline = timeline
        }
    }
}

nonisolated enum OrderStatus: String, Codable, Sendable, CaseIterable {
    case placed = "PLACED"
    case accepted = "ACCEPTED"
    case preparing = "PREPARING"
    case ready = "READY"
    case outForDelivery = "OUT_FOR_DELIVERY"
    case delivered = "DELIVERED"
    case canceled = "CANCELED"

    var displayName: String {
        switch self {
        case .placed: "Order Placed"
        case .accepted: "Accepted"
        case .preparing: "Preparing"
        case .ready: "Ready for Pickup"
        case .outForDelivery: "Out for Delivery"
        case .delivered: "Delivered"
        case .canceled: "Canceled"
        }
    }

    var icon: String {
        switch self {
        case .placed: "checkmark.circle"
        case .accepted: "hand.thumbsup"
        case .preparing: "frying.pan"
        case .ready: "bag.fill"
        case .outForDelivery: "car.fill"
        case .delivered: "house.fill"
        case .canceled: "xmark.circle"
        }
    }

    var sortOrder: Int {
        switch self {
        case .placed: 0
        case .accepted: 1
        case .preparing: 2
        case .ready: 3
        case .outForDelivery: 4
        case .delivered: 5
        case .canceled: 6
        }
    }

    var isActive: Bool {
        switch self {
        case .delivered, .canceled: false
        default: true
        }
    }

    var next: OrderStatus? {
        switch self {
        case .placed: .accepted
        case .accepted: .preparing
        case .preparing: .ready
        case .ready: .outForDelivery
        case .outForDelivery: .delivered
        case .delivered: nil
        case .canceled: nil
        }
    }
}

nonisolated struct OrderTimelineEvent: Codable, Sendable, Identifiable, Equatable {
    let id: String
    let status: OrderStatus
    let timestamp: Date
    var note: String?

    init(id: String = UUID().uuidString, status: OrderStatus, timestamp: Date = Date(), note: String? = nil) {
        self.id = id
        self.status = status
        self.timestamp = timestamp
        self.note = note
    }
}
