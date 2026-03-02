import Foundation
import Supabase

nonisolated struct CreateOrderParams: Encodable, Sendable {
    let p_user_id: String
    let p_customer_name: String
    let p_items: String
    let p_address_snapshot: String
    let p_notes: String
    let p_promo_code: String?
    let p_tip: Double
    let p_payment_method: String
    let p_delivery_method: String
}

nonisolated struct UpdateStatusParams: Encodable, Sendable {
    let p_order_id: String
    let p_new_status: String
    let p_changed_by: String
    let p_note: String?
}

nonisolated struct AssignDriverParams: Encodable, Sendable {
    let p_order_id: String
    let p_driver_id: String
    let p_assigned_by: String
}

nonisolated struct DriverAcceptParams: Encodable, Sendable {
    let p_order_id: String
    let p_driver_id: String
}

@Observable
final class SupabaseOrderService {
    var isLoading: Bool = false
    var errorMessage: String?

    private var client: SupabaseClient { SupabaseManager.shared.client }

    func createOrder(
        userId: String,
        customerName: String,
        items: [CartItem],
        address: DeliveryAddress,
        notes: String,
        promoCode: String?,
        tip: Double,
        paymentMethod: String,
        deliveryMethod: String = "delivery"
    ) async -> String? {
        isLoading = true
        errorMessage = nil
        do {
            let orderItems = items.map { cartItem in
                CreateOrderItemJSON(
                    itemId: cartItem.menuItem.id,
                    name: cartItem.menuItem.name,
                    imageUrl: cartItem.menuItem.imageURL,
                    qty: cartItem.quantity,
                    notes: cartItem.specialInstructions,
                    modifiers: nil
                )
            }

            let itemsData = try JSONEncoder().encode(orderItems)
            let itemsString = String(data: itemsData, encoding: .utf8) ?? "[]"

            let addressSnapshot = AddressSnapshotJSON(
                street: address.street,
                city: address.city,
                state: address.state,
                zip: address.zip,
                notes: address.notes
            )
            let addrData = try JSONEncoder().encode(addressSnapshot)
            let addrString = String(data: addrData, encoding: .utf8) ?? "{}"

            let params = CreateOrderParams(
                p_user_id: userId,
                p_customer_name: customerName,
                p_items: itemsString,
                p_address_snapshot: addrString,
                p_notes: notes,
                p_promo_code: promoCode,
                p_tip: tip,
                p_payment_method: paymentMethod,
                p_delivery_method: deliveryMethod
            )

            let result: String = try await client.rpc("create_order", params: params).execute().value
            isLoading = false
            return result
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return nil
        }
    }

    func fetchOrders(userId: String, role: UserRole) async -> [Order] {
        do {
            let dbOrders: [DBOrder]
            switch role {
            case .customer:
                dbOrders = try await client.from("orders")
                    .select()
                    .eq("user_id", value: userId)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
            case .admin:
                dbOrders = try await client.from("orders")
                    .select()
                    .order("created_at", ascending: false)
                    .execute()
                    .value
            case .driver:
                dbOrders = try await client.from("orders")
                    .select()
                    .order("created_at", ascending: false)
                    .execute()
                    .value
            }

            var orders: [Order] = []
            for dbOrder in dbOrders {
                let lines: [DBOrderLine] = try await client.from("order_lines")
                    .select()
                    .eq("order_id", value: dbOrder.id)
                    .execute()
                    .value

                let events: [DBOrderStatusEvent] = try await client.from("order_status_events")
                    .select()
                    .eq("order_id", value: dbOrder.id)
                    .order("created_at")
                    .execute()
                    .value

                var order = dbOrder.toOrder(lines: lines)
                order.timeline = events.map { $0.toTimelineEvent() }
                orders.append(order)
            }
            return orders
        } catch {
            errorMessage = error.localizedDescription
            return []
        }
    }

    func updateStatus(orderId: String, newStatus: OrderStatus, changedBy: String, note: String? = nil) async -> Bool {
        do {
            let params = UpdateStatusParams(
                p_order_id: orderId,
                p_new_status: newStatus.rawValue,
                p_changed_by: changedBy,
                p_note: note
            )
            try await client.rpc("update_order_status", params: params).execute()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func assignDriver(orderId: String, driverId: String, assignedBy: String) async -> Bool {
        do {
            let params = AssignDriverParams(
                p_order_id: orderId,
                p_driver_id: driverId,
                p_assigned_by: assignedBy
            )
            try await client.rpc("assign_driver", params: params).execute()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func driverAcceptOrder(orderId: String, driverId: String) async -> Bool {
        do {
            let params = DriverAcceptParams(
                p_order_id: orderId,
                p_driver_id: driverId
            )
            try await client.rpc("driver_accept_order", params: params).execute()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
