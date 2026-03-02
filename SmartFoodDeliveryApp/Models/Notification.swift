import Foundation

nonisolated struct AppNotification: Codable, Sendable, Identifiable, Equatable {
    let id: String
    var title: String
    var body: String
    var type: NotificationType
    var isRead: Bool
    var createdAt: Date
    var orderId: String?

    init(id: String = UUID().uuidString, title: String, body: String, type: NotificationType, isRead: Bool = false, createdAt: Date = Date(), orderId: String? = nil) {
        self.id = id
        self.title = title
        self.body = body
        self.type = type
        self.isRead = isRead
        self.createdAt = createdAt
        self.orderId = orderId
    }
}

nonisolated enum NotificationType: String, Codable, Sendable {
    case orderUpdate
    case promotion
    case reminder
    case system
}
