import React, { useState } from 'react';
import {
  View,
  Text,
  FlatList,
  StyleSheet,
  Pressable,
  Image,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useDataStore } from '../../state/DataStore';
import { useCartStore } from '../../state/CartStore';
import { colors, spacing, radii } from '../../theme/theme';
import { Button } from '../../theme/components/Button';
import { Card } from '../../theme/components/Card';
import { Chip } from '../../theme/components/Chip';
import { SectionHeader } from '../../theme/components/SectionHeader';
import type { MenuItem, MenuCategory } from '../../models/MenuItem';

const CATEGORY_LABELS: Record<MenuCategory, string> = {
  burgers: 'Burgers',
  pizza: 'Pizza',
  sushi: 'Sushi',
  salads: 'Salads',
  pasta: 'Pasta',
  chicken: 'Chicken',
  seafood: 'Seafood',
  desserts: 'Desserts',
  drinks: 'Drinks',
  sides: 'Sides',
  breakfast: 'Breakfast',
  bowls: 'Bowls',
};

const CATEGORIES: MenuCategory[] = [
  'burgers',
  'pizza',
  'sushi',
  'salads',
  'pasta',
  'chicken',
  'seafood',
  'desserts',
  'drinks',
  'sides',
  'breakfast',
  'bowls',
];

export const CategoriesScreen: React.FC = () => {
  const insets = useSafeAreaInsets();
  const { menuItems } = useDataStore();
  const { addItem } = useCartStore();
  const [selectedCategory, setSelectedCategory] =
    useState<MenuCategory>('burgers');

  const filteredItems = menuItems.filter(
    item => item.category === selectedCategory && item.isAvailable,
  );

  const renderCategoryChip = (category: MenuCategory) => {
    const isSelected = category === selectedCategory;
    return (
      <Pressable
        key={category}
        onPress={() => setSelectedCategory(category)}
        style={[
          styles.categoryChip,
          {
            backgroundColor: isSelected ? colors.accent : colors.cardBackground,
          },
        ]}
      >
        <Text
          style={[
            styles.categoryChipText,
            { color: isSelected ? '#FFFFFF' : colors.textPrimary },
          ]}
        >
          {CATEGORY_LABELS[category]}
        </Text>
      </Pressable>
    );
  };

  const renderMenuItem = ({ item }: { item: MenuItem }) => (
    <Card style={styles.menuItem}>
      {item.imageUrl ? (
        <Image source={{ uri: item.imageUrl }} style={styles.itemImage} />
      ) : (
        <View style={styles.itemImagePlaceholder} />
      )}
      <View style={styles.itemContent}>
        <Text style={styles.itemName}>{item.name}</Text>
        <Text style={styles.itemDescription} numberOfLines={2}>
          {item.description}
        </Text>

        {/* Tags */}
        {item.tags.length > 0 && (
          <View style={styles.tagsContainer}>
            {item.tags.slice(0, 3).map((tag, idx) => (
              <Chip key={idx} label={tag} />
            ))}
          </View>
        )}

        {/* Nutrition info */}
        <View style={styles.nutritionRow}>
          <Text style={styles.nutritionText}>{item.calories} cal</Text>
          <Text style={styles.nutritionText}>•</Text>
          <Text style={styles.nutritionText}>
            {item.nutritionInfo.protein}g protein
          </Text>
          <Text style={styles.nutritionText}>•</Text>
          <Text style={styles.nutritionText}>~{item.prepTimeMinutes} min</Text>
        </View>

        {/* Price and rating */}
        <View style={styles.itemFooter}>
          <View>
            <Text style={styles.itemPrice}>${item.price.toFixed(2)}</Text>
            <Text style={styles.ratingText}>
              ⭐ {item.rating.toFixed(1)} ({item.reviewCount})
            </Text>
          </View>
          <Button
            title="Add to Cart"
            onPress={() => addItem(item, 1)}
            fullWidth={false}
            style={styles.addButton}
          />
        </View>

        {/* Limited time badge */}
        {item.isLimitedTime && (
          <View style={styles.limitedBadge}>
            <Text style={styles.limitedText}>Limited Time</Text>
          </View>
        )}
      </View>
    </Card>
  );

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      <Text style={styles.title}>Menu</Text>

      {/* Category selector */}
      <View style={styles.categoriesContainer}>
        <FlatList
          horizontal
          data={CATEGORIES}
          keyExtractor={cat => cat}
          renderItem={({ item }) => renderCategoryChip(item)}
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.categoriesList}
        />
      </View>

      {/* Menu items */}
      <SectionHeader title={CATEGORY_LABELS[selectedCategory]} />
      <FlatList
        data={filteredItems}
        keyExtractor={item => item.id}
        renderItem={renderMenuItem}
        contentContainerStyle={{ paddingBottom: spacing.xl }}
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Text style={styles.emptyText}>
              No items available in this category
            </Text>
          </View>
        }
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  title: {
    fontSize: 24,
    fontWeight: '800',
    color: colors.textPrimary,
    paddingHorizontal: spacing.lg,
    paddingTop: spacing.lg,
    paddingBottom: spacing.sm,
  },
  categoriesContainer: {
    marginBottom: spacing.md,
  },
  categoriesList: {
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.sm,
  },
  categoryChip: {
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    borderRadius: radii.button,
    marginRight: spacing.sm,
    borderWidth: 1,
    borderColor: colors.border,
  },
  categoryChipText: {
    fontSize: 14,
    fontWeight: '600',
  },
  menuItem: {
    marginHorizontal: spacing.lg,
    marginBottom: spacing.md,
    flexDirection: 'row',
    padding: spacing.md,
  },
  itemImage: {
    width: 100,
    height: 100,
    borderRadius: radii.small,
    marginRight: spacing.md,
  },
  itemImagePlaceholder: {
    width: 100,
    height: 100,
    borderRadius: radii.small,
    marginRight: spacing.md,
    backgroundColor: colors.border,
  },
  itemContent: {
    flex: 1,
  },
  itemName: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.textPrimary,
    marginBottom: 4,
  },
  itemDescription: {
    fontSize: 13,
    color: colors.textSecondary,
    marginBottom: 6,
    lineHeight: 18,
  },
  tagsContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginBottom: 6,
    gap: 4,
  },
  nutritionRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
    gap: 6,
  },
  nutritionText: {
    fontSize: 11,
    color: colors.textSecondary,
  },
  itemFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  itemPrice: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.textPrimary,
  },
  ratingText: {
    fontSize: 12,
    color: colors.textSecondary,
    marginTop: 2,
  },
  addButton: {
    paddingHorizontal: spacing.md,
  },
  limitedBadge: {
    position: 'absolute',
    top: 0,
    right: 0,
    backgroundColor: colors.warning,
    paddingHorizontal: spacing.sm,
    paddingVertical: 4,
    borderRadius: radii.small,
  },
  limitedText: {
    fontSize: 10,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  emptyContainer: {
    padding: spacing.xl,
    alignItems: 'center',
  },
  emptyText: {
    fontSize: 14,
    color: colors.textSecondary,
  },
});
