import SwiftUI

struct AccentButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isFullWidth: Bool = true
    var isLoading: Bool = false

    init(_ title: String, icon: String? = nil, isFullWidth: Bool = true, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isFullWidth = isFullWidth
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.body.weight(.semibold))
                    }
                    Text(title)
                        .font(.body.weight(.bold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: 52)
            .padding(.horizontal, isFullWidth ? 0 : 24)
            .background(Theme.accent, in: .capsule)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isLoading)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

struct CardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(Theme.cardBackground)
            .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

struct ChipView: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    init(_ title: String, icon: String? = nil, isSelected: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .foregroundStyle(isSelected ? .white : Theme.textPrimary)
            .background(isSelected ? Theme.accent : Theme.cardBackground)
            .clipShape(.capsule)
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct RatingView: View {
    let rating: Double
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption)
                .foregroundStyle(Theme.accent)
            Text(String(format: "%.1f", rating))
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
            Text("(\(count))")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
    }
}

struct SkeletonView: View {
    @State private var isAnimating: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.3), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 200 : -200)
            )
            .clipShape(.rect(cornerRadius: 8))
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

struct BadgeView: View {
    let count: Int

    var body: some View {
        if count > 0 {
            Text("\(count)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .frame(minWidth: 18, minHeight: 18)
                .background(Theme.danger, in: Circle())
                .transition(.scale.combined(with: .opacity))
        }
    }
}

struct ToastView: View {
    let message: String
    let type: ToastType

    nonisolated enum ToastType: Sendable {
        case success, error, info
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: type == .success ? "checkmark.circle.fill" : type == .error ? "xmark.circle.fill" : "info.circle.fill")
                .foregroundStyle(type == .success ? Theme.success : type == .error ? Theme.danger : Theme.accent)
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.7))
        .clipShape(.capsule)
    }
}

struct SectionHeader: View {
    let title: String
    var action: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            if let action {
                Button(action) {
                    onAction?()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.accent)
            }
        }
    }
}
