import Foundation
import AVFoundation

@Observable
final class VoiceAIService {
    private let sttURL = URL(string: "https://toolkit.rork.com/stt/transcribe/")!
    private let chatURL = URL(string: "https://text.pollinations.ai/openai")!
    private let synthesizer = AVSpeechSynthesizer()
    var isSpeaking: Bool = false

    func transcribe(audioFileURL: URL) async throws -> String {
        var request = URLRequest(url: sttURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 10

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let audioData = try Data(contentsOf: audioFileURL)
        let ext = audioFileURL.pathExtension.lowercased()
        let mimeType = ext == "wav" ? "audio/wav" : "audio/m4a"

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"recording.\(ext)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw VoiceAIError.transcriptionFailed
        }

        let result = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
        return result.text
    }

    func classifyIntent(text: String) async throws -> IntentClassification {
        let systemPrompt = """
        Classify the user's intent into exactly one category. Respond ONLY with valid JSON.
        Categories: order_intent, menu_question, recommendation_request, cart_edit, checkout_help, smalltalk, set_preference
        
        Also determine if clarification is needed (ambiguous request, missing size/qty/drink).
        
        JSON format: {"intent":"<category>","needsClarification":false,"clarificationQuestion":null}
        If clarification needed: {"intent":"<category>","needsClarification":true,"clarificationQuestion":"Which size would you like?"}
        """

        let messages = [
            ChatMessage(role: "system", content: systemPrompt),
            ChatMessage(role: "user", content: text)
        ]

        let requestBody = ChatCompletionRequest(
            model: "openai",
            messages: messages,
            temperature: 0.1,
            max_tokens: 150
        )

        var request = URLRequest(url: chatURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = AppConfiguration.voiceAPIKey, !apiKey.isEmpty {
            // Adjust header name/value if Pollinations expects a different auth scheme.
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = 8
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return IntentClassification(intent: "unknown", needsClarification: false, clarificationQuestion: nil)
        }

        let chatResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = chatResponse.choices.first?.message.content else {
            return IntentClassification(intent: "unknown", needsClarification: false, clarificationQuestion: nil)
        }

        let cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let jsonData = cleaned.data(using: .utf8),
           let classification = try? JSONDecoder().decode(IntentClassification.self, from: jsonData) {
            return classification
        }

        return IntentClassification(intent: "unknown", needsClarification: false, clarificationQuestion: nil)
    }

    func chat(messages: [ChatMessage], menuContext: String, foodMemoryContext: String, intent: UserIntent) async throws -> String {
        let temperature: Double = intent == .orderIntent || intent == .cartEdit ? 0.2 : 0.4

        let systemMessage = ChatMessage(
            role: "system",
            content: """
            You are a friendly, concise food ordering assistant. Help customers find and order food.

            RULES:
            - Keep responses under 2 sentences for simple queries. Be concise.
            - If the user's request is ambiguous, ask ONE clarifying question (size, quantity, drink, spice level, pickup/delivery).
            - When suggesting items, always mention name and price.
            - If user says "order that" or "add that", confirm the exact item name and price.
            - Never confirm a final checkout. The user must do that manually.
            - If an item isn't available, suggest the closest alternative.
            - For mood-based requests, suggest 2-3 relevant items.
            - When adding items, say "I'll add [Item Name] ($X.XX) to your cart" clearly.
            - Respect the user's food preferences and dislikes listed below.
            - If budget is mentioned, only suggest items within budget and show remaining.
            - For nutrition requests, prioritize matching items and mention key nutrition facts.

            USER PREFERENCES:
            \(foodMemoryContext)

            AVAILABLE MENU (use ONLY these items):
            \(menuContext)
            """
        )

        var allMessages = [systemMessage] + messages

        let requestBody = ChatCompletionRequest(
            model: "openai",
            messages: allMessages,
            temperature: temperature,
            max_tokens: 400
        )

        var request = URLRequest(url: chatURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = AppConfiguration.voiceAPIKey, !apiKey.isEmpty {
            // Adjust header name/value if Pollinations expects a different auth scheme.
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = 12
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw VoiceAIError.chatFailed
        }

        let result = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = result.choices.first?.message.content else {
            throw VoiceAIError.emptyResponse
        }
        return content
    }

    func speak(_ text: String) {
        stopSpeaking()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.05
        utterance.pitchMultiplier = 1.0
        isSpeaking = true
        synthesizer.speak(utterance)

        Task {
            while synthesizer.isSpeaking {
                try? await Task.sleep(for: .milliseconds(100))
                if Task.isCancelled { break }
            }
            isSpeaking = false
        }
    }

    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }

    func speakFirstSentence(of text: String) {
        let firstSentence: String
        if let range = text.range(of: ".", options: .literal) {
            firstSentence = String(text[text.startIndex...range.lowerBound])
        } else {
            firstSentence = text
        }
        speak(firstSentence)
    }
}

nonisolated enum VoiceAIError: Error, LocalizedError, Sendable {
    case transcriptionFailed
    case chatFailed
    case emptyResponse
    case audioRecordingFailed
    case microphonePermissionDenied
    case timeout
    case cancelled

    var errorDescription: String? {
        switch self {
        case .transcriptionFailed: "Could not process your speech. Please try again."
        case .chatFailed: "Could not reach the assistant. Please try again."
        case .emptyResponse: "No response received. Please try again."
        case .audioRecordingFailed: "Audio recording failed. Check microphone access."
        case .microphonePermissionDenied: "Microphone access is required for voice ordering."
        case .timeout: "Request timed out. Please try again."
        case .cancelled: "Request was cancelled."
        }
    }
}
