import SwiftUI

struct DriverEarningsView: View {
    @Environment(DataStore.self) private var store
    @Environment(AuthViewModel.self) private var authVM

    private var myDeliveredOrders: [Order] {
        guard let user = authVM.currentUser else { return [] }
        return store.orders.filter { $0.driverId == user.id && $0.status == .delivered }
    }

    private var todayEarnings: Double {
        let calendar = Calendar.current
        return myDeliveredOrders
            .filter { calendar.isDateInToday($0.createdAt) }
            .reduce(0) { $0 + $1.tip + 5.0 }
    }

    private var totalEarnings: Double {
        myDeliveredOrders.reduce(0) { $0 + $1.tip + 5.0 }
    }

    private var acceptanceRate: Int {
        let total = store.orders.filter { $0.driverId == authVM.currentUser?.id }.count
        guard total > 0 else { return 100 }
        return Int((Double(myDeliveredOrders.count) / Double(total)) * 100)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    earningsHeader

                    statsGrid

                    recentDeliveries
                }
                .padding(.vertical, Theme.spacingMD)
            }
            .background(Theme.background)
            .navigationTitle("Earnings")
        }
    }

    private var earningsHeader: some View {
        VStack(spacing: 8) {
            Text("Today's Earnings")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Text(todayEarnings, format: .currency(code: "USD"))
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(Theme.accent)
            Text("\(myDeliveredOrders.filter { Calendar.current.isDateInToday($0.createdAt) }.count) deliveries today")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.spacingLG)
        .background(
            LinearGradient(
                colors: [Theme.accent.opacity(0.08), Theme.accent.opacity(0.02)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(.rect(cornerRadius: Theme.cornerRadiusLarge))
        .padding(.horizontal, Theme.spacingMD)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "Total", value: totalEarnings.formatted(.currency(code: "USD")), icon: "dollarsign.circle.fill")
            StatCard(title: "Deliveries", value: "\(myDeliveredOrders.count)", icon: "bag.fill")
            StatCard(title: "Rating", value: "\(acceptanceRate)%", icon: "star.fill")
        }
        .padding(.horizontal, Theme.spacingMD)
    }

    private var recentDeliveries: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Deliveries")
                .font(.headline)
                .padding(.horizontal, Theme.spacingMD)

            if myDeliveredOrders.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title)
                        .foregroundStyle(Theme.textSecondary)
                    Text("No deliveries yet")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.spacingLG)
            } else {
                ForEach(myDeliveredOrders.prefix(10)) { order in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Theme.success)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("#\(order.id.prefix(6))")
                                .font(.subheadline.weight(.semibold))
                            Text(order.customerName)
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text((order.tip + 5.0), format: .currency(code: "USD"))
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Theme.success)
                            Text(order.createdAt, style: .time)
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .padding(14)
                    .background(Theme.cardBackground)
                    .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
                    .padding(.horizontal, Theme.spacingMD)
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.accent)
            Text(value)
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
    }
}
