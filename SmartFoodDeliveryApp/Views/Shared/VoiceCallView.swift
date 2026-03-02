import SwiftUI
import AVFoundation

struct VoiceCallView: View {
    @Environment(DataStore.self) private var store
    @Environment(CartViewModel.self) private var cartVM
    @Environment(\.dismiss) private var dismiss
    @State private var vm = VoiceCallViewModel()
    @State private var showTextInput: Bool = false
    @State private var textInput: String = ""
    @State private var orbScale: CGFloat = 1.0
    @State private var orbPulse: Bool = false
    @State private var showPreferences: Bool = false

    var body: some View {
        ZStack {
            backgroundGradient
            VStack(spacing: 0) {
                callHeader
                scrollContent
                Spacer(minLength: 0)
                if showTextInput {
                    textInputBar
                }
                callControls
            }
        }
        .ignoresSafeArea(.container, edges: .top)
        .onAppear { vm.startCall(menuItems: store.menuItems) }
        .onDisappear { vm.endCall() }
        .alert("Confirm Transcript", isPresented: $vm.showTranscriptConfirmation) {
            TextField("What did you say?", text: $vm.editableTranscript)
            Button("Send") { vm.confirmTranscript() }
            Button("Retry", role: .destructive) { vm.retryRecording() }
            Button("Cancel", role: .cancel) { vm.callState = .idle }
        } message: {
            Text("I heard: \"\(vm.editableTranscript)\"\nIs that correct?")
        }
        .overlay(alignment: .top) {
            if let error = vm.errorMessage {
                errorBanner(error)
            }
        }
        .sheet(isPresented: $showPreferences) {
            preferencesSheet
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(hex: "1A1A2E"), Color(hex: "16213E"), Color(hex: "0F3460")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var callHeader: some View {
        VStack(spacing: 4) {
            HStack {
                Button {
                    vm.endCall()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 44, height: 44)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text("AI Assistant")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    HStack(spacing: 6) {
                        Circle()
                            .fill(vm.isCallActive ? Theme.success : .gray)
                            .frame(width: 6, height: 6)
                        Text(vm.formattedDuration)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                Spacer()
                Menu {
                    Button { vm.toggleTTS() } label: {
                        Label(vm.isTTSEnabled ? "Mute Voice" : "Enable Voice", systemImage: vm.isTTSEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    }
                    Button { vm.toggleHandsFree() } label: {
                        Label(vm.micMode == .pushToTalk ? "Hands-Free Mode" : "Push to Talk", systemImage: vm.micMode == .pushToTalk ? "hand.raised.fill" : "mic.fill")
                    }
                    Button { showPreferences = true } label: {
                        Label("Preferences", systemImage: "heart.text.clipboard")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 56)

            Text(vm.callState.label)
                .font(.caption.weight(.medium))
                .foregroundStyle(statusColor.opacity(0.8))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.12), in: .capsule)
                .contentTransition(.numericText())
        }
        .padding(.bottom, 8)
    }

    private var statusColor: Color {
        switch vm.callState {
        case .listening: Theme.success
        case .thinking, .uploading, .transcribing: Theme.accent
        case .speaking: Color(hex: "5B9BD5")
        case .error: Theme.danger
        case .proposingActions: Theme.warning
        default: .white
        }
    }

    private var scrollContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    avatarOrb
                        .padding(.top, 12)

                    stateHint

                    if vm.showQuickChips && vm.messages.count <= 1 {
                        quickChipsSection
                    }

                    conversationBubbles

                    if !vm.pendingActions.isEmpty {
                        decisionCard.id("decision_card")
                    }

                    Color.clear.frame(height: 1).id("scroll_bottom")
                }
                .padding(.horizontal, 16)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: vm.messages.count) { _, _ in
                withAnimation { proxy.scrollTo("scroll_bottom", anchor: .bottom) }
            }
            .onChange(of: vm.pendingActions.count) { _, _ in
                withAnimation { proxy.scrollTo("decision_card", anchor: .bottom) }
            }
        }
    }

