import SwiftUI

struct CustomerTabView: View {
    @State private var selectedTab: Int = 0
    @Environment(CartViewModel.self) private var cartVM

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: 0) {
                CustomerHomeView()
            }

            Tab("Menu", systemImage: "menucard.fill", value: 1) {
                CategoryView()
            }

            Tab("Orders", systemImage: "bag.fill", value: 2) {
                CustomerOrdersView()
            }

            Tab("Cart", systemImage: "cart.fill", value: 3) {
                CartView()
            }
            .badge(cartVM.itemCount)

            Tab("Profile", systemImage: "person.fill", value: 4) {
                CustomerProfileView()
            }
        }
        .tint(Theme.accent)
    }
}
