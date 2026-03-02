import SwiftUI

struct AdminDispatchView: View {
    @Environment(DataStore.self) private var store

    private var unassignedOrders: [Order] {
        store.orders.filter { $0.status == .ready && $0.driverId == nil }
    }

    private var inTransitOrders: [Order] {
        store.orders.filter { $0.status == .outForDelivery }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    driversOnline

                    if !unassignedOrders.isEmpty {
                        unassignedSection
                    }

                    if !inTransitOrders.isEmpty {
                        inTransitSection
                    }

                    if unassignedOrders.isEmpty && inTransitOrders.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(Theme.success)
                            Text("All Caught Up!")
                                .font(.headline)
                            Text("No pending dispatches")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(Theme.spacingXL)
                    }
                }
                .padding(.vertical, Theme.spacingMD)
            }
            .background(Theme.background)
            .navigationTitle("Dispatch")
        }
    }

    private var driversOnline: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Drivers Online")
                .padding(.horizontal, Theme.spacingMD)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.drivers) { driver in
                        VStack(spacing: 8) {
                            Circle()
                                .fill(Theme.accent.opacity(0.15))
                                .frame(width: 48, height: 48)
                                .overlay {
                                    Text(String(driver.name.prefix(1)))
                                        .font(.headline)
                                        .foregroundStyle(Theme.accent)
                                }
                                .overlay(alignment: .bottomTrailing) {
                                    Circle()
                                        .fill(Theme.success)
                                        .frame(width: 12, height: 12)
                                        .overlay(Circle().stroke(.white, lineWidth: 2))
                                }

                            Text(driver.name.components(separatedBy: " ").first ?? "")
                                .font(.caption)
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }
                }
                .padding(.horizontal, Theme.spacingMD)
            }
            .contentMargins(.horizontal, 0)
        }
    }

    private var unassignedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Theme.warning)
                    .frame(width: 8, height: 8)
                Text("Needs Driver (\(unassignedOrders.count))")
                    .font(.headline)
            }
            .padding(.horizontal, Theme.spacingMD)

            ForEach(unassignedOrders) { order in
                AdminOrderRow(order: order)
                    .padding(.horizontal, Theme.spacingMD)
            }
        }
    }

    private var inTransitSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: "5856D6"))
                    .frame(width: 8, height: 8)
                Text("In Transit (\(inTransitOrders.count))")
                    .font(.headline)
            }
            .padding(.horizontal, Theme.spacingMD)

            ForEach(inTransitOrders) { order in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("#\(order.id.prefix(6))")
                            .font(.subheadline.weight(.bold))
                        Text(order.driverName ?? "Unknown")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Text(order.customerName)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    StatusBadge(status: order.status)
                }
                .padding(14)
                .background(Theme.cardBackground)
                .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
                .padding(.horizontal, Theme.spacingMD)
            }
        }
    }
}
