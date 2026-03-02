import SwiftUI

struct ContentView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(DataStore.self) private var store

    var body: some View {
        Group {
            if authVM.isAuthenticated, let user = authVM.currentUser {
                switch user.role {
                case .customer:
                    CustomerTabView()
                case .admin:
                    AdminTabView()
                case .driver:
                    DriverTabView()
                }
            } else {
                LoginView()
            }
        }
        .animation(.spring(duration: 0.4), value: authVM.isAuthenticated)
        .task {
            await authVM.initialize()
        }
        .onChange(of: authVM.isAuthenticated) { _, newValue in
            if newValue, let user = authVM.currentUser {
                Task {
                    await store.loadFromSupabase(userId: user.id, role: user.role)
                    store.subscribeToRealtimeUpdates()
                }
            } else {
                store.unsubscribeFromRealtime()
            }
        }
    }
}
