import SwiftUI

struct CategoryView: View {
    @Environment(DataStore.self) private var store
    @State private var selectedCategory: MenuCategory?
    @State private var searchText: String = ""
    @State private var sortOption: SortOption = .popular
    @State private var showFilter: Bool = false
    @State private var showDetail: MenuItem?

    private var filteredItems: [MenuItem] {
        var items = store.menuItems
        if let category = selectedCategory {
            items = items.filter { $0.category == category }
        }
        if !searchText.isEmpty {
            items = items.filter { $0.name.localizedStandardContains(searchText) || $0.description.localizedStandardContains(searchText) }
        }
        switch sortOption {
        case .popular: items.sort { $0.rating > $1.rating }
        case .priceLow: items.sort { $0.price < $1.price }
        case .priceHigh: items.sort { $0.price > $1.price }
        case .fastest: items.sort { $0.prepTimeMinutes < $1.prepTimeMinutes }
        case .newest: break
        }
        return items
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ChipView("All", isSelected: selectedCategory == nil) {
                            withAnimation { selectedCategory = nil }
                        }
                        ForEach(MenuCategory.allCases) { cat in
                            ChipView("\(cat.icon) \(cat.rawValue)", isSelected: selectedCategory == cat) {
                                withAnimation { selectedCategory = cat }
                            }
                        }
                    }
                    .padding(.horizontal, Theme.spacingMD)
                    .padding(.vertical, 12)
                }
                .contentMargins(.horizontal, 0)

                HStack {
                    Text("\(filteredItems.count) items")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button {
                                sortOption = option
                            } label: {
                                if sortOption == option {
                                    Label(option.rawValue, systemImage: "checkmark")
                                } else {
                                    Text(option.rawValue)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                            Text(sortOption.rawValue)
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.accent)
                    }
                }
                .padding(.horizontal, Theme.spacingMD)
                .padding(.bottom, 8)

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredItems) { item in
                            MenuListRow(item: item) {
                                showDetail = item
                            }
                        }
                    }
                    .padding(.horizontal, Theme.spacingMD)
                    .padding(.bottom, 20)
                }
            }
            .background(Theme.background)
            .navigationTitle("Menu")
            .searchable(text: $searchText, prompt: "Search menu...")
            .sheet(item: $showDetail) { item in
                MenuItemDetailView(item: item)
            }
        }
    }
}

nonisolated enum SortOption: String, CaseIterable, Sendable {
    case popular = "Most Popular"
    case priceLow = "Price: Low to High"
    case priceHigh = "Price: High to Low"
    case fastest = "Fastest Prep"
    case newest = "Newest"
}
