import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Pressable,
  TextInput,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useCartStore } from '../../state/CartStore';
import { useAuthStore } from '../../state/AuthStore';
import { useDataStore } from '../../state/DataStore';
import type { DeliveryAddress } from '../../models/AppUser';
import type { TipOption } from '../../state/CartStore';

// Checkout design tokens
const COLORS = {
  background: '#F8F8F8',
  white: '#FFFFFF',
  primary: '#FF8C1A',
  primaryLight: '#FFF3E6',
  textPrimary: '#111111',
  textSecondary: '#777777',
  border: '#EEEEEE',
  grayLight: '#F5F5F5',
  error: '#E74C3C',
  success: '#2ECC71',
  errorLight: '#FDE8E8',
  warningBg: '#FFF3E0',
  warningText: '#E65100',
  disabled: '#CCCCCC',
};

const TIME_SLOTS = [
  '12:00 PM', '12:30 PM', '1:00 PM', '1:30 PM', '2:00 PM', '2:30 PM',
  '3:00 PM', '3:30 PM', '4:00 PM', '4:30 PM', '5:00 PM', '5:30 PM',
  '6:00 PM', '6:30 PM', '7:00 PM',
];

const DELIVERY_NOTES_TEMPLATES = [
  'Leave at door',
  'Ring the doorbell',
  'Call on arrival',
  'Gate code: 1234',
];

const formatAddress = (a: DeliveryAddress) =>
  `${a.street}, ${a.city}, ${a.state} ${a.zip}`;

