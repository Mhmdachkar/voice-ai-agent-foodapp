import SwiftUI

struct AdminSettingsView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(DataStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileCard

                    reportsSection

                    VStack(spacing: 2) {
                        settingsRow("Store Hours", icon: "clock.fill", value: "9AM - 11PM")
                        settingsRow("Delivery Radius", icon: "location.circle.fill", value: "5 miles")
                        settingsRow("Min Order", icon: "dollarsign.circle.fill", value: "$10.00")
                        settingsRow("Tax Rate", icon: "percent", value: "8.75%")
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
            .navigationTitle("Settings")
        }
    }

    private var profileCard: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Theme.accent)
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "shield.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(authVM.currentUser?.name ?? "Admin")
                    .font(.headline)
                Text("Store Administrator")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
        .padding(.horizontal, Theme.spacingMD)
    }

    private var reportsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reports")
                .font(.headline)
                .padding(.horizontal, Theme.spacingMD)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ReportCard(title: "Sales Report", icon: "chart.bar.fill", color: Theme.success)
                ReportCard(title: "Peak Hours", icon: "clock.fill", color: Theme.accent)
                ReportCard(title: "Driver Stats", icon: "car.fill", color: Color(hex: "5856D6"))
                ReportCard(title: "Menu Analytics", icon: "chart.pie.fill", color: Color(hex: "007AFF"))
            }
            .padding(.horizontal, Theme.spacingMD)
        }
    }

    private func settingsRow(_ title: String, icon: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(Theme.accent)
                .frame(width: 28)
            Text(title)
                .font(.body)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, Theme.spacingMD)
        .padding(.vertical, 14)
    }
}

struct ReportCard: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}
