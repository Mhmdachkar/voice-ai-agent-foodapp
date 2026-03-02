import SwiftUI

struct AdminOrdersView: View {
    @Environment(DataStore.self) private var store
    @Environment(AuthViewModel.self) private var authVM
    @State private var filterStatus: OrderStatus?
    @State private var selectedOrder: Order?

    private var filteredOrders: [Order] {
        if let filter = filterStatus {
            return store.orders.filter { $0.status == filter }
        }
        return store.orders
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ChipView("All", isSelected: filterStatus == nil) {
                            withAnimation { filterStatus = nil }
                        }
                        ForEach(OrderStatus.allCases, id: \.rawValue) { status in
                            ChipView(status.displayName, isSelected: filterStatus == status) {
                                withAnimation { filterStatus = status }
                            }
                        }
                    }
                    .padding(.horizontal, Theme.spacingMD)
                    .padding(.vertical, 12)
                }
                .contentMargins(.horizontal, 0)

                if filteredOrders.isEmpty {
                    ContentUnavailableView("No Orders", systemImage: "list.clipboard", description: Text("No orders match this filter"))
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(filteredOrders) { order in
                                Button {
                                    selectedOrder = order
                                } label: {
                                    AdminOrderRow(order: order)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Theme.spacingMD)
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(Theme.background)
            .navigationTitle("Orders")
            .refreshable {
                if let user = authVM.currentUser {
                    await store.refreshOrders(userId: user.id, role: user.role)
                }
            }
            .sheet(item: $selectedOrder) { order in
                AdminOrderDetailSheet(order: order)
            }
        }
    }
}

struct AdminOrderDetailSheet: View {
    let order: Order
    @Environment(DataStore.self) private var store
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss
    @State private var showAssignDriver: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Order #\(order.id.prefix(6))")
                                .font(.title3.weight(.bold))
                            Text(order.createdAt, style: .date)
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        StatusBadge(status: order.status)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Customer")
                            .font(.headline)
                        HStack(spacing: 10) {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Theme.accent)
                            VStack(alignment: .leading) {
                                Text(order.customerName)
                                    .font(.subheadline.weight(.medium))
                                Text(order.deliveryAddress.formatted)
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Items")
                            .font(.headline)
                        ForEach(order.items) { item in
                            HStack {
                                Text("\(item.quantity)x")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(Theme.accent)
                                Text(item.menuItem.name)
                                    .font(.subheadline)
                                Spacer()
                                Text(item.itemTotal, format: .currency(code: "USD"))
                                    .font(.subheadline.weight(.medium))
                            }
                        }
                        Divider()
                        HStack {
                            Text("Total").font(.headline)
                            Spacer()
                            Text(order.total, format: .currency(code: "USD"))
                                .font(.headline)
                                .foregroundStyle(Theme.accent)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Timeline")
                            .font(.headline)
                        ForEach(order.timeline) { event in
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(Theme.accent)
                                    .frame(width: 8, height: 8)
                                Text(event.status.displayName)
                                    .font(.caption.weight(.medium))
                                Spacer()
                                Text(event.timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }

                    if let next = order.status.next {
                        AccentButton("Move to \(next.displayName)", icon: "arrow.right") {
                            let userId = authVM.currentUser?.id ?? ""
                            store.updateOrderStatus(order.id, to: next, changedBy: userId)
                            dismiss()
                        }
                    }

                    if order.status == .ready && order.driverId == nil {
                        Button {
                            showAssignDriver = true
                        } label: {
                            HStack {
                                Image(systemName: "car.fill")
                                Text("Assign Driver")
                                    .font(.body.weight(.semibold))
                            }
                            .foregroundStyle(Theme.accent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Theme.accent.opacity(0.12), in: .capsule)
                        }
                    }
                }
                .padding(Theme.spacingMD)
            }
            .background(Theme.background)
            .navigationTitle("Order Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showAssignDriver) {
                AssignDriverSheet(orderId: order.id)
            }
        }
    }
}

struct AssignDriverSheet: View {
    let orderId: String
    @Environment(DataStore.self) private var store
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(store.drivers) { driver in
                Button {
                    let assignedBy = authVM.currentUser?.id ?? ""
                    store.assignDriver(orderId, driverId: driver.id, driverName: driver.name, assignedBy: assignedBy)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.accent)
                        VStack(alignment: .leading) {
                            Text(driver.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Theme.textPrimary)
                            Text(driver.phone)
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .navigationTitle("Assign Driver")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
    }
}
