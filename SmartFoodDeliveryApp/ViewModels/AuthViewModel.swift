import Foundation
import SwiftUI

@Observable
final class AuthViewModel {
    let authService = SupabaseAuthService()

    var currentUser: AppUser?
    var isAuthenticated: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?

    // Login form fields
    var isSignUp: Bool = false
    var loginName: String = ""
    var loginEmail: String = ""
    var loginPassword: String = ""
    var selectedRole: UserRole = .customer

    // MARK: - Initialize (check existing session)

    func initialize() async {
        isLoading = true
        await authService.initialize()
        if authService.isAuthenticated, let profile = authService.profile {
            currentUser = profile.toAppUser()
            isAuthenticated = true
        }
        isLoading = false
    }

    // MARK: - Supabase Login / Sign-Up

    func login() {
        let email = loginEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = loginPassword
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password."
            return
        }

        isLoading = true
        errorMessage = nil

        Task { @MainActor in
            if isSignUp {
                let name = loginName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else {
                    errorMessage = "Please enter your name."
                    isLoading = false
                    return
                }
                await authService.signUp(
                    email: email,
                    password: password,
                    fullName: name,
                    role: selectedRole.rawValue
                )
            } else {
                await authService.signIn(email: email, password: password)
            }

            if let serviceError = authService.errorMessage {
                errorMessage = serviceError
            } else if authService.isAuthenticated, let profile = authService.profile {
                currentUser = profile.toAppUser()
                isAuthenticated = true
                clearForm()
            }
            isLoading = false
        }
    }

    // MARK: - Quick Login (offline / demo mode)

    func quickLogin(role: UserRole) {
        let user: AppUser
        switch role {
        case .customer:
            user = AppUser(
                id: "demo_customer",
                name: "Demo Customer",
                email: "customer@demo.com",
                phone: "",
                role: .customer
            )
        case .admin:
            user = AppUser(
                id: "demo_admin",
                name: "Demo Admin",
                email: "admin@demo.com",
                phone: "",
                role: .admin
            )
        case .driver:
            user = AppUser(
                id: "demo_driver",
                name: "Demo Driver",
                email: "driver@demo.com",
                phone: "",
                role: .driver
            )
        }
        currentUser = user
        isAuthenticated = true
        errorMessage = nil
    }

    // MARK: - Logout

    func logout() {
        Task { @MainActor in
            await authService.signOut()
            currentUser = nil
            isAuthenticated = false
            clearForm()
        }
    }

    // MARK: - Helpers

    private func clearForm() {
        loginName = ""
        loginEmail = ""
        loginPassword = ""
        isSignUp = false
        selectedRole = .customer
        errorMessage = nil
    }
}