    // MARK: - Avatar Orb

    private var avatarOrb: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(orbGradient.opacity(0.06 + Double(i) * 0.03))
                    .frame(width: CGFloat(140 + i * 28), height: CGFloat(140 + i * 28))
                    .scaleEffect(vm.callState == .listening ? 1.08 + CGFloat(i) * 0.04 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.8 + Double(i) * 0.2).repeatForever(autoreverses: true),
                        value: vm.callState == .listening
                    )
            }

            Circle()
                .fill(orbGradient)
                .frame(width: 100, height: 100)
                .shadow(color: Theme.accent.opacity(0.35), radius: 16)
                .scaleEffect(orbScale)
                .overlay {
                    Image(systemName: vm.callState.icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(.white)
                        .contentTransition(.symbolEffect(.replace))
                }

            if vm.callState == .listening {
                Circle()
                    .stroke(Theme.accent.opacity(0.25), lineWidth: 2.5)
                    .frame(width: 130, height: 130)
                    .scaleEffect(orbPulse ? 1.35 : 1.0)
                    .opacity(orbPulse ? 0 : 0.5)
                    .onAppear {
                        withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                            orbPulse = true
                        }
                    }
                    .onDisappear { orbPulse = false }
            }

            if vm.callState.isProcessing {
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(.white.opacity(0.5))
                            .frame(width: 7, height: 7)
                            .offset(y: vm.callState.isProcessing ? -5 : 0)
                            .animation(
                                .easeInOut(duration: 0.45).repeatForever(autoreverses: true).delay(Double(i) * 0.12),
                                value: vm.callState.isProcessing
                            )
                    }
                }
                .offset(y: 70)
            }
        }
        .frame(height: 200)
        .onChange(of: vm.callState) { _, newValue in
            withAnimation(.spring(duration: 0.4)) {
                switch newValue {
                case .listening: orbScale = 1.06
                case .thinking, .uploading, .transcribing: orbScale = 0.94
                case .speaking: orbScale = 1.04
                case .proposingActions: orbScale = 1.02
                default: orbScale = 1.0
                }
            }
        }
    }

    private var orbGradient: LinearGradient {
        LinearGradient(
            colors: [Theme.accent, Color(hex: "FF6B35")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var stateHint: some View {
        Group {
            if vm.micMode == .handsFree && vm.callState == .idle {
                Text("Hands-free mode on")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.35))
            } else if vm.micMode == .pushToTalk && vm.callState == .idle {
                Text("Hold mic button to talk")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
    }

    // MARK: - Quick Chips

    private var quickChipsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick suggestions")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.4))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], spacing: 8) {
                ForEach(QuickChip.defaults) { chip in
                    Button {
                        vm.sendQuickChip(chip)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: chip.icon)
                                .font(.caption2)
                            Text(chip.label)
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.08), in: .capsule)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Conversation

    private var conversationBubbles: some View {
        LazyVStack(spacing: 10) {
            ForEach(vm.messages) { msg in
                messageBubble(msg).id(msg.id)
            }
        }
    }

    private func messageBubble(_ message: ConversationMessage) -> some View {
        HStack(alignment: .bottom) {
            if message.role == .user { Spacer(minLength: 50) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 5) {
                Text(message.text)
                    .font(.subheadline)
                    .foregroundStyle(message.role == .user ? .white : .white.opacity(0.9))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.role == .user
                            ? AnyShapeStyle(Theme.accent)
                            : AnyShapeStyle(.white.opacity(0.1))
                    )
                    .clipShape(.rect(cornerRadius: 16, style: .continuous))

                if message.role == .assistant && !message.text.isEmpty {
                    HStack(spacing: 10) {
                        Button { vm.repeatLastResponse() } label: {
                            Image(systemName: "speaker.wave.1.fill")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.35))
                        }
                        Text(message.timestamp, style: .time)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.2))
                    }
                }
            }

            if message.role == .assistant { Spacer(minLength: 50) }
        }
    }

    // MARK: - Decision Card

    private var decisionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Theme.accent)
                Text("Proposed Actions")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.accent)
                Spacer()
            }

            ForEach(vm.pendingActions) { action in
                HStack(spacing: 10) {
                    Image(systemName: actionIcon(for: action.type))
                        .foregroundStyle(actionColor(for: action.type))
                        .font(.body)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(action.itemName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        if let price = action.price {
                            Text("\(action.quantity)x " + String(format: "$%.2f", price))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    Spacer()
                }
            }

            let allAssumptions = vm.pendingActions.flatMap { $0.assumptions }
            if !allAssumptions.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.caption2)
                    Text(allAssumptions.joined(separator: " · "))
                        .font(.caption2)
                }
                .foregroundStyle(.white.opacity(0.35))
            }

            HStack(spacing: 10) {
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        vm.confirmActions(cartVM: cartVM, menuItems: store.menuItems)
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark")
                        Text("Confirm")
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Theme.success, in: .capsule)
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: vm.pendingActions.isEmpty)

                Button { vm.dismissActions() } label: {
                    Text("Dismiss")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.45))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.white.opacity(0.08), in: .capsule)
                }

                Spacer()

                if !vm.actionLog.isEmpty {
                    Button { vm.undoLastAction(cartVM: cartVM) } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.uturn.backward")
                            Text("Undo")
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.accent)
                    }
                }
            }
        }
        .padding(16)
        .background(.white.opacity(0.07))
        .clipShape(.rect(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.accent.opacity(0.25), lineWidth: 1)
        )
        .transition(.scale(scale: 0.95).combined(with: .opacity))
    }

    private func actionIcon(for type: ActionType) -> String {
        switch type {
        case .addToCart: "plus.circle.fill"
        case .removeFromCart: "minus.circle.fill"
        case .updateQuantity: "arrow.triangle.2.circlepath"
        case .applyPreference: "heart.fill"
        }
    }

    private func actionColor(for type: ActionType) -> Color {
        switch type {
        case .addToCart: Theme.success
        case .removeFromCart: Theme.danger
        case .updateQuantity, .applyPreference: Theme.accent
        }
    }

    // MARK: - Text Input

    private var textInputBar: some View {
        HStack(spacing: 10) {
            TextField("Type a message...", text: $textInput)
                .font(.subheadline)
                .foregroundStyle(.white)
                .tint(Theme.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.white.opacity(0.1))
                .clipShape(.capsule)
                .onSubmit {
                    guard !textInput.isEmpty else { return }
                    vm.sendTextMessage(textInput)
                    textInput = ""
                    showTextInput = false
                }

            Button {
                vm.sendTextMessage(textInput)
                textInput = ""
                showTextInput = false
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(textInput.isEmpty ? .white.opacity(0.25) : Theme.accent)
            }
            .disabled(textInput.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Controls

    private var callControls: some View {
        VStack(spacing: 14) {
            HStack(spacing: 28) {
                controlButton(icon: vm.isMuted ? "mic.slash.fill" : "mic.fill", label: vm.isMuted ? "Unmute" : "Mute", isActive: vm.isMuted) {
                    vm.toggleMute()
                }

                micButton

                controlButton(icon: vm.isTTSEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill", label: vm.isTTSEnabled ? "Speaker" : "Off", isActive: vm.isTTSEnabled) {
                    vm.toggleTTS()
                }
            }

            HStack(spacing: 16) {
                Button {
                    withAnimation(.spring(duration: 0.3)) { showTextInput.toggle() }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "keyboard")
                        Text("Type")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.45))
                }

                Spacer()

                Button {
                    vm.endCall()
                    dismiss()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "phone.down.fill")
                        Text("End")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Theme.danger, in: .capsule)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 36)
    }

    private var micButton: some View {
        VoiceCallMicButton(
            callState: vm.callState,
            micMode: vm.micMode,
            onTapHandsFree: {
                if vm.callState == .listening {
                    vm.stopRecording()
                } else if vm.callState == .idle || vm.callState == .proposingActions {
                    requestMicPermissionAndRecord()
                }
            },
            onPressStart: { requestMicPermissionAndRecord() },
            onPressEnd: {
                if vm.callState == .listening { vm.stopRecording() }
            }
        )
        .sensoryFeedback(.impact(weight: .medium), trigger: vm.callState == .listening)
    }

    private func controlButton(icon: String, label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .frame(width: 46, height: 46)
                    .foregroundStyle(isActive ? .white : .white.opacity(0.45))
                    .background(isActive ? .white.opacity(0.14) : .white.opacity(0.05))
                    .clipShape(Circle())

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.warning)
            Text(message)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white)
            Spacer()
            Button {
                withAnimation { vm.errorMessage = nil }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "1A1A2E").opacity(0.95))
        .clipShape(.rect(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.top, 60)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Preferences Sheet

    private var preferencesSheet: some View {
        NavigationStack {
            List {
                Section("Spice Level") {
                    Picker("Spice Level", selection: Binding(
                        get: { vm.foodMemory.memory.spiceLevel },
                        set: { vm.foodMemory.setSpiceLevel($0) }
                    )) {
                        ForEach(SpiceLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Default Drink") {
                    TextField("e.g. Matcha Latte", text: Binding(
                        get: { vm.foodMemory.memory.defaultDrink ?? "" },
                        set: { vm.foodMemory.setDefaultDrink($0.isEmpty ? nil : $0) }
                    ))
                }

                Section("Disliked Ingredients") {
                    ForEach(vm.foodMemory.memory.dislikedIngredients, id: \.self) { ingredient in
                        HStack {
                            Text(ingredient.capitalized)
                            Spacer()
                            Button { vm.foodMemory.removeDislikedIngredient(ingredient) } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    let suggestions = ["Onions", "Mushrooms", "Anchovies", "Cilantro", "Shellfish", "Peanuts"]
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 8) {
                        ForEach(suggestions, id: \.self) { item in
                            let isAdded = vm.foodMemory.memory.dislikedIngredients.contains(item.lowercased())
                            Button {
                                if isAdded {
                                    vm.foodMemory.removeDislikedIngredient(item)
                                } else {
                                    vm.foodMemory.addDislikedIngredient(item)
                                }
                            } label: {
                                Text(item)
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .foregroundStyle(isAdded ? .white : .primary)
                                    .background(isAdded ? Theme.accent : Color(.tertiarySystemFill), in: .capsule)
                            }
                        }
                    }
                }

                Section("Notes") {
                    TextField("e.g. Extra napkins please", text: Binding(
                        get: { vm.foodMemory.memory.commonNotes ?? "" },
                        set: { vm.foodMemory.setCommonNotes($0.isEmpty ? nil : $0) }
                    ))
                }
            }
            .navigationTitle("Food Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showPreferences = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func requestMicPermissionAndRecord() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            vm.startRecording()
        case .denied:
            vm.errorMessage = "Microphone access denied. Enable in Settings."
        case .undetermined:
            AVAudioApplication.requestRecordPermission { granted in
                if granted {
                    vm.startRecording()
                } else {
                    vm.errorMessage = "Microphone access is required for voice ordering."
                }
            }
        @unknown default:
            break
        }
    }
}

struct VoiceCallMicButton: View {
    let callState: VoiceCallState
    let micMode: MicMode
    let onTapHandsFree: () -> Void
    let onPressStart: () -> Void
    let onPressEnd: () -> Void

    var body: some View {
        Button {
            if micMode == .handsFree {
                onTapHandsFree()
            } else {
                if callState == .listening {
                    onPressEnd()
                } else {
                    onPressStart()
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(callState == .listening ? Theme.danger : .white)
                    .frame(width: 68, height: 68)
                    .shadow(color: (callState == .listening ? Theme.danger : .white).opacity(0.25), radius: 10)

                Image(systemName: callState == .listening ? "stop.fill" : "mic.fill")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(callState == .listening ? .white : Color(hex: "1A1A2E"))
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(callState.isProcessing)
    }
}
