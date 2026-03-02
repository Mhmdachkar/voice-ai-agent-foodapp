import Foundation

nonisolated enum AppEvent: Sendable {
    case orderPlaced(String)
    case orderStatusChanged(String, OrderStatus)
    case driverAssigned(String, String)
    case cartUpdated
    case notificationReceived
}

@Observable
final class EventBus {
    static let shared = EventBus()
    var lastEvent: AppEvent?
    private(set) var eventCount: Int = 0

    private init() {}

    func publish(_ event: AppEvent) {
        lastEvent = event
        eventCount += 1
    }
}
