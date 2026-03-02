import SwiftUI

struct AdminTabView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Dashboard", systemImage: "square.grid.2x2.fill", value: 0) {
                AdminDashboardView()
            }

            Tab("Orders", systemImage: "list.clipboard.fill", value: 1) {
                AdminOrdersView()
            }

            Tab("Menu", systemImage: "menucard.fill", value: 2) {
                AdminMenuView()
            }

            Tab("Dispatch", systemImage: "car.2.fill", value: 3) {
                AdminDispatchView()
            }

            Tab("Settings", systemImage: "gearshape.fill", value: 4) {
                AdminSettingsView()
            }
        }
        .tint(Theme.accent)
    }
}
