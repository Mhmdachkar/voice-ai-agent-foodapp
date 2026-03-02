import SwiftUI

@Observable
final class CartViewModel {
    var items: [CartItem] = []
    var promoCode: String = ""
    var promoDiscount: Double = 0
    var deliveryNotes: String = ""
    var selectedTip: TipOption = .fifteen
    var showToast: Bool = false
    var toastMessage: String = ""

    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var subtotal: Double {
        items.reduce(0) { $0 + $1.itemTotal }
    }

    var tax: Double {
        subtotal * 0.0875
    }

    var deliveryFee: Double {
        subtotal > 35 ? 0 : 3.99
    }

    var tipAmount: Double {
        switch selectedTip {
        case .none: 0
        case .ten: subtotal * 0.10
        case .fifteen: subtotal * 0.15
        case .twenty: subtotal * 0.20
        case .custom(let amount): amount
        }
    }

    var total: Double {
        subtotal + tax + deliveryFee + tipAmount - promoDiscount
    }

    var isEmpty: Bool { items.isEmpty }

    func addItem(_ menuItem: MenuItem, quantity: Int = 1, modifiers: [String: [String]] = [:], instructions: String = "") {
        if let index = items.firstIndex(where: { $0.menuItem.id == menuItem.id && $0.selectedModifiers == modifiers }) {
            items[index].quantity += quantity
        } else {
            items.append(CartItem(menuItem: menuItem, quantity: quantity, selectedModifiers: modifiers, specialInstructions: instructions))
        }
        showToastMessage("\(menuItem.name) added to cart")
        EventBus.shared.publish(.cartUpdated)
    }

    func removeItem(_ item: CartItem) {
        items.removeAll { $0.id == item.id }
        EventBus.shared.publish(.cartUpdated)
    }

    func updateQuantity(_ item: CartItem, quantity: Int) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        if quantity <= 0 {
            items.remove(at: index)
        } else {
            items[index].quantity = quantity
        }
        EventBus.shared.publish(.cartUpdated)
    }

    func applyPromo(_ code: String) {
        if code.uppercased() == "SAVE10" {
            promoDiscount = subtotal * 0.10
            promoCode = code
            showToastMessage("10% discount applied!")
        } else if code.uppercased() == "FREE5" {
            promoDiscount = 5.0
            promoCode = code
            showToastMessage("$5 discount applied!")
        } else {
            showToastMessage("Invalid promo code")
        }
    }

    func clear() {
        items.removeAll()
        promoCode = ""
        promoDiscount = 0
        deliveryNotes = ""
        selectedTip = .fifteen
    }

    private func showToastMessage(_ message: String) {
        toastMessage = message
        showToast = true
    }
}

nonisolated enum TipOption: Equatable, Sendable {
    case none
    case ten
    case fifteen
    case twenty
    case custom(Double)

    var label: String {
        switch self {
        case .none: "No Tip"
        case .ten: "10%"
        case .fifteen: "15%"
        case .twenty: "20%"
        case .custom: "Custom"
        }
    }
}
