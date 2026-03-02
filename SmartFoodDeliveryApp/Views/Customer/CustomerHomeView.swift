import SwiftUI
import Combine

struct CustomerHomeView: View {
    @Environment(DataStore.self) private var store
    @Environment(CartViewModel.self) private var cartVM
    @Environment(AuthViewModel.self) private var authVM
    @State private var selectedMood: Mood?
    @State private var showVoiceAI: Bool = false
    @State private var showVoiceCall: Bool = false
    @State private var showDetail: MenuItem?
    @State private var searchText: String = ""
    @State private var appeared: Bool = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good Morning" }
        if hour < 17 { return "Good Afternoon" }
        return "Good Evening"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    heroSection
                    moodChips
                    if let selectedMood {
                        moodResults(selectedMood)
                    }
                    topPicks
                    limitedTimeOffers
                    popularCombos
                    trendingFilters
                    allItems
                }
                .padding(.bottom, cartVM.isEmpty ? 20 : 80)
            }
            .background(Theme.background)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(greeting)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                        Text(authVM.currentUser?.name ?? "Friend")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showVoiceAI = true } label: {
                        Image(systemName: "waveform.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
            .sheet(item: $showDetail) { item in
                MenuItemDetailView(item: item)
            }
            .sheet(isPresented: $showVoiceAI) {
                VoiceAIView()
            }
            .fullScreenCover(isPresented: $showVoiceCall) {
                VoiceCallView()
            }
            .overlay(alignment: .bottom) {
                if !cartVM.isEmpty {
                    miniCartBar
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    appeared = true
                }
            }
        }
    }

    private var heroSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.accent, Theme.accent.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    Image(systemName: "brain.head.profile.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("What are you craving?")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text("Let AI help you decide")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }

            HStack(spacing: 10) {
                Button {
                    showVoiceCall = true
                } label: {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text("Call Assistant")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        LinearGradient(
                            colors: [Theme.accent, Color(hex: "FF6B35")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: .capsule
                    )
                }
                .buttonStyle(ScaleButtonStyle())

                Button {
                    showVoiceAI = true
                } label: {
                    HStack {
                        Image(systemName: "text.bubble.fill")
                    }
                    .foregroundStyle(Theme.accent)
                    .frame(width: 44, height: 44)
                    .background(Theme.accent.opacity(0.12), in: Circle())
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(20)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: Theme.cornerRadiusLarge))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        .padding(.horizontal, Theme.spacingMD)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    private var moodChips: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "How are you feeling?")
                .padding(.horizontal, Theme.spacingMD)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Mood.allCases) { mood in
                        Button {
                            withAnimation(.spring(duration: 0.3)) {
                                selectedMood = selectedMood == mood ? nil : mood
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(mood.emoji)
                                    .font(.body)
                                Text(mood.rawValue)
                                    .font(.subheadline.weight(.medium))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .foregroundStyle(selectedMood == mood ? .white : Theme.textPrimary)
                            .background(selectedMood == mood ? Theme.accent : Theme.cardBackground)
                            .clipShape(.capsule)
                            .overlay(
                                Capsule()
                                    .stroke(selectedMood == mood ? Color.clear : Theme.border, lineWidth: 1)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, Theme.spacingMD)
            }
            .contentMargins(.horizontal, 0)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
    }

    private func moodResults(_ mood: Mood) -> some View {
        let items = AIClient().getMoodSuggestions(mood: mood, menuItems: store.menuItems)
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "\(mood.emoji) \(mood.rawValue) Picks")
                .padding(.horizontal, Theme.spacingMD)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(items) { item in
                        MenuCardSmall(item: item) {
                            showDetail = item
                        }
                    }
                }
                .padding(.horizontal, Theme.spacingMD)
            }
            .contentMargins(.horizontal, 0)
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var topPicks: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Top Picks Today", action: "See All")
                .padding(.horizontal, Theme.spacingMD)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(store.menuItems.sorted { $0.rating > $1.rating }.prefix(6), id: \.id) { item in
                        MenuCardLarge(item: item) {
                            showDetail = item
                        }
                    }
                }
                .padding(.horizontal, Theme.spacingMD)
            }
            .contentMargins(.horizontal, 0)
        }
    }

    private var limitedTimeOffers: some View {
        let limitedItems = store.menuItems.filter { $0.isLimitedTime }
        return Group {
            if !limitedItems.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Limited Time Offers")
                        .padding(.horizontal, Theme.spacingMD)

                    ForEach(limitedItems) { item in
                        LimitedTimeCard(item: item) {
                            showDetail = item
                        }
                        .padding(.horizontal, Theme.spacingMD)
                    }
                }
            }
        }
    }

    private var popularCombos: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Popular Combos", action: "See All")
                .padding(.horizontal, Theme.spacingMD)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(store.menuItems.filter { $0.tags.contains("Popular") }) { item in
                        MenuCardLarge(item: item) {
                            showDetail = item
                        }
                    }
                }
                .padding(.horizontal, Theme.spacingMD)
            }
            .contentMargins(.horizontal, 0)
        }
    }

    private var trendingFilters: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Trending")
                .padding(.horizontal, Theme.spacingMD)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(["🔥 Best Sellers", "💪 High Protein", "🌱 Plant-Based", "⚡ Quick Prep", "🏷️ Under $15"], id: \.self) { filter in
                        ChipView(filter) {}
                    }
                }
                .padding(.horizontal, Theme.spacingMD)
            }
            .contentMargins(.horizontal, 0)
        }
    }

    private var allItems: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "All Items")
                .padding(.horizontal, Theme.spacingMD)

            LazyVStack(spacing: 12) {
                ForEach(store.menuItems) { item in
                    MenuListRow(item: item) {
                        showDetail = item
                    }
                    .padding(.horizontal, Theme.spacingMD)
                }
            }
        }
    }

    private var miniCartBar: some View {
        Button {
        } label: {
            HStack {
                BadgeView(count: cartVM.itemCount)
                Text("View Cart")
                    .font(.subheadline.weight(.bold))
                Spacer()
                Text(cartVM.total, format: .currency(code: "USD"))
                    .font(.subheadline.weight(.bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Theme.accent, in: .capsule)
        }
        .padding(.horizontal, Theme.spacingMD)
        .padding(.bottom, 4)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

struct MenuCardLarge: View {
    let item: MenuItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                Color(.secondarySystemBackground)
                    .frame(width: 200, height: 140)
                    .overlay {
                        AsyncImage(url: URL(string: item.imageURL)) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                SkeletonView()
                            }
                        }
                        .allowsHitTesting(false)
                    }
                    .clipShape(.rect(cornerRadius: Theme.cornerRadiusSmall))

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        RatingView(rating: item.rating, count: item.reviewCount)
                        Spacer()
                        Text(item.price, format: .currency(code: "USD"))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Theme.accent)
                    }
                }
                .padding(10)
            }
            .frame(width: 200)
            .background(Theme.cardBackground)
            .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct MenuCardSmall: View {
    let item: MenuItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Color(.secondarySystemBackground)
                    .frame(width: 150, height: 100)
                    .overlay {
                        AsyncImage(url: URL(string: item.imageURL)) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                SkeletonView()
                            }
                        }
                        .allowsHitTesting(false)
                    }
                    .clipShape(.rect(cornerRadius: Theme.cornerRadiusSmall))

                Text(item.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                Text(item.price, format: .currency(code: "USD"))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.accent)
            }
            .frame(width: 150)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct LimitedTimeCard: View {
    let item: MenuItem
    let onTap: () -> Void
    @State private var timeRemaining: String = ""
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Color(.secondarySystemBackground)
                    .frame(width: 80, height: 80)
                    .overlay {
                        AsyncImage(url: URL(string: item.imageURL)) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                SkeletonView()
                            }
                        }
                        .allowsHitTesting(false)
                    }
                    .clipShape(.rect(cornerRadius: Theme.cornerRadiusSmall))

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("LIMITED")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Theme.danger, in: .capsule)

                        if !timeRemaining.isEmpty {
                            Text(timeRemaining)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Theme.danger)
                        }
                    }

                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)

                    Text(item.price, format: .currency(code: "USD"))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.accent)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(14)
            .background(Theme.cardBackground)
            .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .stroke(Theme.danger.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .onReceive(timer) { _ in
            updateTimer()
        }
        .onAppear { updateTimer() }
    }

    private func updateTimer() {
        guard let end = item.limitedTimeEnd else { return }
        let diff = end.timeIntervalSinceNow
        guard diff > 0 else { timeRemaining = "Expired"; return }
        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60
        timeRemaining = "\(hours)h \(minutes)m left"
    }
}

struct MenuListRow: View {
    let item: MenuItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Color(.secondarySystemBackground)
                    .frame(width: 70, height: 70)
                    .overlay {
                        AsyncImage(url: URL(string: item.imageURL)) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                SkeletonView()
                            }
                        }
                        .allowsHitTesting(false)
                    }
                    .clipShape(.rect(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)

                    Text(item.description)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)

                    HStack {
                        Text(item.price, format: .currency(code: "USD"))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Theme.accent)
                        Spacer()
                        RatingView(rating: item.rating, count: item.reviewCount)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(Theme.cardBackground)
            .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
            .shadow(color: .black.opacity(0.03), radius: 6, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
