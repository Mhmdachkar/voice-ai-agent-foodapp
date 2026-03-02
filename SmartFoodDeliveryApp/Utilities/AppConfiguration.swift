import Foundation

nonisolated enum AppConfiguration {
    /// Supabase project URL, read from Info.plist key `SUPABASE_URL`.
    /// Falls back to a placeholder string if not set so the app still builds.
    static let supabaseURL: String = {
        (Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        ?? "https://YOUR-SUPABASE-PROJECT.supabase.co"
    }()

    /// Supabase anon public key, read from Info.plist key `SUPABASE_ANON_KEY`.
    /// Falls back to a placeholder so you can still run without wiring config yet.
    static let supabaseAnonKey: String = {
        (Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        ?? "YOUR_SUPABASE_ANON_KEY"
    }()

    /// Optional Voice/LLM API key, read from Info.plist key `VOICE_API_KEY`.
    static let voiceAPIKey: String? = {
        (Bundle.main.object(forInfoDictionaryKey: "VOICE_API_KEY") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }()
}
