import SwiftUI

struct OrderTrackingView: View {
    let order: Order
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    statusHeader

                    timelineSection

                    orderDetails

                    if order.status == .delivered {
                        AccentButton("Reorder", icon: "arrow.counterclockwise") {}
                            .padding(.horizontal, Theme.spacingMD)
                    }

                    if order.status.isActive {
                        Button {
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.bubble")
                                Text("Report an Issue")
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.danger)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Theme.danger.opacity(0.1), in: .capsule)
                        }
                        .padding(.horizontal, Theme.spacingMD)
                    }
                }
                .padding(.vertical, Theme.spacingMD)
            }
            .background(Theme.background)
            .navigationTitle("Order #\(order.id.prefix(6))")
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

    private var statusHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: order.status.icon)
                .font(.system(size: 48))
                .foregroundStyle(Theme.accent)
                .symbolEffect(.bounce, value: order.status)

            Text(order.status.displayName)
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.textPrimary)

            if order.status == .outForDelivery {
                if let driver = order.driverName {
                    Text("\(driver) is on the way!")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.spacingLG)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: Theme.cornerRadiusLarge))
        .padding(.horizontal, Theme.spacingMD)
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(order.timeline.enumerated()), id: \.element.id) { index, event in
                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(index == order.timeline.count - 1 ? Theme.accent : Theme.success)
                            .frame(width: 12, height: 12)
                        if index < order.timeline.count - 1 {
                            Rectangle()
                                .fill(Theme.success.opacity(0.3))
                                .frame(width: 2, height: 40)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.status.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(event.timestamp, style: .time)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                        if let note = event.note {
                            Text(note)
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }

                    Spacer()
                }
            }
        }
        .padding(Theme.spacingMD)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
        .padding(.horizontal, Theme.spacingMD)
    }

    private var orderDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Order Details")
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
                Text("Total")
                    .font(.headline)
                Spacer()
                Text(order.total, format: .currency(code: "USD"))
                    .font(.headline)
                    .foregroundStyle(Theme.accent)
            }
        }
        .padding(Theme.spacingMD)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
        .padding(.horizontal, Theme.spacingMD)
    }
}
