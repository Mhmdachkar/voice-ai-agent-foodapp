import SwiftUI

struct MenuItemDetailView: View {
    let item: MenuItem
    @Environment(CartViewModel.self) private var cartVM
    @Environment(\.dismiss) private var dismiss
    @State private var quantity: Int = 1
    @State private var showNutrition: Bool = false
    @State private var addedToCart: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    Color(.secondarySystemBackground)
                        .frame(height: 260)
                        .overlay {
                            AsyncImage(url: URL(string: item.imageURL)) { phase in
                                if let image = phase.image {
                                    image.resizable().aspectRatio(contentMode: .fill)
                                } else {
                                    SkeletonView()
                                }
                            }
                            .allowsHitTesting(false)
                        }
                        .clipShape(.rect(cornerRadius: 0))

                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(item.category.icon)
                                Text(item.category.rawValue)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Theme.accent)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Theme.accent.opacity(0.1))
                            .clipShape(.capsule)

                            Text(item.name)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(Theme.textPrimary)

                            HStack(spacing: 16) {
                                RatingView(rating: item.rating, count: item.reviewCount)
                                Label("\(item.prepTimeMinutes) min", systemImage: "clock")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                                Label("\(item.calories) cal", systemImage: "flame")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }

                        Text(item.description)
                            .font(.body)
                            .foregroundStyle(Theme.textSecondary)
                            .lineSpacing(4)

                        if !item.modifierGroups.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Customize")
                                    .font(.headline)
                                    .foregroundStyle(Theme.textPrimary)

                                ForEach(item.modifierGroups) { group in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(group.name)
                                                .font(.subheadline.weight(.semibold))
                                            if group.required {
                                                Text("Required")
                                                    .font(.caption2.weight(.bold))
                                                    .foregroundStyle(.white)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Theme.accent, in: .capsule)
                                            }
                                        }

                                        ForEach(group.options) { option in
                                            HStack {
                                                Image(systemName: "circle")
                                                    .font(.caption)
                                                    .foregroundStyle(Theme.textSecondary)
                                                Text(option.name)
                                                    .font(.subheadline)
                                                Spacer()
                                                if option.priceAdjustment != 0 {
                                                    Text(option.priceAdjustment > 0 ? "+\(option.priceAdjustment, specifier: "$%.2f")" : "\(option.priceAdjustment, specifier: "$%.2f")")
                                                        .font(.caption.weight(.medium))
                                                        .foregroundStyle(Theme.textSecondary)
                                                }
                                            }
                                            .padding(.vertical, 4)
                                        }
                                    }
                                    .padding(14)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(.rect(cornerRadius: Theme.cornerRadiusSmall))
                                }
                            }
                        }

                        if !item.allergens.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Allergens")
                                    .font(.headline)
                                HStack(spacing: 8) {
                                    ForEach(item.allergens, id: \.self) { allergen in
                                        Text(allergen)
                                            .font(.caption.weight(.medium))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Theme.warning.opacity(0.15))
                                            .foregroundStyle(Theme.warning)
                                            .clipShape(.capsule)
                                    }
                                }
                            }
                        }

                        DisclosureGroup(isExpanded: $showNutrition) {
                            VStack(spacing: 10) {
                                nutritionRow("Calories", "\(item.nutritionInfo.calories)")
                                nutritionRow("Protein", "\(item.nutritionInfo.protein)g")
                                nutritionRow("Carbs", "\(item.nutritionInfo.carbs)g")
                                nutritionRow("Fat", "\(item.nutritionInfo.fat)g")
                                nutritionRow("Fiber", "\(item.nutritionInfo.fiber)g")
                                nutritionRow("Sugar", "\(item.nutritionInfo.sugar)g")
                            }
                            .padding(.top, 8)
                        } label: {
                            Text("Nutrition Information")
                                .font(.headline)
                                .foregroundStyle(Theme.textPrimary)
                        }
                        .tint(Theme.accent)
                    }
                    .padding(Theme.spacingMD)
                }
                .padding(.bottom, 100)
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 16) {
                    HStack(spacing: 16) {
                        Button { if quantity > 1 { quantity -= 1 } } label: {
                            Image(systemName: "minus")
                                .font(.body.weight(.bold))
                                .frame(width: 36, height: 36)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(Circle())
                        }
                        Text("\(quantity)")
                            .font(.headline)
                            .frame(minWidth: 24)
                        Button { quantity += 1 } label: {
                            Image(systemName: "plus")
                                .font(.body.weight(.bold))
                                .frame(width: 36, height: 36)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(Circle())
                        }
                    }

                    Button {
                        cartVM.addItem(item, quantity: quantity)
                        addedToCart = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Text(addedToCart ? "Added!" : "Add to Cart")
                                .font(.body.weight(.bold))
                            Text("•")
                            Text((item.price * Double(quantity)), format: .currency(code: "USD"))
                                .font(.body.weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(addedToCart ? Theme.success : Theme.accent, in: .capsule)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .sensoryFeedback(.impact(weight: .medium), trigger: addedToCart)
                }
                .padding(.horizontal, Theme.spacingMD)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
            }
        }
    }

    private func nutritionRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
        }
    }
}
