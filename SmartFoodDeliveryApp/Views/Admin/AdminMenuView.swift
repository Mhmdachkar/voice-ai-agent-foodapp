import SwiftUI

struct AdminMenuView: View {
    @Environment(DataStore.self) private var store
    @State private var searchText: String = ""
    @State private var selectedCategory: MenuCategory?

    private var filteredItems: [MenuItem] {
        var items = store.menuItems
        if let cat = selectedCategory {
            items = items.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            items = items.filter { $0.name.localizedStandardContains(searchText) }
        }
        return items
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ChipView("All", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        ForEach(MenuCategory.allCases) { cat in
                            ChipView(cat.rawValue, isSelected: selectedCategory == cat) {
                                selectedCategory = cat
                            }
                        }
                    }
                    .padding(.horizontal, Theme.spacingMD)
                    .padding(.vertical, 10)
                }
                .contentMargins(.horizontal, 0)

                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredItems) { item in
                            AdminMenuItemRow(item: item)
                        }
                    }
                    .padding(.horizontal, Theme.spacingMD)
                    .padding(.bottom, 20)
                }
            }
            .background(Theme.background)
            .navigationTitle("Menu Management")
            .searchable(text: $searchText, prompt: "Search items...")
        }
    }
}

struct AdminMenuItemRow: View {
    let item: MenuItem
    @Environment(DataStore.self) private var store

    var body: some View {
        HStack(spacing: 12) {
            Color(.secondarySystemBackground)
                .frame(width: 56, height: 56)
                .overlay {
                    AsyncImage(url: URL(string: item.imageURL)) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        }
                    }
                    .allowsHitTesting(false)
                }
                .clipShape(.rect(cornerRadius: 10))
                .opacity(item.isAvailable ? 1 : 0.5)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(item.isAvailable ? Theme.textPrimary : Theme.textSecondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(item.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    Text("•")
                        .foregroundStyle(Theme.textSecondary)
                    Text(item.price, format: .currency(code: "USD"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.accent)
                }
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { item.isAvailable },
                set: { _ in store.toggleMenuItemAvailability(item.id) }
            ))
            .tint(Theme.success)
            .labelsHidden()
        }
        .padding(12)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: Theme.cornerRadiusMedium))
    }
}
