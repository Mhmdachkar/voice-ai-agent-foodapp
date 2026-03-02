import SwiftUI

struct CheckoutView: View {
    @Environment(CartViewModel.self) private var cartVM
    @Environment(DataStore.self) private var store
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep: Int = 0
    @State private var street: String = ""
    @State private var city: String = ""
    @State private var zipCode: String = ""
    @State private var deliveryNotes: String = ""
    @State private var paymentMethod: String = "Apple Pay"
    @State private var isPlacing: Bool = false
    @State private var orderPlaced: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                stepIndicator

                TabView(selection: $currentStep) {
                    addressStep.tag(0)
                    paymentStep.tag(1)
                    reviewStep.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(duration: 0.3), value: currentStep)

                bottomBar
            }
            .background(Theme.background)
            .navigationTitle("Checkout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .fullScreenCover(isPresented: $orderPlaced) {
                OrderConfirmationView { dismiss() }
            }
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 0) {
            ForEach(0..<3) { step in
                HStack(spacing: 6) {
                    Circle()
                        .fill(step <= currentStep ? Theme.accent : Theme.border)
                        .frame(width: 28, height: 28)
                        .overlay {
                            if step < currentStep {
                                Image(systemName: "checkmark")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                            } else {
                                Text("\(step + 1)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(step == currentStep ? .white : Theme.textSecondary)
                            }
                        }
                    if step < 2 {
                        Rectangle()
                            .fill(step < currentStep ? Theme.accent : Theme.border)
                            .frame(height: 2)
                    }
                }
            }
        }
        .padding(.horizontal, Theme.spacingLG)
        .padding(.vertical, Theme.spacingMD)
    }

    private var addressStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Delivery Address")
                    .font(.title3.weight(.bold))

                VStack(spacing: 12) {
                    TextField("Street address", text: $street)
                        .textFieldStyle(.plain)
                        .padding(14)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(.rect(cornerRadius: 12))

                    HStack(spacing: 12) {
                        TextField("City", text: $city)
                            .textFieldStyle(.plain)
                            .padding(14)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(.rect(cornerRadius: 12))

                        TextField("ZIP", text: $zipCode)
                            .textFieldStyle(.plain)
                            .keyboardType(.numberPad)
                            .padding(14)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(.rect(cornerRadius: 12))
                            .frame(width: 100)
                    }

                    TextField("Delivery notes (optional)", text: $deliveryNotes, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(3...5)
                        .padding(14)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(.rect(cornerRadius: 12))
                }
            }
            .padding(Theme.spacingMD)
        }
        .onAppear {
            if let addr = authVM.currentUser?.address {
                street = addr.street
                city = addr.city
                zipCode = addr.zip
            }
        }
    }

    private var paymentStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Payment Method")
                    .font(.title3.weight(.bold))

                ForEach(["Apple Pay", "Credit Card", "Cash on Delivery"], id: \.self) { method in
                    Button {
                        paymentMethod = method
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: method == "Apple Pay" ? "apple.logo" : method == "Credit Card" ? "creditcard.fill" : "banknote.fill")
                                .font(.title3)
                                .foregroundStyle(Theme.accent)
                                .frame(width: 44, height: 44)
                                .background(Theme.accent.opacity(0.1))
                                .clipShape(Circle())

                            Text(method)
                                .font(.body.weight(.medium))
                                .foregroundStyle(Theme.textPrimary)

                            Spacer()

                            Image(systemName: paymentMethod == method ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(paymentMethod == method ? Theme.accent : Theme.border)
                        }
                        .padding(16)
                        .background(Theme.cardBackground)
                        .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                                .stroke(paymentMethod == method ? Theme.accent : Theme.border, lineWidth: paymentMethod == method ? 2 : 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(Theme.spacingMD)
        }
    }

    private var reviewStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Order Summary")
                    .font(.title3.weight(.bold))

                VStack(spacing: 10) {
                    ForEach(cartVM.items) { item in
                        HStack {
                            Text("\(item.quantity)x")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Theme.accent)
                            Text(item.menuItem.name)
                                .font(.subheadline)
                            Spacer()
                            Text(item.itemTotal, format: .currency(code: "USD"))
                                .font(.subheadline.weight(.medium))
                        }
                    }
                }
                .padding(16)
                .background(Theme.cardBackground)
                .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))

                VStack(spacing: 8) {
                    summaryRow("Subtotal", cartVM.subtotal)
                    summaryRow("Tax", cartVM.tax)
                    summaryRow("Delivery", cartVM.deliveryFee)
                    summaryRow("Tip", cartVM.tipAmount)
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
                    Divider()
                    HStack {
                        Text("Total")
                            .font(.headline)
                        Spacer()
                        Text(cartVM.total, format: .currency(code: "USD"))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Theme.accent)
                    }
                }
                .padding(16)
                .background(Theme.cardBackground)
                .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))

                HStack(spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(Theme.accent)
                    VStack(alignment: .leading) {
                        Text("Delivering to")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                        Text("\(street), \(city) \(zipCode)")
                            .font(.subheadline.weight(.medium))
                    }
                }
                .padding(16)
                .background(Theme.cardBackground)
                .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))

                HStack(spacing: 12) {
                    Image(systemName: "creditcard.fill")
                        .foregroundStyle(Theme.accent)
                    VStack(alignment: .leading) {
                        Text("Payment")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                        Text(paymentMethod)
                            .font(.subheadline.weight(.medium))
                    }
                }
                .padding(16)
                .background(Theme.cardBackground)
                .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
            }
            .padding(Theme.spacingMD)
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                if currentStep > 0 {
                    Button {
                        withAnimation { currentStep -= 1 }
                    } label: {
                        Text("Back")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .frame(height: 52)
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemBackground), in: .capsule)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }

                Button {
                    if currentStep < 2 {
                        withAnimation { currentStep += 1 }
                    } else {
                        placeOrder()
                    }
                } label: {
                    HStack {
                        if isPlacing {
                            ProgressView().tint(.white)
                        } else {
                            Text(currentStep == 2 ? "Place Order" : "Continue")
                                .font(.body.weight(.bold))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(height: 52)
                    .frame(maxWidth: .infinity)
                    .background(Theme.accent, in: .capsule)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(isPlacing)
            }
            .padding(Theme.spacingMD)
        }
        .background(.ultraThinMaterial)
    }

    private func summaryRow(_ label: String, _ amount: Double) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(amount, format: .currency(code: "USD")).font(.subheadline.weight(.medium))
        }
    }

    private func placeOrder() {
        guard let user = authVM.currentUser else { return }
        isPlacing = true

        let address = DeliveryAddress(street: street, city: city, zip: zipCode, notes: deliveryNotes)

        if authVM.authService.isAuthenticated {
            Task {
                let orderId = await store.placeOrderViaSupabase(
                    userId: user.id,
                    customerName: user.name,
                    items: cartVM.items,
                    address: address,
                    notes: deliveryNotes,
                    promoCode: cartVM.promoCode.isEmpty ? nil : cartVM.promoCode,
                    tip: cartVM.tipAmount,
                    paymentMethod: paymentMethod.lowercased().replacingOccurrences(of: " ", with: "_")
                )
                if orderId != nil {
                    cartVM.clear()
                    orderPlaced = true
                }
                isPlacing = false
            }
        } else {
            let order = Order(
                customerId: user.id,
                customerName: user.name,
                items: cartVM.items,
                subtotal: cartVM.subtotal,
                tax: cartVM.tax,
                deliveryFee: cartVM.deliveryFee,
                tip: cartVM.tipAmount,
                deliveryAddress: address,
                promoCode: cartVM.promoCode.isEmpty ? nil : cartVM.promoCode,
                promoDiscount: cartVM.promoDiscount
            )

            Task {
                try? await Task.sleep(for: .seconds(1.5))
                store.placeOrder(order)
                cartVM.clear()
                isPlacing = false
                orderPlaced = true
            }
        }
    }
}

struct OrderConfirmationView: View {
    let onDismiss: () -> Void
    @State private var appeared: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Theme.success)
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)

            VStack(spacing: 8) {
                Text("Order Confirmed!")
                    .font(.title.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Your food is being prepared")
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer()

            AccentButton("Done", icon: "house.fill") {
                onDismiss()
            }
            .padding(.horizontal, Theme.spacingLG)
        }
        .padding(Theme.spacingMD)
        .background(Theme.background)
        .onAppear {
            withAnimation(.spring(duration: 0.6)) {
                appeared = true
            }
        }
    }
}
