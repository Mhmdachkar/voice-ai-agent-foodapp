import SwiftUI

struct VoiceAIView: View {
    @Environment(DataStore.self) private var store
    @Environment(CartViewModel.self) private var cartVM
    @Environment(\.dismiss) private var dismiss
    @State private var aiClient = AIClient()
    @State private var avatarState: AvatarState = .idle
    @State private var transcript: String = ""
    @State private var aiResponse: String = ""
    @State private var suggestedItems: [MenuItem] = []
    @State private var inputText: String = ""
    @State private var pulseAnimation: Bool = false

    nonisolated enum AvatarState: Sendable {
        case idle, listening, thinking, speaking, success
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                avatarView

                if !aiResponse.isEmpty {
                    responseSection
                }

                if !suggestedItems.isEmpty {
                    suggestedItemsSection
                }

                Spacer()

                inputSection
            }
            .padding(Theme.spacingMD)
            .background(Theme.background)
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
    }

    private var avatarView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseAnimation ? 1.2 : 1)
                    .opacity(pulseAnimation ? 0.3 : 0.6)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.accent, Color(hex: "FF6B35")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: avatarIcon)
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
            }

            Text(avatarMessage)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var avatarIcon: String {
        switch avatarState {
        case .idle: "brain.head.profile.fill"
        case .listening: "waveform"
        case .thinking: "ellipsis"
        case .speaking: "speaker.wave.2.fill"
        case .success: "checkmark"
        }
    }

    private var avatarMessage: String {
        switch avatarState {
        case .idle: "Tell me what you're craving!\nType below or describe your mood."
        case .listening: "Listening..."
        case .thinking: "Let me find the perfect food for you..."
        case .speaking: "Here's what I found!"
        case .success: "Added to your cart!"
        }
    }

    private var responseSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Theme.accent)
                Text("AI Recommendation")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.accent)
            }
            Text(aiResponse)
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary)
                .lineSpacing(4)
        }
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var suggestedItemsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(suggestedItems) { item in
                    VStack(spacing: 8) {
                        Color(.secondarySystemBackground)
                            .frame(width: 100, height: 80)
                            .overlay {
                                AsyncImage(url: URL(string: item.imageURL)) { phase in
                                    if let image = phase.image {
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    }
                                }
                                .allowsHitTesting(false)
                            }
                            .clipShape(.rect(cornerRadius: 10))

                        Text(item.name)
                            .font(.caption2.weight(.medium))
                            .lineLimit(1)

                        Button {
                            cartVM.addItem(item)
                            withAnimation {
                                avatarState = .success
                            }
                        } label: {
                            Text("Add \(item.price, format: .currency(code: "USD"))")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Theme.accent, in: .capsule)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .frame(width: 100)
                }
            }
        }
        .contentMargins(.horizontal, 0)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var inputSection: some View {
        HStack(spacing: 12) {
            TextField("Describe what you want...", text: $inputText)
                .textFieldStyle(.plain)
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(.capsule)

            Button {
                processInput()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(inputText.isEmpty ? Theme.border : Theme.accent)
            }
            .disabled(inputText.isEmpty)
            .buttonStyle(ScaleButtonStyle())
        }
    }

    private func processInput() {
        let text = inputText
        inputText = ""
        transcript = text

        withAnimation { avatarState = .thinking }

        Task {
            let response = await aiClient.processVoiceCommand(text, menuItems: store.menuItems)
            withAnimation(.spring(duration: 0.4)) {
                aiResponse = response.message
                suggestedItems = response.suggestedItems
                avatarState = .speaking
            }
        }
    }
}
