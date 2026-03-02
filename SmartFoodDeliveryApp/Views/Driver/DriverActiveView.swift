import SwiftUI

struct DriverActiveView: View {
    @Environment(DataStore.self) private var store
    @Environment(AuthViewModel.self) private var authVM

    private var myActiveOrders: [Order] {
        guard let user = authVM.currentUser else { return [] }
        return store.orders.filter { $0.driverId == user.id && $0.status == .outForDelivery }
    }

    var body: some View {
        NavigationStack {
            Group {
                if myActiveOrders.isEmpty {
                    ContentUnavailableView("No Active Deliveries", systemImage: "car", description: Text("Accept an order to start delivering"))
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(myActiveOrders) { order in
                                ActiveDeliveryCard(order: order)
                            }
                        }
                        .padding(Theme.spacingMD)
                    }
                }
            }
            .background(Theme.background)
            .navigationTitle("Active Deliveries")
        }
    }
}

struct ActiveDeliveryCard: View {
    let order: Order
    @Environment(DataStore.self) private var store
    @Environment(AuthViewModel.self) private var authVM
    @State private var delivered: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Order #\(order.id.prefix(6))")
                        .font(.headline)
                    Text(order.customerName)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                StatusBadge(status: order.status)
            }

            VStack(alignment: .leading, spacing: 8) {
                Label(order.deliveryAddress.formatted.isEmpty ? "123 Main St, San Francisco" : order.deliveryAddress.formatted, systemImage: "mappin.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textPrimary)

                if !order.deliveryNotes.isEmpty {
                    Label(order.deliveryNotes, systemImage: "note.text")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 12))

            HStack(spacing: 8) {
                ForEach(order.items.prefix(3)) { item in
                    Text("\(item.quantity)x \(item.menuItem.name)")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
            }

            HStack(spacing: 12) {
                Button {
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                        Text("Call")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Theme.accent.opacity(0.12), in: .capsule)
                }
                .buttonStyle(ScaleButtonStyle())

                Button {
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "map.fill")
                        Text("Navigate")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(hex: "007AFF"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(hex: "007AFF").opacity(0.12), in: .capsule)
                }
                .buttonStyle(ScaleButtonStyle())
            }

            AccentButton(delivered ? "Delivered!" : "Mark as Delivered", icon: delivered ? "checkmark.circle.fill" : "checkmark") {
                let userId = authVM.currentUser?.id ?? ""
                store.updateOrderStatus(order.id, to: .delivered, changedBy: userId)
                delivered = true
                if let user = authVM.currentUser {
                    Task {
                        await store.driverService.clearCurrentOrder(driverId: user.id)
                    }
                }
            }
            .sensoryFeedback(.success, trigger: delivered)
        }
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: Theme.cornerRadiusLarge))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}
