import SwiftUI

@main
struct SmartFoodDeliveryAppApp: App {
    @State private var authVM = AuthViewModel()
    @State private var cartVM = CartViewModel()
    @State private var dataStore = DataStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authVM)
                .environment(cartVM)
                .environment(dataStore)
        }
    }
}
