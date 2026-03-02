import SwiftUI

struct AdminDashboardView: View {
    @Environment(DataStore.self) private var store
    @Environment(AuthViewModel.self) private var authVM
    @State private var isBusyMode: Bool = false

    private var todayOrders: [Order] {
        let calendar = Calendar.current
        return store.orders.filter { calendar.isDateInToday($0.createdAt) }
    }

    private var todayRevenue: Double {
        todayOrders.reduce(0) { $0 + $1.total }
    }

    private var activeOrderCount: Int {
        store.orders.filter { $0.status.isActive }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    busyModeToggle
                    kpiCards
                    liveOrdersFeed
                    quickStats
                }
                .padding(.vertical, Theme.spacingMD)
            }
            .background(Theme.background)
            .navigationTitle("Dashboard")
            .refreshable {
                if let user = authVM.currentUser {
                    await store.refreshOrders(userId: user.id, role: user.role)
                }
            }
        }
    }

    private var busyModeToggle: some View {
        HStack(spacing: 14) {
            Image(systemName: isBusyMode ? "flame.fill" : "flame")
                .font(.title2)
                .foregroundStyle(isBusyMode ? Theme.danger : Theme.textSecondary)
                .symbolEffect(.bounce, value: isBusyMode)

            VStack(alignment: .leading, spacing: 2) {
                Text("Busy Mode")
                    .font(.headline)
                Text(isBusyMode ? "Increased prep times shown" : "Normal operations")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            Toggle("", isOn: $isBusyMode)
                .tint(Theme.danger)
                .labelsHidden()
        }
        .padding(16)
        .background(isBusyMode ? Theme.danger.opacity(0.08) : Theme.cardBackground)
        .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .stroke(isBusyMode ? Theme.danger.opacity(0.3) : Theme.border, lineWidth: 1)
        )
        .padding(.horizontal, Theme.spacingMD)
    }

    private var kpiCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            KPICard(title: "Today's Revenue", value: todayRevenue.formatted(.currency(code: "USD")), icon: "dollarsign.circle.fill", color: Theme.success)
            KPICard(title: "Orders Today", value: "\(todayOrders.count)", icon: "bag.fill", color: Theme.accent)
            KPICard(title: "Active Orders", value: "\(activeOrderCount)", icon: "clock.fill", color: Color(hex: "007AFF"))
            KPICard(title: "Drivers Online", value: "\(store.drivers.count)", icon: "car.fill", color: Color(hex: "5856D6"))
        }
        .padding(.horizontal, Theme.spacingMD)
    }

    private var liveOrdersFeed: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Live Orders", action: "View All")
                .padding(.horizontal, Theme.spacingMD)

            if store.activeOrders().isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title)
                        .foregroundStyle(Theme.textSecondary)
                    Text("No active orders")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.spacingLG)
            } else {
                ForEach(store.activeOrders().prefix(5)) { order in
                    AdminOrderRow(order: order)
                        .padding(.horizontal, Theme.spacingMD)
                }
            }
        }
    }

    private var quickStats: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Quick Stats")
                .padding(.horizontal, Theme.spacingMD)

            VStack(spacing: 10) {
                statRow("Avg Order Value", todayOrders.isEmpty ? "$0" : (todayRevenue / Double(todayOrders.count)).formatted(.currency(code: "USD")))
                statRow("Menu Items", "\(store.menuItems.count)")
                statRow("Available Items", "\(store.menuItems.filter { $0.isAvailable }.count)")
                statRow("Total Orders", "\(store.orders.count)")
            }
            .padding(Theme.spacingMD)
            .background(Theme.cardBackground)
            .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
            .padding(.horizontal, Theme.spacingMD)
        }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
        }
    }
}

struct KPICard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.textPrimary)

            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

struct AdminOrderRow: View {
    let order: Order
    @Environment(DataStore.self) private var store
    @Environment(AuthViewModel.self) private var authVM

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("#\(order.id.prefix(6))")
                        .font(.subheadline.weight(.bold))
                    Text(order.customerName)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                StatusBadge(status: order.status)
            }

            HStack {
                Text("\(order.items.count) items")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                Text("•")
                    .foregroundStyle(Theme.textSecondary)
                Text(order.total, format: .currency(code: "USD"))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.accent)

                Spacer()

                if let next = order.status.next {
                    Button {
                        let userId = authVM.currentUser?.id ?? ""
                        store.updateOrderStatus(order.id, to: next, changedBy: userId)
                    } label: {
                        Text(next.displayName)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.accent, in: .capsule)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .padding(14)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
    }
}
