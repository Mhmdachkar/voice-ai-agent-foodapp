import SwiftUI

struct CustomerProfileView: View {
    @Environment(AuthViewModel.self) private var authVM

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileHeader

                    foodMemorySection

                    settingsSection

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
                    LinearGradient(colors: [Theme.accent, Theme.accent.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 80, height: 80)
                .overlay {
                    Text(String(authVM.currentUser?.name.prefix(1) ?? "?"))
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                }

            Text(authVM.currentUser?.name ?? "User")
                .font(.title3.weight(.bold))
            Text(authVM.currentUser?.email ?? "")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.spacingLG)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: Theme.cornerRadiusLarge))
        .padding(.horizontal, Theme.spacingMD)
    }

    private var foodMemorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.fill")
                    .foregroundStyle(Theme.accent)
                Text("Food Memory")
                    .font(.headline)
            }

            VStack(spacing: 10) {
                memoryRow("Spice Level", authVM.currentUser?.foodMemory.spiceLevel.rawValue ?? "Medium")
                memoryRow("Default Drink", authVM.currentUser?.foodMemory.defaultDrink ?? "None set")
                if let disliked = authVM.currentUser?.foodMemory.dislikedIngredients, !disliked.isEmpty {
                    memoryRow("Dislikes", disliked.joined(separator: ", "))
                }
            }
        }
        .padding(Theme.spacingMD)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
        .padding(.horizontal, Theme.spacingMD)
    }

    private var settingsSection: some View {
        VStack(spacing: 2) {
            settingsRow("Delivery Addresses", icon: "mappin.circle.fill")
            settingsRow("Payment Methods", icon: "creditcard.fill")
            settingsRow("Notifications", icon: "bell.fill")
            settingsRow("Help & Support", icon: "questionmark.circle.fill")
            settingsRow("About", icon: "info.circle.fill")
        }
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
        .padding(.horizontal, Theme.spacingMD)
    }

    private func memoryRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private func settingsRow(_ title: String, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Theme.accent)
                .frame(width: 28)
            Text(title)
                .font(.body)
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, Theme.spacingMD)
        .padding(.vertical, 14)
    }
}
