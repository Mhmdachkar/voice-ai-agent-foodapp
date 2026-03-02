import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Pressable,
  Image,
  ScrollView,
  TextInput,
  Platform,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useCartStore } from '../../state/CartStore';
import { useUpsellStore } from '../../state/UpsellStore';
import { useDataStore } from '../../state/DataStore';
import { FreeDeliveryProgress } from '../../components/FreeDeliveryProgress';
import { SavingsCard } from '../../components/SavingsCard';
import type { CartItem } from '../../models/Cart';

// Cart design tokens
const CART_COLORS = {
  background: '#FFFFFF',
  primary: '#FF8C1A',
  primaryLight: '#FFF3E6',
  textPrimary: '#111111',
  textSecondary: '#777777',
  border: '#EEEEEE',
  error: '#E74C3C',
  success: '#2ECC71',
  white: '#FFFFFF',
  grayLight: '#F5F5F5',
};

type PromoState = 'idle' | 'input' | 'applied';

export const CartScreen: React.FC = () => {
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const {
    items,
    subtotal,
    tax,
    deliveryFee,
    total,
    promoCode,
    promoDiscount,
    isEmpty,
    removeItem,
    updateQuantity,
    clear,
    addItem,
    applyPromo,
    removePromo,
  } = useCartStore();
  const { menuItems } = useDataStore();
  const { suggestions, generateSuggestions, dismiss } = useUpsellStore();

  const [promoState, setPromoState] = useState<PromoState>('idle');
  const [promoInput, setPromoInput] = useState('');

  useEffect(() => {
    if (items.length > 0 && menuItems.length > 0) {
      generateSuggestions(items, menuItems);
    }
  }, [items.length, menuItems.length]);

  useEffect(() => {
    if (promoCode && promoDiscount > 0) {
      setPromoState('applied');
    } else {
      setPromoState('idle');
    }
  }, [promoCode, promoDiscount]);

  const handleApplyPromo = () => {
    if (promoInput.trim()) {
      applyPromo(promoInput.trim());
      setPromoInput('');
      setPromoState('applied');
    }
  };

  const renderCartItem = ({ item }: { item: CartItem }) => {
    const unitPrice =
      item.menuItem.price +
      Object.values(item.selectedModifiers)
        .flat()
        .reduce((sum, optionId) => {
          const group = item.menuItem.modifierGroups.find(g =>
            g.options.some(o => o.id === optionId),
          );
          const option = group?.options.find(o => o.id === optionId);
          return sum + (option?.priceAdjustment ?? 0);
        }, 0);

    return (
      <View style={styles.cartItemCard}>
        {item.menuItem.imageUrl ? (
          <Image
            source={{ uri: item.menuItem.imageUrl }}
            style={styles.cartItemImage}
            resizeMode="cover"
          />
        ) : (
          <View style={[styles.cartItemImage, styles.imagePlaceholder]} />
        )}
        <View style={styles.cartItemCenter}>
          <Text style={styles.cartItemName} numberOfLines={1}>
            {item.menuItem.name}
          </Text>
          <Text style={styles.cartItemPrice}>${unitPrice.toFixed(2)}</Text>
          <View style={styles.quantityRow}>
            <Pressable
              style={styles.qtyBtn}
              onPress={() => updateQuantity(item, item.quantity - 1)}
            >
              <Text style={styles.qtyBtnText}>−</Text>
            </Pressable>
            <Text style={styles.qtyText}>{item.quantity}</Text>
            <Pressable
              style={styles.qtyBtn}
              onPress={() => updateQuantity(item, item.quantity + 1)}
            >
              <Text style={styles.qtyBtnText}>+</Text>
            </Pressable>
          </View>
        </View>
        <Pressable style={styles.deleteBtn} onPress={() => removeItem(item)}>
          <Ionicons name="trash-outline" size={18} color={CART_COLORS.error} />
        </Pressable>
      </View>
    );
  };

  // Empty state
  if (isEmpty()) {
    return (
      <View style={[styles.container, { paddingTop: insets.top }]}>
        <View style={styles.header}>
          <Text style={styles.headerTitle}>My Cart</Text>
        </View>
        <View style={styles.emptyState}>
          <View style={styles.emptyIconWrapper}>
            <Ionicons
              name="bag-outline"
              size={48}
              color={CART_COLORS.textSecondary}
            />
          </View>
          <Text style={styles.emptyTitle}>Your cart is empty</Text>
          <Text style={styles.emptyMessage}>
            Add some delicious food to get started
          </Text>
          <Pressable
            style={styles.browseBtn}
            onPress={() => router.push('/customer/home')}
          >
            <Text style={styles.browseBtnText}>Browse Menu</Text>
          </Pressable>
        </View>
      </View>
    );
  }

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>My Cart</Text>
        <Pressable onPress={clear}>
          <Text style={styles.clearText}>Clear all</Text>
        </Pressable>
      </View>

      <ScrollView
        style={styles.scroll}
        contentContainerStyle={[
          styles.scrollContent,
          { paddingBottom: insets.bottom + 120 },
        ]}
        showsVerticalScrollIndicator={false}
      >
        {/* Free Delivery Progress */}
        <FreeDeliveryProgress subtotal={subtotal()} />

        {/* Cart items */}
        {items.map(item => (
          <View key={item.id}>{renderCartItem({ item })}</View>
        ))}

        {/* Upsell section */}
        {suggestions.length > 0 && (
          <View style={styles.upsellSection}>
            <Text style={styles.upsellTitle}>Add something extra?</Text>
            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={false}
              contentContainerStyle={styles.upsellScroll}
            >
              {suggestions.map(s => (
                <View key={s.item.id} style={styles.upsellCard}>
                  {s.item.imageUrl ? (
                    <Image
                      source={{ uri: s.item.imageUrl }}
                      style={styles.upsellImage}
                      resizeMode="cover"
                    />
                  ) : (
                    <View style={[styles.upsellImage, styles.upsellImgPlaceholder]}>
                      <Ionicons
                        name="restaurant-outline"
                        size={24}
                        color={CART_COLORS.textSecondary}
                      />
                    </View>
                  )}
                  <Text style={styles.upsellName} numberOfLines={1}>
                    {s.item.name}
                  </Text>
                  <View style={styles.upsellBottom}>
                    <Text style={styles.upsellPrice}>
                      ${s.item.price.toFixed(2)}
                    </Text>
                    <Pressable
                      style={styles.upsellAddBtn}
                      onPress={() => {
                        addItem(s.item, 1);
                        dismiss(s.item.id);
                      }}
                    >
                      <Text style={styles.upsellAddText}>+</Text>
                    </Pressable>
                  </View>
                </View>
              ))}
            </ScrollView>
          </View>
        )}

        {/* Promo code section */}
        <View style={styles.promoSection}>
          {promoState === 'idle' && !promoCode && (
            <Pressable
              style={styles.promoButton}
              onPress={() => setPromoState('input')}
            >
              <Ionicons
                name="pricetag"
                size={18}
                color={CART_COLORS.primary}
                style={styles.promoIcon}
              />
              <Text style={styles.promoButtonText}>Add promo code</Text>
              <Ionicons
                name="chevron-forward"
                size={18}
                color={CART_COLORS.textSecondary}
              />
            </Pressable>
          )}
          {promoState === 'input' && (
            <View style={styles.promoInputRow}>
              <TextInput
                style={styles.promoTextInput}
                placeholder="Enter promo code"
                placeholderTextColor={CART_COLORS.textSecondary}
                value={promoInput}
                onChangeText={setPromoInput}
                autoCapitalize="characters"
              />
              <Pressable
                style={styles.promoApplyBtn}
                onPress={handleApplyPromo}
              >
                <Text style={styles.promoApplyText}>Apply</Text>
              </Pressable>
            </View>
          )}
          {promoState === 'applied' && promoCode && promoDiscount > 0 && (
            <View style={styles.promoApplied}>
              <Ionicons
                name="pricetag"
                size={16}
                color={CART_COLORS.success}
                style={styles.promoIcon}
              />
              <Text style={styles.promoAppliedText}>{promoCode} applied</Text>
              <Pressable onPress={() => { removePromo(); setPromoState('idle'); }}>
                <Ionicons
                  name="close"
                  size={18}
                  color={CART_COLORS.textSecondary}
                />
              </Pressable>
            </View>
          )}
        </View>

        {/* Savings Card */}
        <SavingsCard
          promoDiscount={promoDiscount}
          freeDeliverySaved={subtotal() >= 30 ? 3.99 : 0}
        />

        {/* Price breakdown */}
        <View style={styles.priceCard}>
          <View style={styles.priceRow}>
            <Text style={styles.priceLabel}>Subtotal</Text>
            <Text style={styles.priceValue}>${subtotal().toFixed(2)}</Text>
          </View>
          <View style={styles.priceRow}>
            <Text style={styles.priceLabel}>Tax</Text>
            <Text style={styles.priceValue}>${tax().toFixed(2)}</Text>
          </View>
          <View style={styles.priceRow}>
            <Text style={styles.priceLabel}>Delivery fee</Text>
            <Text style={styles.priceValue}>${deliveryFee().toFixed(2)}</Text>
          </View>
          {promoDiscount > 0 && (
            <View style={styles.priceRow}>
              <Text style={[styles.priceLabel, styles.discountLabel]}>
                Discount
              </Text>
              <Text style={[styles.priceValue, styles.discountValue]}>
                -${promoDiscount.toFixed(2)}
              </Text>
            </View>
          )}
          <View style={styles.divider} />
          <View style={styles.priceRow}>
            <Text style={styles.totalLabel}>Total</Text>
            <Text style={styles.totalValue}>${total().toFixed(2)}</Text>
          </View>
        </View>
      </ScrollView>

      {/* Sticky footer */}
      <View
        style={[
          styles.footer,
          {
            paddingBottom: insets.bottom + 16,
            paddingTop: 16,
          },
        ]}
      >
        <Pressable
          style={styles.ctaButton}
          onPress={() => router.push('/customer/checkout')}
        >
          <Text style={styles.ctaText}>Proceed to Checkout</Text>
          <View style={styles.priceBadge}>
            <Text style={styles.priceBadgeText}>${total().toFixed(2)}</Text>
          </View>
        </Pressable>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: CART_COLORS.background,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingBottom: 16,
  },
  headerTitle: {
    fontSize: 26,
    fontWeight: '800',
    color: CART_COLORS.textPrimary,
    letterSpacing: -0.5,
  },
  clearText: {
    fontSize: 14,
    fontWeight: '600',
    color: CART_COLORS.error,
  },
  scroll: {
    flex: 1,
  },
  scrollContent: {
    paddingHorizontal: 20,
    paddingTop: 8,
  },
  emptyState: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingBottom: 80,
  },
  emptyIconWrapper: {
    width: 96,
    height: 96,
    borderRadius: 48,
    backgroundColor: CART_COLORS.grayLight,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 16,
  },
  emptyTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: CART_COLORS.textPrimary,
    marginBottom: 4,
  },
  emptyMessage: {
    fontSize: 14,
    color: CART_COLORS.textSecondary,
    marginBottom: 24,
  },
  browseBtn: {
    backgroundColor: CART_COLORS.primary,
    borderRadius: 24,
    paddingHorizontal: 32,
    paddingVertical: 14,
  },
  browseBtnText: {
    color: CART_COLORS.white,
    fontSize: 15,
    fontWeight: '700',
  },
  cartItemCard: {
    flexDirection: 'row',
    backgroundColor: CART_COLORS.white,
    borderRadius: 16,
    padding: 12,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 10,
    elevation: 3,
    ...(Platform.OS === 'web' && {
      boxShadow: '0 2px 10px rgba(0,0,0,0.05)',
    }),
  },
  cartItemImage: {
    width: 80,
    height: 80,
    borderRadius: 14,
  },
  imagePlaceholder: {
    backgroundColor: CART_COLORS.grayLight,
  },
  cartItemCenter: {
    flex: 1,
    marginLeft: 14,
  },
  cartItemName: {
    fontSize: 16,
    fontWeight: '600',
    color: CART_COLORS.textPrimary,
  },
  cartItemPrice: {
    fontSize: 17,
    fontWeight: '700',
    color: CART_COLORS.primary,
    marginBottom: 8,
  },
  quantityRow: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
  },
  qtyBtn: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: CART_COLORS.primaryLight,
    alignItems: 'center',
    justifyContent: 'center',
  },
  qtyBtnText: {
    fontSize: 18,
    fontWeight: '600',
    color: CART_COLORS.primary,
  },
  qtyText: {
    fontSize: 15,
    fontWeight: '600',
    color: CART_COLORS.textPrimary,
    marginHorizontal: 12,
    minWidth: 20,
    textAlign: 'center',
  },
  deleteBtn: {
    paddingLeft: 12,
    justifyContent: 'center',
  },
  upsellSection: {
    marginTop: 8,
    marginBottom: 16,
  },
  upsellTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: CART_COLORS.textPrimary,
    marginBottom: 12,
  },
  upsellScroll: {
    flexDirection: 'row',
    gap: 12,
  },
  upsellCard: {
    width: 130,
    backgroundColor: CART_COLORS.white,
    borderRadius: 14,
    overflow: 'hidden',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  upsellImage: {
    width: 130,
    height: 80,
  },
  upsellImgPlaceholder: {
    backgroundColor: CART_COLORS.grayLight,
    alignItems: 'center',
    justifyContent: 'center',
  },
  upsellName: {
    fontSize: 12,
    fontWeight: '600',
    paddingHorizontal: 8,
    paddingTop: 8,
    color: CART_COLORS.textPrimary,
  },
  upsellBottom: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 8,
    paddingVertical: 8,
  },
  upsellPrice: {
    fontSize: 14,
    fontWeight: '700',
    color: CART_COLORS.primary,
  },
  upsellAddBtn: {
    width: 26,
    height: 26,
    borderRadius: 13,
    backgroundColor: CART_COLORS.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  upsellAddText: {
    color: CART_COLORS.white,
    fontSize: 16,
    fontWeight: '700',
  },
  promoSection: {
    marginBottom: 16,
  },
  promoButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: CART_COLORS.primaryLight,
    borderRadius: 14,
    padding: 14,
    gap: 10,
  },
  promoIcon: {
    marginRight: 0,
  },
  promoButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: CART_COLORS.primary,
  },
  promoInputRow: {
    flexDirection: 'row',
    gap: 10,
  },
  promoTextInput: {
    flex: 1,
    backgroundColor: CART_COLORS.grayLight,
    borderRadius: 14,
    paddingHorizontal: 16,
    height: 48,
    fontSize: 15,
    color: CART_COLORS.textPrimary,
  },
  promoApplyBtn: {
    backgroundColor: CART_COLORS.primary,
    borderRadius: 14,
    paddingHorizontal: 20,
    justifyContent: 'center',
  },
  promoApplyText: {
    color: CART_COLORS.white,
    fontSize: 14,
    fontWeight: '700',
  },
  promoApplied: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#E8F8EE',
    borderRadius: 14,
    padding: 14,
    gap: 10,
  },
  promoAppliedText: {
    fontSize: 14,
    fontWeight: '600',
    color: CART_COLORS.success,
    flex: 1,
  },
  priceCard: {
    backgroundColor: CART_COLORS.white,
    borderRadius: 16,
    padding: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 8,
    elevation: 2,
  },
  priceRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 10,
  },
  priceLabel: {
    fontSize: 14,
    color: CART_COLORS.textSecondary,
  },
  priceValue: {
    fontSize: 14,
    fontWeight: '500',
    color: CART_COLORS.textPrimary,
  },
  discountLabel: {
    color: CART_COLORS.success,
    fontWeight: '500',
  },
  discountValue: {
    color: CART_COLORS.success,
    fontWeight: '600',
  },
  divider: {
    height: 1,
    backgroundColor: CART_COLORS.border,
    marginVertical: 10,
  },
  totalLabel: {
    fontSize: 17,
    fontWeight: '700',
    color: CART_COLORS.textPrimary,
  },
  totalValue: {
    fontSize: 20,
    fontWeight: '800',
    color: CART_COLORS.textPrimary,
  },
  footer: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: CART_COLORS.white,
    paddingHorizontal: 20,
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: -4 },
    shadowOpacity: 0.08,
    shadowRadius: 16,
    elevation: 10,
  },
  ctaButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 12,
    backgroundColor: CART_COLORS.primary,
    borderRadius: 24,
    paddingVertical: 16,
    paddingHorizontal: 24,
  },
  ctaText: {
    color: CART_COLORS.white,
    fontSize: 16,
    fontWeight: '700',
  },
  priceBadge: {
    backgroundColor: 'rgba(255,255,255,0.25)',
    borderRadius: 12,
    paddingHorizontal: 12,
    paddingVertical: 4,
  },
  priceBadgeText: {
    color: CART_COLORS.white,
    fontSize: 14,
    fontWeight: '700',
  },
});
