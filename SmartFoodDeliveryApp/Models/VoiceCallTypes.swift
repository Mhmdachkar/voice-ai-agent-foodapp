import Foundation

nonisolated enum VoiceCallState: String, Sendable, Equatable {
    case idle
    case listening
    case uploading
    case transcribing
    case confirmingTranscript
    case thinking
    case proposingActions
    case speaking
    case error

    var label: String {
        switch self {
        case .idle: return "Tap to talk"
        case .listening: return "Listening..."
        case .uploading: return "Processing..."
        case .transcribing: return "Transcribing..."
        case .confirmingTranscript: return "Confirm transcript"
        case .thinking: return "Thinking..."
        case .proposingActions: return "Review actions"
        case .speaking: return "Speaking..."
        case .error: return "Error occurred"
        }
    }

    var icon: String {
        switch self {
        case .idle: return "mic.fill"
        case .listening: return "waveform"
        case .uploading, .transcribing: return "text.bubble"
        case .confirmingTranscript: return "pencil.line"
        case .thinking: return "brain.head.profile.fill"
        case .proposingActions: return "sparkles"
        case .speaking: return "speaker.wave.2.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    var isProcessing: Bool {
        return self == .uploading || self == .transcribing || self == .thinking
    }
}

nonisolated enum MicMode: String, Sendable {
    case pushToTalk
    case handsFree
}

nonisolated enum UserIntent: String, Codable, Sendable {
    case orderIntent = "order_intent"
    case menuQuestion = "menu_question"
    case recommendationRequest = "recommendation_request"
    case cartEdit = "cart_edit"
    case checkoutHelp = "checkout_help"
    case smalltalk = "smalltalk"
    case setPreference = "set_preference"
    case unknown = "unknown"
}

nonisolated struct IntentClassification: Codable, Sendable {
    let intent: String
    let needsClarification: Bool
    let clarificationQuestion: String?
}

nonisolated struct ConversationMessage: Identifiable, Sendable {
    let id: String
    let role: MessageRole
    let text: String
    let timestamp: Date
    var proposedActions: [ProposedAction]
    var isDecisionCard: Bool

    init(id: String = UUID().uuidString, role: MessageRole, text: String, timestamp: Date = Date(), proposedActions: [ProposedAction] = [], isDecisionCard: Bool = false) {
        self.id = id
        self.role = role
        self.text = text
        self.timestamp = timestamp
        self.proposedActions = proposedActions
        self.isDecisionCard = isDecisionCard
    }
}

nonisolated enum MessageRole: String, Sendable {
    case user
    case assistant
    case system
}

nonisolated struct ProposedAction: Identifiable, Sendable {
    let id: String
    let type: ActionType
    let itemName: String
    let itemId: String?
    let quantity: Int
    let price: Double?
    let modifiers: [String]
    let assumptions: [String]
    var isConfirmed: Bool

    init(id: String = UUID().uuidString, type: ActionType, itemName: String, itemId: String? = nil, quantity: Int = 1, price: Double? = nil, modifiers: [String] = [], assumptions: [String] = [], isConfirmed: Bool = false) {
        self.id = id
        self.type = type
        self.itemName = itemName
        self.itemId = itemId
        self.quantity = quantity
        self.price = price
        self.modifiers = modifiers
        self.assumptions = assumptions
        self.isConfirmed = isConfirmed
    }
}

nonisolated enum ActionType: String, Sendable {
    case addToCart = "Add to Cart"
    case removeFromCart = "Remove from Cart"
    case updateQuantity = "Update Quantity"
    case applyPreference = "Apply Preference"
}

nonisolated struct AIActionLog: Identifiable, Sendable {
    let id: String
    let action: ProposedAction
    let timestamp: Date
    var undone: Bool

    init(id: String = UUID().uuidString, action: ProposedAction, timestamp: Date = Date(), undone: Bool = false) {
        self.id = id
        self.action = action
        self.timestamp = timestamp
        self.undone = undone
    }
}

nonisolated struct ChatMessage: Codable, Sendable {
    let role: String
    let content: String
}

nonisolated struct ChatCompletionRequest: Codable, Sendable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
    let max_tokens: Int
}

nonisolated struct ChatCompletionResponse: Codable, Sendable {
    let choices: [ChatChoice]
}

nonisolated struct ChatChoice: Codable, Sendable {
    let message: ChatMessage
}

nonisolated struct TranscriptionResponse: Codable, Sendable {
    let text: String
    let language: String?
}

nonisolated struct QuickChip: Identifiable, Sendable {
    let id: String
    let label: String
    let icon: String
    let message: String

    init(id: String = UUID().uuidString, label: String, icon: String, message: String) {
        self.id = id
        self.label = label
        self.icon = icon
        self.message = message
    }

    static let defaults: [QuickChip] = [
        QuickChip(label: "Comfort", icon: "cup.and.saucer.fill", message: "I'm in the mood for comfort food"),
        QuickChip(label: "Healthy", icon: "leaf.fill", message: "Suggest something healthy and light"),
        QuickChip(label: "Under $15", icon: "dollarsign.circle", message: "What can I get for under 15 dollars"),
        QuickChip(label: "High Protein", icon: "figure.strengthtraining.traditional", message: "I want something high in protein"),
        QuickChip(label: "Spicy", icon: "flame.fill", message: "Give me something spicy"),
        QuickChip(label: "Quick", icon: "bolt.fill", message: "What is the fastest thing to prepare"),
    ]
}
