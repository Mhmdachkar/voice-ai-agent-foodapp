import SwiftUI

struct DriverAvailableView: View {
    @Environment(DataStore.self) private var store
    @Environment(AuthViewModel.self) private var authVM
    @State private var isOnline: Bool = true
    @State private var acceptedOrderId: String?

    private var availableOrders: [Order] {
        store.orders.filter { $0.status == .ready && $0.driverId == nil }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                onlineToggle

                if !isOnline {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(Theme.textSecondary)
                        Text("You're Offline")
                            .font(.title3.weight(.bold))
                        Text("Go online to see available deliveries")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                    }
                } else if availableOrders.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundStyle(Theme.textSecondary)
                        Text("No Available Orders")
                            .font(.title3.weight(.bold))
                        Text("New orders will appear here when ready")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(availableOrders) { order in
                                DriverOrderCard(order: order) {
                                    acceptOrder(order)
                                }
                            }
                        }
                        .padding(Theme.spacingMD)
                    }
                }
            }
            .background(Theme.background)
            .navigationTitle("Available Deliveries")
            .sensoryFeedback(.success, trigger: acceptedOrderId)
            .refreshable {
                if let user = authVM.currentUser {
                    await store.refreshOrders(userId: user.id, role: user.role)
                }
            }
        }
    }

    private var onlineToggle: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(isOnline ? Theme.success : Theme.textSecondary)
                .frame(width: 12, height: 12)

            Text(isOnline ? "Online" : "Offline")
                .font(.headline)
                .foregroundStyle(isOnline ? Theme.success : Theme.textSecondary)

            Spacer()

            Toggle("", isOn: $isOnline)
                .tint(Theme.success)
                .labelsHidden()
        }
        .padding(16)
        .background(isOnline ? Theme.success.opacity(0.08) : Color(.secondarySystemBackground))
        .padding(.horizontal, Theme.spacingMD)
        .padding(.vertical, 8)
        .onChange(of: isOnline) { _, newValue in
            if let user = authVM.currentUser {
                Task {
                    await store.driverService.setOnlineStatus(driverId: user.id, isOnline: newValue)
                }
            }
        }
    }

    private func acceptOrder(_ order: Order) {
        guard let user = authVM.currentUser else { return }
        if authVM.authService.isAuthenticated {
            store.driverAcceptOrder(order.id, driverId: user.id)
        } else {
            store.assignDriver(order.id, driverId: user.id, driverName: user.name)
        }
        acceptedOrderId = order.id
    }
}

struct DriverOrderCard: View {
    let order: Order
    let onAccept: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Order #\(order.id.prefix(6))")
                        .font(.subheadline.weight(.bold))
                    Text(order.customerName)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Text(order.total, format: .currency(code: "USD"))
                    .font(.headline)
                    .foregroundStyle(Theme.accent)
            }

            HStack(spacing: 8) {
                Label("\(order.items.count) items", systemImage: "bag")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)

                Text("•")
                    .foregroundStyle(Theme.textSecondary)

                Label(order.deliveryAddress.street.isEmpty ? "Nearby" : order.deliveryAddress.street, systemImage: "mappin")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }

            AccentButton("Accept Delivery", icon: "checkmark.circle") {
                onAccept()
            }
        }
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}
