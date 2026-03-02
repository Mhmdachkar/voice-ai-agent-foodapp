import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) private var authVM

    var body: some View {
        @Bindable var auth = authVM
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(Theme.accent)
                        .symbolEffect(.bounce, value: true)

                    Text("SmartFood")
                        .font(.system(.largeTitle, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)

                    Text("AI-powered food delivery")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.top, 60)
                .padding(.bottom, 40)

                VStack(spacing: 20) {
                    Text("Quick Start")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(UserRole.allCases) { role in
                        QuickLoginCard(role: role) {
                            authVM.quickLogin(role: role)
                        }
                    }
                }
                .padding(.horizontal, Theme.spacingMD)

                VStack(spacing: 16) {
                    dividerWithText("or sign in with Supabase")

                    Picker("", selection: $auth.isSignUp) {
                        Text("Sign In").tag(false)
                        Text("Sign Up").tag(true)
                    }
                    .pickerStyle(.segmented)

                    VStack(spacing: 12) {
                        if auth.isSignUp {
                            TextField("Your name", text: $auth.loginName)
                                .textFieldStyle(.plain)
                                .textContentType(.name)
                                .padding(16)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(.rect(cornerRadius: Theme.cornerRadiusSmall))
                        }

                        TextField("Email address", text: $auth.loginEmail)
                            .textFieldStyle(.plain)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(16)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(.rect(cornerRadius: Theme.cornerRadiusSmall))

                        SecureField("Password", text: $auth.loginPassword)
                            .textFieldStyle(.plain)
                            .textContentType(auth.isSignUp ? .newPassword : .password)
                            .padding(16)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(.rect(cornerRadius: Theme.cornerRadiusSmall))

                        if auth.isSignUp {
                            Picker("Role", selection: $auth.selectedRole) {
                                ForEach(UserRole.allCases) { role in
                                    Text(role.displayName).tag(role)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    if let error = auth.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Theme.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    AccentButton(auth.isSignUp ? "Create Account" : "Sign In", icon: "arrow.right") {
                        authVM.login()
                    }
                    .disabled(auth.isLoading)
                    .overlay {
                        if auth.isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                }
                .padding(.horizontal, Theme.spacingMD)
                .padding(.top, 32)
            }
            .padding(.bottom, 40)
        }
        .background(Theme.background)
    }

    private func dividerWithText(_ text: String) -> some View {
        HStack {
            Rectangle()
                .fill(Theme.border)
                .frame(height: 1)
            Text(text)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            Rectangle()
                .fill(Theme.border)
                .frame(height: 1)
        }
        .padding(.vertical, 8)
    }
}

struct QuickLoginCard: View {
    let role: UserRole
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: role.icon)
                    .font(.title2)
                    .foregroundStyle(Theme.accent)
                    .frame(width: 48, height: 48)
                    .background(Theme.accent.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(role.displayName)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text(roleDescription(role))
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(16)
            .background(Theme.cardBackground)
            .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func roleDescription(_ role: UserRole) -> String {
        switch role {
        case .customer: "Browse menu, order food, track delivery"
        case .admin: "Manage orders, menu, drivers, reports"
        case .driver: "Accept deliveries, track earnings"
        }
    }
}
