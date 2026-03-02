import SwiftUI

struct DriverTabView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Available", systemImage: "list.bullet.circle.fill", value: 0) {
                DriverAvailableView()
            }

            Tab("Active", systemImage: "car.fill", value: 1) {
                DriverActiveView()
            }

            Tab("Earnings", systemImage: "dollarsign.circle.fill", value: 2) {
                DriverEarningsView()
            }

            Tab("Profile", systemImage: "person.fill", value: 3) {
                DriverProfileView()
            }
        }
        .tint(Theme.accent)
    }
}
