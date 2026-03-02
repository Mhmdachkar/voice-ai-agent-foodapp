import SwiftUI
import AVFoundation

@Observable
final class VoiceCallViewModel {
    var callState: VoiceCallState = .idle
    var micMode: MicMode = .pushToTalk
    var isTTSEnabled: Bool = true
    var isMuted: Bool = false
    var messages: [ConversationMessage] = []
    var editableTranscript: String = ""
    var showTranscriptConfirmation: Bool = false
    var callDuration: TimeInterval = 0
    var isCallActive: Bool = false
    var errorMessage: String?
    var actionLog: [AIActionLog] = []
    var pendingActions: [ProposedAction] = []
    var lastSpokenText: String = ""
    var currentBudget: Double?
    var showQuickChips: Bool = true

    let foodMemory = FoodMemoryService()
    private let voiceAI = VoiceAIService()
    private let menuSearch = MenuSearchService()
    private var chatHistory: [ChatMessage] = []
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var callTimer: Task<Void, Never>?
    private var currentTask: Task<Void, Never>?
    private var retryCount: Int = 0
    private let maxRetries: Int = 1

    func startCall(menuItems: [MenuItem]) {
        isCallActive = true
        callDuration = 0
        messages = []
        chatHistory = []
        actionLog = []
        pendingActions = []
        errorMessage = nil
        currentBudget = nil
        showQuickChips = true
        menuSearch.buildIndex(from: menuItems)

        callTimer = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                self?.callDuration += 1
            }
        }

        let memoryContext = foodMemory.contextString()
        let hasPrefs = foodMemory.memory.dislikedIngredients.isEmpty == false ||
                       foodMemory.memory.defaultDrink != nil

        var greetingText = "Hey! I'm your food assistant. What are you craving today?"
        if hasPrefs {
            greetingText = "Hey! Welcome back. I remember your preferences. What sounds good today?"
        }

        let greeting = ConversationMessage(role: .assistant, text: greetingText)
        messages.append(greeting)

        if isTTSEnabled {
            voiceAI.speakFirstSentence(of: greetingText)
        }
    }

    func endCall() {
        isCallActive = false
        callTimer?.cancel()
        callTimer = nil
        currentTask?.cancel()
        currentTask = nil
        stopRecording()
        voiceAI.stopSpeaking()
        callState = .idle
    }

    // MARK: - Recording

    func startRecording() {
        guard !isMuted else { return }

        if voiceAI.isSpeaking {
            voiceAI.stopSpeaking()
            withAnimation(.spring(duration: 0.2)) {
                callState = .idle
            }
        }

        currentTask?.cancel()

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            errorMessage = "Audio session setup failed"
            return
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "voice_recording_\(UUID().uuidString).wav"
        recordingURL = tempDir.appendingPathComponent(fileName)

        guard let url = recordingURL else { return }

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            withAnimation(.spring(duration: 0.3)) {
                callState = .listening
                showQuickChips = false
            }
        } catch {
            errorMessage = "Could not start recording"
        }
    }

    func stopRecording() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        recorder.stop()
        audioRecorder = nil

        guard callState == .listening else { return }

        withAnimation(.spring(duration: 0.3)) {
            callState = .uploading
        }

        processRecording()
    }

    func toggleHandsFree() {
        micMode = micMode == .pushToTalk ? .handsFree : .pushToTalk
    }

    func toggleMute() {
        isMuted.toggle()
        if isMuted && callState == .listening {
            stopRecording()
        }
    }

    func toggleTTS() {
        isTTSEnabled.toggle()
        if !isTTSEnabled {
            voiceAI.stopSpeaking()
        }
    }

    func repeatLastResponse() {
        guard !lastSpokenText.isEmpty, isTTSEnabled else { return }
        voiceAI.speak(lastSpokenText)
    }

    // MARK: - Transcript

    func confirmTranscript() {
        showTranscriptConfirmation = false
        let text = editableTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            callState = .idle
            return
        }
        sendUserMessage(text)
    }

    func retryRecording() {
        showTranscriptConfirmation = false
        editableTranscript = ""
        callState = .idle
    }

    func sendTextMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        showQuickChips = false
        sendUserMessage(trimmed)
    }

    func sendQuickChip(_ chip: QuickChip) {
        showQuickChips = false
        sendUserMessage(chip.message)
    }

    // MARK: - Action Handling

    func confirmActions(cartVM: CartViewModel, menuItems: [MenuItem]) {
        for action in pendingActions {
            switch action.type {
            case .addToCart:
                if let item = menuItems.first(where: { $0.id == action.itemId }) {
                    let qty = max(1, min(20, action.quantity))
                    cartVM.addItem(item, quantity: qty)
                    actionLog.insert(AIActionLog(action: action), at: 0)
                } else if let item = menuItems.first(where: { $0.name.lowercased() == action.itemName.lowercased() }) {
                    let qty = max(1, min(20, action.quantity))
                    cartVM.addItem(item, quantity: qty)
                    actionLog.insert(AIActionLog(action: action), at: 0)
                }
            case .removeFromCart:
                if let cartItem = cartVM.items.first(where: { $0.menuItem.name.lowercased() == action.itemName.lowercased() }) {
                    cartVM.removeItem(cartItem)
                    actionLog.insert(AIActionLog(action: action), at: 0)
                }
            case .updateQuantity:
                if let cartItem = cartVM.items.first(where: { $0.menuItem.name.lowercased() == action.itemName.lowercased() }) {
                    let qty = max(1, min(20, action.quantity))
                    cartVM.updateQuantity(cartItem, quantity: qty)
                    actionLog.insert(AIActionLog(action: action), at: 0)
                }
            case .applyPreference:
                break
            }
        }

        if let budget = currentBudget {
            let remaining = budget - cartVM.subtotal
            if remaining > 0 {
                let remainingStr = String(format: "$%.2f", remaining)
                let infoMsg = ConversationMessage(
                    role: .assistant,
                    text: "Added to cart! You have \(remainingStr) left in your budget."
                )
                messages.append(infoMsg)
            }
        } else {
            let confirmMsg = ConversationMessage(role: .assistant, text: "Done! Items added to your cart.")
            messages.append(confirmMsg)
        }

        withAnimation(.spring(duration: 0.3)) {
            pendingActions.removeAll()
        }
    }

    func undoLastAction(cartVM: CartViewModel) {
        guard let lastLog = actionLog.first(where: { !$0.undone }) else { return }
        guard let index = actionLog.firstIndex(where: { $0.id == lastLog.id }) else { return }
        actionLog[index].undone = true

        switch lastLog.action.type {
        case .addToCart:
            if let cartItem = cartVM.items.first(where: { $0.menuItem.name.lowercased() == lastLog.action.itemName.lowercased() }) {
                cartVM.removeItem(cartItem)
                let undoMsg = ConversationMessage(role: .assistant, text: "Removed \(lastLog.action.itemName) from cart.")
                messages.append(undoMsg)
            }
        case .removeFromCart:
            break
        default:
            break
        }
    }

    func dismissActions() {
        withAnimation(.spring(duration: 0.3)) {
            pendingActions.removeAll()
        }
    }

    // MARK: - Private Pipeline

    private func processRecording() {
        retryCount = 0
        currentTask = Task {
            guard let url = recordingURL else {
                callState = .idle
                return
            }

            do {
                withAnimation(.spring(duration: 0.2)) {
                    callState = .transcribing
                }

                let transcript = try await voiceAI.transcribe(audioFileURL: url)
                let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)

                guard !Task.isCancelled else { return }

                guard !trimmed.isEmpty else {
                    errorMessage = "I didn't catch that. Please try again."
                    callState = .idle
                    return
                }

                let wordCount = trimmed.components(separatedBy: " ").count
                let isLowConfidence = trimmed.count < 5 || wordCount < 2

                if isLowConfidence {
                    editableTranscript = trimmed
                    showTranscriptConfirmation = true
                    withAnimation(.spring(duration: 0.2)) {
                        callState = .confirmingTranscript
                    }
                    return
                }

                sendUserMessage(trimmed)
            } catch {
                if !Task.isCancelled {
                    if retryCount < maxRetries {
                        retryCount += 1
                        processRecording()
                    } else {
                        errorMessage = "Could not process speech. Try again or type your message."
                        callState = .idle
                    }
                }
            }

            cleanupRecording()
        }
    }

    private func sendUserMessage(_ text: String) {
        let userMsg = ConversationMessage(role: .user, text: text)
        messages.append(userMsg)
        chatHistory.append(ChatMessage(role: "user", content: text))

        withAnimation(.spring(duration: 0.3)) {
            callState = .thinking
        }

        currentTask = Task {
            do {
                let classification = try await voiceAI.classifyIntent(text: text)
                guard !Task.isCancelled else { return }

                let intent = UserIntent(rawValue: classification.intent) ?? .unknown

                if classification.needsClarification, let question = classification.clarificationQuestion {
                    chatHistory.append(ChatMessage(role: "assistant", content: question))
                    let clarMsg = ConversationMessage(role: .assistant, text: question)
                    messages.append(clarMsg)
                    lastSpokenText = question

                    if isTTSEnabled {
                        await speakAndWait(question)
                    }

                    if !Task.isCancelled {
                        withAnimation(.spring(duration: 0.3)) {
                            callState = .idle
                        }
                    }
                    return
                }

                if let budget = extractBudget(from: text) {
                    currentBudget = budget
                }

                let filters = buildFilters(from: text, intent: intent)
                let searchResults = menuSearch.search(query: text, filters: filters)
                let menuContext: String
                if searchResults.isEmpty {
                    menuContext = menuSearch.fullContextString()
                } else {
                    menuContext = menuSearch.contextString(for: searchResults)
                }

                let response = try await voiceAI.chat(
                    messages: chatHistory,
                    menuContext: menuContext,
                    foodMemoryContext: foodMemory.contextString(),
                    intent: intent
                )

                guard !Task.isCancelled else { return }

                chatHistory.append(ChatMessage(role: "assistant", content: response))

                let actions = parseActions(from: response, searchResults: searchResults)
                let validActions = validateActions(actions)

                if !validActions.isEmpty {
                    withAnimation(.spring(duration: 0.3)) {
                        pendingActions = validActions
                        callState = .proposingActions
                    }

                    let summaryText = buildActionSummary(response: response, actions: validActions)
                    let assistantMsg = ConversationMessage(
                        role: .assistant,
                        text: summaryText,
                        proposedActions: validActions,
                        isDecisionCard: true
                    )
                    messages.append(assistantMsg)
                    lastSpokenText = response

                    if isTTSEnabled {
                        let shortReply = firstSentences(of: response, max: 1)
                        await speakAndWait(shortReply)
                    }
                } else {
                    let assistantMsg = ConversationMessage(role: .assistant, text: response)
                    messages.append(assistantMsg)
                    lastSpokenText = response

                    if isTTSEnabled {
                        withAnimation(.spring(duration: 0.3)) {
                            callState = .speaking
                        }
                        let sentenceCount = response.components(separatedBy: ". ").count
                        if sentenceCount > 2 {
                            await speakAndWait(firstSentences(of: response, max: 1))
                        } else {
                            await speakAndWait(response)
                        }
                    }
                }

                if !Task.isCancelled && callState != .proposingActions {
                    withAnimation(.spring(duration: 0.3)) {
                        callState = .idle
                    }
                }
            } catch {
                if !Task.isCancelled {
                    if retryCount < maxRetries {
                        retryCount += 1
                        sendUserMessage(text)
                    } else {
                        errorMessage = error.localizedDescription
                        withAnimation(.spring(duration: 0.3)) {
                            callState = .idle
                        }
                    }
                }
            }
        }
    }

    private func speakAndWait(_ text: String) async {
        voiceAI.speak(text)
        while voiceAI.isSpeaking {
            try? await Task.sleep(for: .milliseconds(100))
            if Task.isCancelled { break }
        }
    }

    private func extractBudget(from text: String) -> Double? {
        let lowered = text.lowercased()
        let patterns = [
            "under \\$?(\\d+\\.?\\d*)",
            "less than \\$?(\\d+\\.?\\d*)",
            "budget.+\\$?(\\d+\\.?\\d*)",
            "\\$?(\\d+\\.?\\d*) or less",
            "max \\$?(\\d+\\.?\\d*)"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: lowered, range: NSRange(lowered.startIndex..., in: lowered)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: lowered),
               let value = Double(lowered[range]) {
                return value
            }
        }
        return nil
    }

    private func buildFilters(from text: String, intent: UserIntent) -> MenuSearchFilters {
        var filters = MenuSearchFilters()
        let lowered = text.lowercased()

        if let budget = currentBudget {
            filters.maxPrice = budget
        }

        if lowered.contains("low calorie") || lowered.contains("low cal") || lowered.contains("diet") {
            filters.maxCalories = 500
        }
        if lowered.contains("high protein") || lowered.contains("protein") {
            filters.minProtein = 25
        }
        if lowered.contains("vegetarian") || lowered.contains("veg") {
            filters.excludeIngredients = ["beef", "chicken", "shrimp", "salmon", "tuna", "pork"]
        }

        if !foodMemory.memory.dislikedIngredients.isEmpty {
            var existing = filters.excludeIngredients ?? []
            existing.append(contentsOf: foodMemory.memory.dislikedIngredients)
            filters.excludeIngredients = existing
        }

        return filters
    }

    private func parseActions(from response: String, searchResults: [MenuIndexEntry]) -> [ProposedAction] {
        var actions: [ProposedAction] = []
        let lowered = response.lowercased()

        let addPhrases = ["add", "adding", "i'll add", "let me add", "i've added", "added"]
        let hasAddIntent = addPhrases.contains { lowered.contains($0) }

        let removePhrases = ["remove", "removing", "i'll remove", "take off", "take out"]
        let hasRemoveIntent = removePhrases.contains { lowered.contains($0) }

        if hasAddIntent {
            for entry in searchResults {
                if lowered.contains(entry.name.lowercased()) {
                    let qty = extractQuantity(from: response, itemName: entry.name)
                    actions.append(ProposedAction(
                        type: .addToCart,
                        itemName: entry.name,
                        itemId: entry.id,
                        quantity: qty,
                        price: entry.price,
                        assumptions: buildAssumptions(for: entry)
                    ))
                }
            }
        }

        if hasRemoveIntent {
            for entry in searchResults {
                if lowered.contains(entry.name.lowercased()) {
                    actions.append(ProposedAction(
                        type: .removeFromCart,
                        itemName: entry.name,
                        itemId: entry.id
                    ))
                }
            }
        }

        return actions
    }

    private func extractQuantity(from text: String, itemName: String) -> Int {
        let lowered = text.lowercased()
        let numberWords: [String: Int] = [
            "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
            "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10
        ]

        for (word, num) in numberWords {
            if lowered.contains("\(word) \(itemName.lowercased())") { return num }
        }

        if let regex = try? NSRegularExpression(pattern: "(\\d+)\\s+\(NSRegularExpression.escapedPattern(for: itemName.lowercased()))", options: .caseInsensitive),
           let match = regex.firstMatch(in: lowered, range: NSRange(lowered.startIndex..., in: lowered)),
           match.numberOfRanges > 1,
           let range = Range(match.range(at: 1), in: lowered),
           let num = Int(lowered[range]) {
            return min(20, max(1, num))
        }

        return 1
    }

    private func buildAssumptions(for entry: MenuIndexEntry) -> [String] {
        var assumptions: [String] = []
        let prefs = foodMemory.memory

        if prefs.spiceLevel != .medium {
            assumptions.append("Spice: \(prefs.spiceLevel.rawValue)")
        }
        if !prefs.dislikedIngredients.isEmpty {
            let overlap = entry.ingredients.filter { prefs.dislikedIngredients.contains($0) }
            if !overlap.isEmpty {
                assumptions.append("Contains disliked: \(overlap.joined(separator: ", "))")
            }
        }
        return assumptions
    }

    private func validateActions(_ actions: [ProposedAction]) -> [ProposedAction] {
        actions.compactMap { action in
            guard action.quantity >= 1 && action.quantity <= 20 else { return nil }

            switch action.type {
            case .addToCart, .removeFromCart, .updateQuantity:
                if action.itemId != nil || menuSearch.findItem(byName: action.itemName) != nil {
                    if let budget = currentBudget, let price = action.price {
                        if price * Double(action.quantity) > budget {
                            return nil
                        }
                    }
                    return action
                }
                return nil
            case .applyPreference:
                return action
            }
        }
    }

    private func buildActionSummary(response: String, actions: [ProposedAction]) -> String {
        var parts: [String] = []
        for action in actions {
            switch action.type {
            case .addToCart:
                let priceStr = action.price.map { String(format: "$%.2f", $0 * Double(action.quantity)) } ?? ""
                parts.append("\(action.quantity)x \(action.itemName) \(priceStr)")
            case .removeFromCart:
                parts.append("Remove \(action.itemName)")
            case .updateQuantity:
                parts.append("Update \(action.itemName) to \(action.quantity)")
            case .applyPreference:
                parts.append("Set preference: \(action.itemName)")
            }
        }
        return response
    }

    private func firstSentences(of text: String, max: Int) -> String {
        let sentences = text.components(separatedBy: ". ")
        let selected = Array(sentences.prefix(max))
        var result = selected.joined(separator: ". ")
        if !result.hasSuffix(".") { result += "." }
        return result
    }

    private func cleanupRecording() {
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordingURL = nil
    }

    var formattedDuration: String {
        let minutes = Int(callDuration) / 60
        let seconds = Int(callDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
