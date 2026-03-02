import Foundation
import Supabase

@Observable
final class RealtimeService {
    var lastOrderUpdate: DBOrder?
    var lastStatusEvent: DBOrderStatusEvent?

    private var client: SupabaseClient { SupabaseManager.shared.client }
    private var ordersChannel: RealtimeChannelV2?

    /// Subscribe to order changes via Supabase Realtime postgres_changes.
    func subscribeToOrders(onUpdate: @escaping @Sendable (DBOrder) -> Void) async {
        await unsubscribe()

        let channel = client.realtimeV2.channel("orders_changes")

        channel.onPostgresChange(InsertAction.self, schema: "public", table: "orders") { [weak self] action in
            let record = action.record
            if let data = try? JSONSerialization.data(withJSONObject: record),
               let dbOrder = try? JSONDecoder().decode(DBOrder.self, from: data) {
                self?.lastOrderUpdate = dbOrder
                onUpdate(dbOrder)
            }
        }

        channel.onPostgresChange(UpdateAction.self, schema: "public", table: "orders") { [weak self] action in
            let record = action.record
            if let data = try? JSONSerialization.data(withJSONObject: record),
               let dbOrder = try? JSONDecoder().decode(DBOrder.self, from: data) {
                self?.lastOrderUpdate = dbOrder
                onUpdate(dbOrder)
            }
        }

        await channel.subscribe()
        ordersChannel = channel
    }

    func unsubscribe() async {
        if let channel = ordersChannel {
            await client.realtimeV2.removeChannel(channel)
            ordersChannel = nil
        }
    }
}
