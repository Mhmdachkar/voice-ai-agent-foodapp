import Foundation
import Supabase

nonisolated struct DriverStatusUpdate: Encodable, Sendable {
    let is_online: Bool
    let last_seen: String
}

nonisolated struct DriverStatusInsert: Encodable, Sendable {
    let driver_id: String
    let is_online: Bool
}

nonisolated struct DriverCurrentOrderUpdate: Encodable, Sendable {
    let current_order_id: String?
}

@Observable
final class SupabaseDriverService {
    var onlineDrivers: [AppUser] = []
    var driverStatuses: [String: DBDriverStatus] = [:]
    var errorMessage: String?

    private var client: SupabaseClient { SupabaseManager.shared.client }

    func fetchDrivers() async {
        do {
            let profiles: [DBProfile] = try await client.from("profiles")
                .select()
                .eq("role", value: "driver")
                .execute()
                .value

            let statuses: [DBDriverStatus] = try await client.from("driver_status")
                .select()
                .execute()
                .value

            driverStatuses = Dictionary(uniqueKeysWithValues: statuses.map { ($0.driverId, $0) })
            onlineDrivers = profiles
                .filter { p in driverStatuses[p.id]?.isOnline == true }
                .map { $0.toAppUser() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchAllDriverProfiles() async -> [AppUser] {
        do {
            let profiles: [DBProfile] = try await client.from("profiles")
                .select()
                .eq("role", value: "driver")
                .execute()
                .value
            return profiles.map { $0.toAppUser() }
        } catch {
            return []
        }
    }

    func setOnlineStatus(driverId: String, isOnline: Bool) async {
        do {
            let exists = driverStatuses[driverId] != nil
            if exists {
                let update = DriverStatusUpdate(
                    is_online: isOnline,
                    last_seen: ISO8601DateFormatter().string(from: Date())
                )
                try await client.from("driver_status")
                    .update(update)
                    .eq("driver_id", value: driverId)
                    .execute()
            } else {
                let insert = DriverStatusInsert(driver_id: driverId, is_online: isOnline)
                try await client.from("driver_status")
                    .insert(insert)
                    .execute()
            }
            driverStatuses[driverId] = DBDriverStatus(
                driverId: driverId,
                isOnline: isOnline,
                currentOrderId: driverStatuses[driverId]?.currentOrderId,
                lastSeen: ISO8601DateFormatter().string(from: Date())
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearCurrentOrder(driverId: String) async {
        do {
            let update = DriverCurrentOrderUpdate(current_order_id: nil)
            try await client.from("driver_status")
                .update(update)
                .eq("driver_id", value: driverId)
                .execute()
        } catch {}
    }
}
