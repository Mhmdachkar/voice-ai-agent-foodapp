import Foundation
import Supabase

@Observable
final class SupabaseAuthService {
    var profile: DBProfile?
    var isLoading: Bool = false
    var errorMessage: String?
    private var hasSession: Bool = false

    private var client: SupabaseClient { SupabaseManager.shared.client }

    func initialize() async {
        do {
            let session = try await client.auth.session
            hasSession = true
            await fetchProfile(userId: session.user.id.uuidString)
        } catch {
            hasSession = false
        }
    }

    func signUp(email: String, password: String, fullName: String, role: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password,
                data: ["full_name": .string(fullName), "role": .string(role)]
            )
            hasSession = response.session != nil
            await fetchProfile(userId: response.user.id.uuidString)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            hasSession = true
            await fetchProfile(userId: session.user.id.uuidString)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() async {
        do {
            try await client.auth.signOut()
        } catch {}
        hasSession = false
        profile = nil
    }

    func fetchProfile(userId: String) async {
        do {
            let result: DBProfile = try await client.from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            profile = result
        } catch {
            errorMessage = "Failed to load profile"
        }
    }

    var currentUserId: String? {
        profile?.id
    }

    var isAuthenticated: Bool {
        hasSession && profile != nil
    }
}
