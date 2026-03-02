import Foundation
import Supabase

nonisolated final class SupabaseManager: @unchecked Sendable {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        let urlString = AppConfiguration.supabaseURL
        let key = AppConfiguration.supabaseAnonKey

        guard let url = URL(string: urlString) else {
            fatalError("Invalid Supabase URL. Check SUPABASE_URL in your Info.plist.")
        }

        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key
        )
    }
}
