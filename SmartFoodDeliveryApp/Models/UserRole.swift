import Foundation

nonisolated enum UserRole: String, Codable, Sendable, CaseIterable, Identifiable {
    case customer
    case admin
    case driver

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .customer: "Customer"
        case .admin: "Admin"
        case .driver: "Driver"
        }
    }

    var icon: String {
        switch self {
        case .customer: "person.fill"
        case .admin: "shield.fill"
        case .driver: "car.fill"
        }
    }
}
