import SwiftUI

struct CustomerOrdersView: View {
    @Environment(DataStore.self) private var store
    @Environment(AuthViewModel.self) private var authVM
    @State private var selectedOrder: Order?

    private var myOrders: [Order] {
        guard let user = authVM.currentUser else { return [] }
        return store.ordersForCustomer(user.id)
    }

    var body: some View {
        NavigationStack {
            Group {
                if myOrders.isEmpty {
                    ContentUnavailableView("No Orders Yet", systemImage: "bag", description: Text("Your order history will appear here"))
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(myOrders) { order in
                                OrderCard(order: order) {
                                    selectedOrder = order
                                }
                            }
                        }
                        .padding(Theme.spacingMD)
                    }
                }
            }
            .background(Theme.background)
            .navigationTitle("My Orders")
            .refreshable {
                if let user = authVM.currentUser {
                    await store.refreshOrders(userId: user.id, role: user.role)
                }
            }
            .sheet(item: $selectedOrder) { order in
                OrderTrackingView(order: order)
            }
        }
    }
}

struct OrderCard: View {
    let order: Order
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Order #\(order.id.prefix(6))")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(order.createdAt, style: .relative)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    StatusBadge(status: order.status)
                }

                Divider()

                ForEach(order.items.prefix(3)) { item in
                    HStack(spacing: 8) {
                        Text("\(item.quantity)x")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.accent)
                        Text(item.menuItem.name)
                            .font(.caption)
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)
                    }
                }

                if order.items.count > 3 {
                    Text("+\(order.items.count - 3) more items")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }

                HStack {
                    Text(order.total, format: .currency(code: "USD"))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    if order.status.isActive {
                        Text("Track Order")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.accent)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
            .padding(16)
            .background(Theme.cardBackground)
            .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct StatusBadge: View {
    let status: OrderStatus

    private var color: Color {
        switch status {
        case .placed, .accepted: Theme.accent
        case .preparing: Color(hex: "007AFF")
        case .ready: Theme.success
        case .outForDelivery: Color(hex: "5856D6")
        case .delivered: Theme.success
        case .canceled: Theme.danger
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption2)
            Text(status.displayName)
                .font(.caption2.weight(.bold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.12))
        .clipShape(.capsule)
    }
}
