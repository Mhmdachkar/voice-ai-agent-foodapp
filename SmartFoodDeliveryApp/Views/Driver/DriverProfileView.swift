import SwiftUI

struct DriverProfileView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(DataStore.self) private var store

    private var totalDeliveries: Int {
        guard let user = authVM.currentUser else { return 0 }
        return store.orders.filter { $0.driverId == user.id && $0.status == .delivered }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileHeader

                    performanceSection

                    VStack(spacing: 2) {
                        profileRow("Vehicle Info", icon: "car.fill", value: "Toyota Camry")
                        profileRow("License", icon: "doc.text.fill", value: "Active")
                        profileRow("Insurance", icon: "shield.checkered", value: "Verified")
                        profileRow("Background Check", icon: "checkmark.seal.fill", value: "Passed")
                    }
                    .background(Theme.cardBackground)
                    .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
                    .padding(.horizontal, Theme.spacingMD)

                    VStack(spacing: 2) {
                        profileRow("Help & Support", icon: "questionmark.circle.fill", value: "")
                        profileRow("Terms of Service", icon: "doc.fill", value: "")
                        profileRow("Privacy Policy", icon: "lock.fill", value: "")
                    }
                    .background(Theme.cardBackground)
                    .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
                    .padding(.horizontal, Theme.spacingMD)

                    Button {
                        authVM.logout()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                                .font(.body.weight(.semibold))
                        }
                        .foregroundStyle(Theme.danger)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Theme.danger.opacity(0.1), in: .capsule)
                    }
                    .padding(.horizontal, Theme.spacingMD)
                }
                .padding(.vertical, Theme.spacingMD)
            }
            .background(Theme.background)
            .navigationTitle("Profile")
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(colors: [Theme.accent, Color(hex: "FF6B35")], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: "car.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }

            Text(authVM.currentUser?.name ?? "Driver")
                .font(.title3.weight(.bold))
            Text(authVM.currentUser?.email ?? "")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)

            HStack(spacing: 20) {
                VStack {
                    Text("\(totalDeliveries)")
                        .font(.headline)
                    Text("Deliveries")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Rectangle()
                    .fill(Theme.border)
                    .frame(width: 1, height: 30)
                VStack {
                    Text("4.9")
                        .font(.headline)
                    Text("Rating")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Rectangle()
                    .fill(Theme.border)
                    .frame(width: 1, height: 30)
                VStack {
                    Text("98%")
                        .font(.headline)
                    Text("On Time")
                        .font(.caption)
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

    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance")
                .font(.headline)
                .padding(.horizontal, Theme.spacingMD)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                PerformanceCard(title: "Acceptance Rate", value: "95%", trend: "+2%", color: Theme.success)
                PerformanceCard(title: "Avg Delivery", value: "18 min", trend: "-3 min", color: Theme.accent)
            }
            .padding(.horizontal, Theme.spacingMD)
        }
    }

    private func profileRow(_ title: String, icon: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(Theme.accent)
                .frame(width: 28)
            Text(title)
                .font(.body)
            Spacer()
            if !value.isEmpty {
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, Theme.spacingMD)
        .padding(.vertical, 14)
    }
}

struct PerformanceCard: View {
    let title: String
    let value: String
    let trend: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
            Text(trend)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
    }
}
