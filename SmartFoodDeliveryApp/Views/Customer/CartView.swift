import SwiftUI

struct CartView: View {
    @Environment(CartViewModel.self) private var cartVM
    @Environment(DataStore.self) private var store
    @State private var promoInput: String = ""
    @State private var showCheckout: Bool = false
    @State private var showReceiptDetail: Bool = false

    var body: some View {
        @Bindable var cart = cartVM
        NavigationStack {
            Group {
                if cartVM.isEmpty {
                    ContentUnavailableView("Your Cart is Empty", systemImage: "cart", description: Text("Add some delicious items to get started"))
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            cartItems

                            upsellSection

                            promoSection

                            optimizeCartSection

                            receiptSection

                            tipSection

                            AccentButton("Proceed to Checkout", icon: "arrow.right") {
                                showCheckout = true
                            }
                            .padding(.horizontal, Theme.spacingMD)
                        }
                        .padding(.vertical, Theme.spacingMD)
                    }
                }
            }
            .background(Theme.background)
            .navigationTitle("Cart")
            .toolbar {
                if !cartVM.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear") { cartVM.clear() }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.danger)
                    }
                }
            }
            .sheet(isPresented: $showCheckout) {
                CheckoutView()
            }
        }
    }

    private var cartItems: some View {
        VStack(spacing: 10) {
            ForEach(cartVM.items) { item in
                CartItemRow(item: item)
            }
        }
        .padding(.horizontal, Theme.spacingMD)
    }

    private var upsellSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Frequently Bought Together")
                .padding(.horizontal, Theme.spacingMD)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.menuItems.filter { item in
                        !cartVM.items.contains { $0.menuItem.id == item.id }
                    }.prefix(4)) { item in
                        UpsellCard(item: item)
                    }
                }
                .padding(.horizontal, Theme.spacingMD)
            }
            .contentMargins(.horizontal, 0)
        }
    }

    private var promoSection: some View {
        @Bindable var cart = cartVM
        return VStack(alignment: .leading, spacing: 8) {
            Text("Promo Code")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 10) {
                TextField("Enter code", text: $promoInput)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(.rect(cornerRadius: 10))

                Button("Apply") {
                    cartVM.applyPromo(promoInput)
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Theme.accent, in: .capsule)
            }

            if !cartVM.promoCode.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.success)
                    Text("\(cartVM.promoCode.uppercased()) applied")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.success)
                }
            }
        }
        .padding(Theme.spacingMD)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
        .padding(.horizontal, Theme.spacingMD)
    }

    private var optimizeCartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                    .foregroundStyle(Theme.accent)
                Text("Optimize Cart")
                    .font(.subheadline.weight(.bold))
            }

            HStack(spacing: 10) {
                OptimizeChip(title: "Cheaper", icon: "dollarsign.circle") {}
                OptimizeChip(title: "Healthier", icon: "heart.circle") {}
                OptimizeChip(title: "Bigger", icon: "arrow.up.circle") {}
            }
        }
        .padding(Theme.spacingMD)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
        .padding(.horizontal, Theme.spacingMD)
    }

    private var receiptSection: some View {
        VStack(spacing: 10) {
            DisclosureGroup(isExpanded: $showReceiptDetail) {
                VStack(spacing: 8) {
                    receiptRow("Subtotal", cartVM.subtotal)
                    receiptRow("Tax", cartVM.tax)
                    receiptRow("Delivery Fee", cartVM.deliveryFee)
                    if cartVM.tipAmount > 0 {
                        receiptRow("Tip", cartVM.tipAmount)
                    }
                    if cartVM.promoDiscount > 0 {
                        HStack {
                            Text("Discount")
                                .font(.subheadline)
                                .foregroundStyle(Theme.success)
                            Spacer()
                            Text("-\(cartVM.promoDiscount, format: .currency(code: "USD"))")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Theme.success)
                        }
                    }
                }
                .padding(.top, 8)
            } label: {
                HStack {
                    Text("Order Total")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text(cartVM.total, format: .currency(code: "USD"))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.accent)
                }
            }
            .tint(Theme.textSecondary)

            if cartVM.deliveryFee == 0 {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Theme.success)
                    Text("Free delivery on orders over $35!")
                        .font(.caption)
                        .foregroundStyle(Theme.success)
                }
            }
        }
        .padding(Theme.spacingMD)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
        .padding(.horizontal, Theme.spacingMD)
    }

    private var tipSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tip your driver")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 10) {
                ForEach([TipOption.none, .ten, .fifteen, .twenty], id: \.label) { tip in
                    Button {
                        cartVM.selectedTip = tip
                    } label: {
                        Text(tip.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(cartVM.selectedTip == tip ? .white : Theme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(cartVM.selectedTip == tip ? Theme.accent : Color(.secondarySystemBackground))
                            .clipShape(.capsule)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .padding(Theme.spacingMD)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
        .padding(.horizontal, Theme.spacingMD)
    }

    private func receiptRow(_ label: String, _ amount: Double) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(amount, format: .currency(code: "USD"))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.textPrimary)
        }
    }
}

struct CartItemRow: View {
    let item: CartItem
    @Environment(CartViewModel.self) private var cartVM

    var body: some View {
        HStack(spacing: 12) {
            Color(.secondarySystemBackground)
                .frame(width: 64, height: 64)
                .overlay {
                    AsyncImage(url: URL(string: item.menuItem.imageURL)) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        }
                    }
                    .allowsHitTesting(false)
                }
                .clipShape(.rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.menuItem.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                Text(item.itemTotal, format: .currency(code: "USD"))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.accent)
            }

            Spacer()

            HStack(spacing: 12) {
                Button {
                    cartVM.updateQuantity(item, quantity: item.quantity - 1)
                } label: {
                    Image(systemName: item.quantity == 1 ? "trash" : "minus")
                        .font(.caption.weight(.bold))
                        .frame(width: 28, height: 28)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Circle())
                }

                Text("\(item.quantity)")
                    .font(.subheadline.weight(.bold))
                    .frame(minWidth: 20)

                Button {
                    cartVM.updateQuantity(item, quantity: item.quantity + 1)
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                        .frame(width: 28, height: 28)
                        .background(Theme.accent.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            .foregroundStyle(Theme.textPrimary)
        }
        .padding(12)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
    }
}

struct UpsellCard: View {
    let item: MenuItem
    @Environment(CartViewModel.self) private var cartVM

    var body: some View {
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
            } label: {
                Text("+ \(item.price, format: .currency(code: "USD"))")
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

struct OptimizeChip: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Theme.accent.opacity(0.1))
            .foregroundStyle(Theme.accent)
            .clipShape(.capsule)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