export const CheckoutScreen: React.FC = () => {
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const { user } = useAuthStore();
  const {
    items,
    subtotal,
    tax,
    deliveryFee,
    tipAmount,
    total,
    promoCode,
    promoDiscount,
    deliveryNotes,
    selectedTip,
    setSelectedTip,
    applyPromo,
    removePromo,
    clear,
  } = useCartStore();
  const { placeOrderViaSupabase } = useDataStore();

  const [isPlacingOrder, setIsPlacingOrder] = useState(false);
  const [isDelivery, setIsDelivery] = useState(true);
  const [addressExpanded, setAddressExpanded] = useState(false);
  const [paymentExpanded, setPaymentExpanded] = useState(false);
  const [isScheduled, setIsScheduled] = useState(false);
  const [selectedSlot, setSelectedSlot] = useState<string | null>(null);
  const [notes, setNotes] = useState(deliveryNotes);
  const [promoInput, setPromoInput] = useState('');
  const [showPromoInput, setShowPromoInput] = useState(false);
  const [paymentMethod, setPaymentMethod] = useState<'card' | 'cash'>('card');
  const [customTip, setCustomTip] = useState('');
  const [addressError, setAddressError] = useState(false);
  const [outOfZone, setOutOfZone] = useState(false);

  const addresses: DeliveryAddress[] = user?.address
    ? [user.address]
    : [
        { street: '123 Main St', city: 'San Francisco', state: 'CA', zip: '94102', notes: '' },
      ];
  const selectedAddress = addresses[0];

  const paymentOptions = [
    { id: 'card' as const, label: 'Credit Card •••• 4242' },
    { id: 'cash' as const, label: 'Cash on Delivery' },
  ];

  const handleApplyPromo = () => {
    if (promoInput.trim()) {
      applyPromo(promoInput.trim());
      setShowPromoInput(false);
      setPromoInput('');
    }
  };

  const handlePlaceOrder = async () => {
    if (!user) {
      Alert.alert('Error', 'You must be logged in to place an order');
      return;
    }
    if (items.length === 0) {
      Alert.alert('Error', 'Your cart is empty');
      return;
    }
    if (isDelivery && !selectedAddress) {
      setAddressError(true);
      Alert.alert('Error', 'Please add a delivery address');
      return;
    }
    if (outOfZone && isDelivery) {
      Alert.alert('Out of Zone', 'Delivery is not available to your area');
      return;
    }

    setIsPlacingOrder(true);
    const address: DeliveryAddress | undefined = isDelivery
      ? selectedAddress
      : undefined;

    const orderId = await placeOrderViaSupabase({
      userId: user.id,
      customerName: user.name,
      items,
      address: address ?? { street: '', city: '', state: '', zip: '', notes: '' },
      notes: notes,
      promoCode: promoCode || null,
      tip: tipAmount(),
      paymentMethod,
    });

    setIsPlacingOrder(false);

    if (orderId) {
      Alert.alert(
        'Order Placed!',
        `Your order #${orderId.slice(0, 8)} has been placed successfully.`,
        [
          {
            text: 'View Orders',
            onPress: () => {
              clear();
              router.replace('/customer/orders');
            },
          },
        ]
      );
    } else {
      Alert.alert(
        'Order Failed',
        'There was an error placing your order. Please try again.'
      );
    }
  };

  const renderTipOption = (opt: TipOption) => {
    const isSelected =
      opt.type === selectedTip.type &&
      (opt.type !== 'custom' || selectedTip.type === 'custom');
    const label =
      opt.type === 'none'
        ? '0%'
        : opt.type === 'five'
        ? '5%'
        : opt.type === 'ten'
        ? '10%'
        : opt.type === 'custom'
        ? 'Custom'
        : opt.type === 'fifteen'
        ? '15%'
        : '20%';
    return (
      <Pressable
        key={opt.type + (opt.type === 'custom' ? 'custom' : '')}
        style={[styles.tipChip, isSelected && styles.tipChipActive]}
        onPress={() => setSelectedTip(opt)}
      >
        <Text style={[styles.tipChipText, isSelected && styles.tipChipTextActive]}>
          {label}
        </Text>
      </Pressable>
    );
  };

  const tipOptions: TipOption[] = [
    { type: 'none' },
    { type: 'five' },
    { type: 'ten' },
    { type: 'custom', amount: 0 },
  ];

  const isDisabled = outOfZone && isDelivery;

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      {/* Header */}
      <View style={styles.header}>
        <Pressable style={styles.backBtn} onPress={() => router.back()}>
          <Ionicons name="arrow-back" size={22} color={COLORS.textPrimary} />
        </Pressable>
        <Text style={styles.headerTitle}>Checkout</Text>
        <View style={styles.headerPlaceholder} />
      </View>

      <ScrollView
        style={styles.scroll}
        contentContainerStyle={[
          styles.scrollContent,
          { paddingBottom: insets.bottom + 100 },
        ]}
        showsVerticalScrollIndicator={false}
      >
        {/* Delivery/Pickup Toggle */}
        <View style={styles.toggleSection}>
          <View style={styles.toggleRow}>
            <Pressable
              style={[styles.toggleBtn, isDelivery && styles.toggleBtnActive]}
              onPress={() => setIsDelivery(true)}
            >
              <Ionicons
                name="car-outline"
                size={18}
                color={isDelivery ? COLORS.white : COLORS.textSecondary}
              />
              <Text
                style={[
                  styles.toggleText,
                  isDelivery && styles.toggleTextActive,
                ]}
              >
                Delivery
              </Text>
            </Pressable>
            <Pressable
              style={[styles.toggleBtn, !isDelivery && styles.toggleBtnActive]}
              onPress={() => setIsDelivery(false)}
            >
              <Ionicons
                name="storefront-outline"
                size={18}
                color={!isDelivery ? COLORS.white : COLORS.textSecondary}
              />
              <Text
                style={[
                  styles.toggleText,
                  !isDelivery && styles.toggleTextActive,
                ]}
              >
                Pickup
              </Text>
            </Pressable>
          </View>
        </View>

        {/* Delivery Address (delivery only) */}
        {isDelivery && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Delivery Address</Text>
            <Pressable
              style={[
                styles.selectionCard,
                addressError && styles.selectionCardError,
              ]}
              onPress={() => setAddressExpanded(!addressExpanded)}
            >
              <View style={[styles.iconContainer, addressError && styles.iconContainerError]}>
                <Ionicons name="location" size={20} color={COLORS.primary} />
              </View>
              <View style={styles.selectionInfo}>
                <Text style={styles.selectionLabel}>Home</Text>
                <Text style={styles.selectionSub} numberOfLines={1}>
                  {selectedAddress ? formatAddress(selectedAddress) : 'Add address'}
                </Text>
              </View>
              <Ionicons
                name={addressExpanded ? 'chevron-up' : 'chevron-down'}
                size={18}
                color={COLORS.textSecondary}
              />
            </Pressable>
            {addressExpanded && (
              <View style={styles.dropdown}>
                {addresses.map((addr, i) => (
                  <Pressable
                    key={i}
                    style={[
                      styles.dropdownOption,
                      selectedAddress === addr && styles.dropdownOptionSelected,
                    ]}
                    onPress={() => {
                      setAddressExpanded(false);
                      setAddressError(false);
                    }}
                  >
                    <Ionicons
                      name="location"
                      size={16}
                      color={COLORS.primary}
                      style={{ marginRight: 10 }}
                    />
                    <View style={{ flex: 1 }}>
                      <Text style={styles.dropdownLabel}>Address {i + 1}</Text>
                      <Text style={styles.dropdownSub}>{formatAddress(addr)}</Text>
                    </View>
                  </Pressable>
                ))}
              </View>
            )}
            {outOfZone && (
              <View style={styles.outOfZone}>
                <Text style={styles.outOfZoneText}>
                  Delivery is not available to this address. Please choose pickup or a different address.
                </Text>
              </View>
            )}
          </View>
        )}

        {/* Payment Method */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Payment Method</Text>
          <Pressable
            style={styles.selectionCard}
            onPress={() => setPaymentExpanded(!paymentExpanded)}
          >
            <View style={styles.iconContainer}>
              <Ionicons name="card-outline" size={20} color={COLORS.primary} />
            </View>
            <View style={styles.selectionInfo}>
              <Text style={styles.selectionLabel}>
                {paymentOptions.find(p => p.id === paymentMethod)?.label ??
                  'Select payment'}
              </Text>
            </View>
            <Ionicons
              name={paymentExpanded ? 'chevron-up' : 'chevron-down'}
              size={18}
              color={COLORS.textSecondary}
            />
          </Pressable>
          {paymentExpanded && (
            <View style={styles.dropdown}>
              {paymentOptions.map(opt => (
                <Pressable
                  key={opt.id}
                  style={[
                    styles.dropdownOption,
                    paymentMethod === opt.id && styles.dropdownOptionSelected,
                  ]}
                  onPress={() => {
                    setPaymentMethod(opt.id);
                    setPaymentExpanded(false);
                  }}
                >
                  <Text style={styles.dropdownLabel}>{opt.label}</Text>
                </Pressable>
              ))}
            </View>
          )}
        </View>

        {/* Schedule */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Schedule</Text>
          <View style={styles.scheduleRow}>
            <Pressable
              style={[styles.scheduleBtn, !isScheduled && styles.scheduleBtnActive]}
              onPress={() => {
                setIsScheduled(false);
                setSelectedSlot(null);
              }}
            >
              <Ionicons
                name="time-outline"
                size={16}
                color={!isScheduled ? COLORS.white : COLORS.textPrimary}
              />
              <Text
                style={[
                  styles.scheduleBtnText,
                  !isScheduled && styles.scheduleBtnTextActive,
                ]}
              >
                ASAP (30-45 min)
              </Text>
            </Pressable>
            <Pressable
              style={[styles.scheduleBtn, isScheduled && styles.scheduleBtnActive]}
              onPress={() => setIsScheduled(true)}
            >
              <Ionicons
                name="time-outline"
                size={16}
                color={isScheduled ? COLORS.white : COLORS.textPrimary}
              />
              <Text
                style={[
                  styles.scheduleBtnText,
                  isScheduled && styles.scheduleBtnTextActive,
                ]}
              >
                Schedule
              </Text>
            </Pressable>
          </View>
          {isScheduled && (
            <View style={styles.timeSlotsGrid}>
              {TIME_SLOTS.map(slot => (
                <Pressable
                  key={slot}
                  style={[
                    styles.timeSlotChip,
                    selectedSlot === slot && styles.timeSlotChipActive,
                  ]}
                  onPress={() => setSelectedSlot(slot)}
                >
                  <Text
                    style={[
                      styles.timeSlotText,
                      selectedSlot === slot && styles.timeSlotTextActive,
                    ]}
                  >
                    {slot}
                  </Text>
                </Pressable>
              ))}
            </View>
          )}
        </View>

        {/* Delivery Notes (delivery only) */}
        {isDelivery && (
          <View style={styles.section}>
            <View style={styles.notesCard}>
              <TextInput
                style={styles.notesInput}
                placeholder="Add delivery instructions..."
                placeholderTextColor={COLORS.textSecondary}
                value={notes}
                onChangeText={setNotes}
                multiline
                numberOfLines={3}
              />
              <Pressable
                style={styles.templatesLink}
                onPress={() => setNotes(DELIVERY_NOTES_TEMPLATES[0])}
              >
                <Ionicons name="document-text-outline" size={14} color={COLORS.primary} />
                <Text style={styles.templatesLinkText}>Quick templates</Text>
              </Pressable>
              <View style={styles.templateChips}>
                {DELIVERY_NOTES_TEMPLATES.map((t, i) => (
                  <Pressable
                    key={i}
                    style={styles.templateChip}
                    onPress={() => setNotes(t)}
                  >
                    <Text style={styles.templateChipText}>{t}</Text>
                  </Pressable>
                ))}
              </View>
            </View>
          </View>
        )}

        {/* Tip Selector (delivery only) */}
        {isDelivery && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Tip</Text>
            <View style={styles.tipRow}>
              {tipOptions.map(opt => renderTipOption(opt))}
            </View>
            {selectedTip.type === 'custom' && (
              <View style={styles.customTipRow}>
                <Text style={styles.customTipPrefix}>$</Text>
                <TextInput
                  style={styles.customTipInput}
                  placeholder="0.00"
                  value={customTip}
                  onChangeText={v => {
                    setCustomTip(v);
                    const num = parseFloat(v) || 0;
                    setSelectedTip({ type: 'custom', amount: num });
                  }}
                  keyboardType="decimal-pad"
                />
              </View>
            )}
          </View>
        )}

        {/* Promo code (inline) */}
        <View style={styles.section}>
          {!promoCode || promoDiscount === 0 ? (
            showPromoInput ? (
              <View style={styles.promoInputRow}>
                <TextInput
                  style={styles.promoInput}
                  placeholder="Enter promo code"
                  value={promoInput}
                  onChangeText={setPromoInput}
                  autoCapitalize="characters"
                />
                <Pressable style={styles.promoApplyBtn} onPress={handleApplyPromo}>
                  <Text style={styles.promoApplyText}>Apply</Text>
                </Pressable>
              </View>
            ) : (
              <Pressable
                style={styles.promoButton}
                onPress={() => setShowPromoInput(true)}
              >
                <Ionicons name="pricetag" size={18} color={COLORS.primary} />
                <Text style={styles.promoButtonText}>Add promo code</Text>
                <Ionicons name="chevron-forward" size={18} color={COLORS.textSecondary} />
              </Pressable>
            )
          ) : (
            <View style={styles.promoApplied}>
              <Ionicons name="pricetag" size={16} color={COLORS.success} />
              <Text style={styles.promoAppliedText}>{promoCode} applied</Text>
              <Pressable onPress={removePromo}>
                <Ionicons name="close" size={18} color={COLORS.textSecondary} />
              </Pressable>
            </View>
          )}
        </View>

        {/* Order Summary */}
        <View style={styles.summaryCard}>
          <Text style={styles.summaryTitle}>Order Summary</Text>
          {items.map((item, idx) => {
            const unitPrice =
              item.menuItem.price +
              Object.values(item.selectedModifiers)
                .flat()
                .reduce((sum, optId) => {
                  const grp = item.menuItem.modifierGroups.find(g =>
                    g.options.some(o => o.id === optId),
                  );
                  const opt = grp?.options.find(o => o.id === optId);
                  return sum + (opt?.priceAdjustment ?? 0);
                }, 0);
            const lineTotal = unitPrice * item.quantity;
            return (
              <View key={item.id} style={styles.summaryItemRow}>
                <Text style={styles.summaryQty}>{item.quantity}</Text>
                <Text style={styles.summaryName} numberOfLines={1}>
                  {item.menuItem.name}
                </Text>
                <Text style={styles.summaryPrice}>
                  ${lineTotal.toFixed(2)}
                </Text>
              </View>
            );
          })}
          <View style={styles.summaryDivider} />
          <View style={styles.summaryRow}>
            <Text style={styles.summaryLabel}>Subtotal</Text>
            <Text style={styles.summaryValue}>${subtotal().toFixed(2)}</Text>
          </View>
          <View style={styles.summaryRow}>
            <View style={styles.summaryLabelRow}>
              <Text style={styles.summaryLabel}>Delivery fee</Text>
              <Ionicons name="information-circle-outline" size={12} color={COLORS.textSecondary} />
            </View>
            <Text style={styles.summaryValue}>
              {deliveryFee() === 0 ? 'FREE' : `$${deliveryFee().toFixed(2)}`}
            </Text>
          </View>
          <View style={styles.summaryRow}>
            <Text style={styles.summaryLabel}>Tax</Text>
            <Text style={styles.summaryValue}>${tax().toFixed(2)}</Text>
          </View>
          {promoDiscount > 0 && (
            <View style={styles.summaryRow}>
              <Text style={[styles.summaryLabel, { color: COLORS.success }]}>
                Discount
              </Text>
              <Text style={[styles.summaryValue, { color: COLORS.success, fontWeight: '600' }]}>
                -${promoDiscount.toFixed(2)}
              </Text>
            </View>
          )}
          {isDelivery && tipAmount() > 0 && (
            <View style={styles.summaryRow}>
              <Text style={styles.summaryLabel}>Tip</Text>
              <Text style={styles.summaryValue}>${tipAmount().toFixed(2)}</Text>
            </View>
          )}
          <View style={styles.summaryDivider} />
          <View style={styles.summaryRow}>
            <Text style={styles.totalLabel}>Total</Text>
            <Text style={styles.totalValue}>${total().toFixed(2)}</Text>
          </View>
        </View>
      </ScrollView>

      {/* Sticky Footer */}
      <View
        style={[
          styles.footer,
          { paddingBottom: insets.bottom + 16, paddingTop: 16 },
        ]}
      >
        <Pressable
          style={[styles.ctaButton, isDisabled && styles.ctaButtonDisabled]}
          onPress={handlePlaceOrder}
          disabled={isDisabled || isPlacingOrder}
        >
          {isPlacingOrder ? (
            <ActivityIndicator color="#FFF" />
          ) : (
            <>
              <Text style={styles.ctaText}>Confirm Order</Text>
              <View style={styles.priceBadge}>
                <Text style={styles.priceBadgeText}>${total().toFixed(2)}</Text>
              </View>
            </>
          )}
        </Pressable>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: COLORS.white,
    paddingHorizontal: 20,
    paddingBottom: 12,
  },
  backBtn: {
    width: 44,
    height: 44,
    borderRadius: 14,
    backgroundColor: COLORS.grayLight,
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerTitle: {
    flex: 1,
    fontSize: 20,
    fontWeight: '700',
    color: COLORS.textPrimary,
    textAlign: 'center',
  },
  headerPlaceholder: {
    width: 44,
    height: 44,
  },
  scroll: {
    flex: 1,
  },
  scrollContent: {
    paddingHorizontal: 20,
    paddingTop: 20,
  },
  toggleSection: {
    backgroundColor: COLORS.white,
    borderRadius: 16,
    padding: 4,
    marginBottom: 20,
  },
  toggleRow: {
    flexDirection: 'row',
    gap: 8,
  },
  toggleBtn: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    paddingVertical: 14,
    borderRadius: 13,
  },
  toggleBtnActive: {
    backgroundColor: COLORS.primary,
  },
  toggleText: {
    fontSize: 15,
    fontWeight: '600',
    color: COLORS.textSecondary,
  },
  toggleTextActive: {
    color: COLORS.white,
  },
  section: {
    marginBottom: 20,
  },
  sectionTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginBottom: 10,
  },
  selectionCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: COLORS.white,
    borderRadius: 14,
    padding: 14,
    gap: 12,
  },
  selectionCardError: {
    borderWidth: 1.5,
    borderColor: COLORS.error,
  },
  iconContainer: {
    width: 40,
    height: 40,
    borderRadius: 12,
    backgroundColor: COLORS.primaryLight,
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconContainerError: {
    backgroundColor: COLORS.errorLight,
  },
  selectionInfo: {
    flex: 1,
  },
  selectionLabel: {
    fontSize: 15,
    fontWeight: '600',
    color: COLORS.textPrimary,
  },
  selectionSub: {
    fontSize: 13,
    color: COLORS.textSecondary,
    marginTop: 2,
  },
  dropdown: {
    backgroundColor: COLORS.white,
    borderRadius: 14,
    marginTop: 8,
    overflow: 'hidden',
  },
  dropdownOption: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 14,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.grayLight,
  },
  dropdownOptionSelected: {
    backgroundColor: COLORS.primaryLight,
  },
  dropdownLabel: {
    fontSize: 15,
    fontWeight: '600',
    color: COLORS.textPrimary,
  },
  dropdownSub: {
    fontSize: 13,
    color: COLORS.textSecondary,
  },
  outOfZone: {
    backgroundColor: COLORS.warningBg,
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
    marginTop: 8,
  },
  outOfZoneText: {
    fontSize: 13,
    color: COLORS.warningText,
    fontWeight: '500',
  },
  scheduleRow: {
    flexDirection: 'row',
    gap: 10,
  },
  scheduleBtn: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    backgroundColor: COLORS.white,
    borderRadius: 14,
    paddingVertical: 14,
  },
  scheduleBtnActive: {
    backgroundColor: COLORS.primary,
  },
  scheduleBtnText: {
    fontSize: 13,
    fontWeight: '500',
    color: COLORS.textPrimary,
  },
  scheduleBtnTextActive: {
    color: COLORS.white,
    fontWeight: '600',
  },
  timeSlotsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginTop: 12,
  },
  timeSlotChip: {
    backgroundColor: COLORS.white,
    borderRadius: 10,
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderWidth: 1.5,
    borderColor: 'transparent',
  },
  timeSlotChipActive: {
    backgroundColor: COLORS.primaryLight,
    borderColor: COLORS.primary,
  },
  timeSlotText: {
    fontSize: 13,
    fontWeight: '500',
    color: COLORS.textPrimary,
  },
  timeSlotTextActive: {
    color: COLORS.primary,
    fontWeight: '600',
  },
  notesCard: {
    backgroundColor: COLORS.white,
    borderRadius: 14,
    padding: 14,
  },
  notesInput: {
    fontSize: 14,
    minHeight: 50,
    color: COLORS.textPrimary,
  },
  templatesLink: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 8,
    gap: 6,
  },
  templatesLinkText: {
    fontSize: 13,
    color: COLORS.primary,
    fontWeight: '600',
  },
  templateChips: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginTop: 8,
  },
  templateChip: {
    backgroundColor: COLORS.grayLight,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 10,
  },
  templateChipText: {
    fontSize: 13,
    fontWeight: '500',
    color: COLORS.textPrimary,
  },
  tipRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  tipChip: {
    backgroundColor: COLORS.white,
    borderRadius: 10,
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderWidth: 1.5,
    borderColor: 'transparent',
  },
  tipChipActive: {
    backgroundColor: COLORS.primaryLight,
    borderColor: COLORS.primary,
  },
  tipChipText: {
    fontSize: 13,
    fontWeight: '500',
    color: COLORS.textPrimary,
  },
  tipChipTextActive: {
    color: COLORS.primary,
    fontWeight: '600',
  },
  customTipRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 12,
    backgroundColor: COLORS.white,
    borderRadius: 14,
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderWidth: 1.5,
    borderColor: COLORS.primary,
  },
  customTipPrefix: {
    fontSize: 16,
    fontWeight: '600',
    color: COLORS.textPrimary,
    marginRight: 4,
  },
  customTipInput: {
    flex: 1,
    fontSize: 16,
    color: COLORS.textPrimary,
    padding: 0,
  },
  promoButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: COLORS.primaryLight,
    borderRadius: 14,
    padding: 14,
    gap: 10,
  },
  promoButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: COLORS.primary,
    flex: 1,
  },
  promoInputRow: {
    flexDirection: 'row',
    gap: 10,
  },
  promoInput: {
    flex: 1,
    backgroundColor: COLORS.grayLight,
    borderRadius: 14,
    paddingHorizontal: 16,
    height: 48,
    fontSize: 15,
  },
  promoApplyBtn: {
    backgroundColor: COLORS.primary,
    borderRadius: 14,
    paddingHorizontal: 20,
    justifyContent: 'center',
  },
  promoApplyText: {
    color: COLORS.white,
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
    color: COLORS.success,
    flex: 1,
  },
  summaryCard: {
    backgroundColor: COLORS.white,
    borderRadius: 16,
    padding: 16,
  },
  summaryTitle: {
    fontSize: 17,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginBottom: 14,
  },
  summaryItemRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  summaryQty: {
    fontSize: 14,
    fontWeight: '600',
    color: COLORS.primary,
    width: 30,
  },
  summaryName: {
    flex: 1,
    fontSize: 14,
    color: COLORS.textPrimary,
  },
  summaryPrice: {
    fontSize: 14,
    fontWeight: '600',
    color: COLORS.textPrimary,
  },
  summaryDivider: {
    height: 1,
    backgroundColor: COLORS.border,
    marginVertical: 12,
  },
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  summaryLabel: {
    fontSize: 14,
    color: COLORS.textSecondary,
  },
  summaryLabelRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  summaryValue: {
    fontSize: 14,
    fontWeight: '500',
    color: COLORS.textPrimary,
  },
  totalLabel: {
    fontSize: 17,
    fontWeight: '700',
    color: COLORS.textPrimary,
  },
  totalValue: {
    fontSize: 20,
    fontWeight: '800',
    color: COLORS.textPrimary,
  },
  footer: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: COLORS.white,
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
    backgroundColor: COLORS.primary,
    borderRadius: 24,
    paddingVertical: 16,
    paddingHorizontal: 24,
  },
  ctaButtonDisabled: {
    backgroundColor: COLORS.disabled,
  },
  ctaText: {
    color: COLORS.white,
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
    color: COLORS.white,
    fontSize: 14,
    fontWeight: '700',
  },
});
