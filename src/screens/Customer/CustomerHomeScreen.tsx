import React, { useEffect, useRef, useMemo, useState } from 'react';
import {
  View,
  Text,
  FlatList,
  StyleSheet,
  Pressable,
  Animated,
  Easing,
  Image,
  ScrollView,
  Dimensions,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { useDataStore } from '../../state/DataStore';
import { useCartStore } from '../../state/CartStore';
import { useAuthStore } from '../../state/AuthStore';
import { useRecentlyViewed } from '../../providers/RecentlyViewedProvider';
import { colors } from '../../theme/theme';
import type { MenuItem } from '../../models/MenuItem';
import { DeliveryBanner } from '../../components/DeliveryBanner';
import { LiveActivityBanner } from '../../components/LiveActivityBanner';
import { FlashDealCard } from '../../components/FlashDealCard';
import { QuickReorderCard } from '../../components/QuickReorderCard';
import { TopPicksCard } from '../../components/TopPicksCard';
import { RecentlyViewedRow } from '../../components/RecentlyViewedRow';
import { PopularNowBadge } from '../../components/PopularNowBadge';
import { buildFlashDeals, popularNowItems } from '../../mocks/deals';

const { width: SW } = Dimensions.get('window');

const CAT_EMOJI: Record<string, string> = {
  burgers: '\uD83C\uDF54', pizza: '\uD83C\uDF55', sushi: '\uD83C\uDF63',
  salads: '\uD83E\uDD57', pasta: '\uD83C\uDF5D', chicken: '\uD83C\uDF57',
  seafood: '\uD83E\uDD90', desserts: '\uD83C\uDF70', drinks: '\uD83E\uDD64',
  sides: '\uD83C\uDF5F', breakfast: '\uD83E\uDD5E', bowls: '\uD83C\uDF5C',
};

const MOOD_CHIPS = [
  { icon: '\uD83D\uDD25', label: 'Trending', filter: 'popular' },
  { icon: '\uD83E\uDDC1', label: 'Healthy', filter: 'healthy' },
  { icon: '\uD83C\uDF36\uFE0F', label: 'Spicy', filter: 'spicy' },
  { icon: '\uD83E\uDDC0', label: 'Comfort', filter: 'classic' },
  { icon: '\uD83C\uDF31', label: 'Vegan', filter: 'vegan' },
  { icon: '\u2728', label: 'Premium', filter: 'premium' },
];

const FEATURE_CARDS = [
  { icon: '\uD83E\uDDE0', title: 'AI Assistant', desc: 'Get personalized picks', route: '/voice/call', bg: '#845EF7' },
  { icon: '\uD83C\uDF99\uFE0F', title: 'Voice Order', desc: 'Talk to order food', route: '/voice/call', bg: '#20C997' },
  { icon: '\uD83D\uDD01', title: 'Reorder', desc: 'Your favorites, fast', route: '/customer/reorder', bg: '#F06595' },
  { icon: '\uD83D\uDC65', title: 'Group Order', desc: 'Order with friends', route: '/customer/group', bg: '#339AF0' },
  { icon: '\uD83D\uDCC5', title: 'Schedule', desc: 'Pre-order meals', route: '/customer/schedule', bg: '#FF922B' },
  { icon: '\uD83C\uDFC6', title: 'Rewards', desc: 'Points & streaks', route: '/customer/loyalty', bg: '#FFD43B' },
  { icon: '\uD83D\uDEE1\uFE0F', title: 'Diet Profile', desc: 'Allergen safety', route: '/customer/dietary', bg: '#51CF66' },
];

/* ──── Horizontal Food Card ──── */
const FoodCard: React.FC<{
  item: MenuItem; index: number; onAdd: (item: MenuItem) => void;
}> = ({ item, index, onAdd }) => {
  const scale = useRef(new Animated.Value(0.9)).current;
  const opacity = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    Animated.parallel([
      Animated.spring(scale, { toValue: 1, friction: 6, tension: 50, delay: index * 60, useNativeDriver: true }),
      Animated.timing(opacity, { toValue: 1, duration: 400, delay: index * 60, useNativeDriver: true }),
    ]).start();
  }, []);

  const emoji = CAT_EMOJI[item.category] ?? '\uD83C\uDF7D\uFE0F';

  return (
    <Animated.View style={[s.foodCard, { opacity, transform: [{ scale }] }]}>
      {item.imageUrl ? (
        <Image source={{ uri: item.imageUrl }} style={s.foodImg} />
      ) : (
        <View style={s.foodImgPlaceholder}>
          <Text style={{ fontSize: 38 }}>{emoji}</Text>
        </View>
      )}
      <View style={s.foodInfo}>
        <View style={s.foodTagRow}>
          {item.tags.slice(0, 2).map((t, i) => (
            <View key={i} style={s.foodTag}><Text style={s.foodTagText}>{t}</Text></View>
          ))}
        </View>
        <Text style={s.foodName} numberOfLines={1}>{item.name}</Text>
        <Text style={s.foodDesc} numberOfLines={2}>{item.description}</Text>
        <View style={s.foodBottom}>
          <View>
            <Text style={s.foodPrice}>${item.price.toFixed(2)}</Text>
            <View style={s.foodMeta}>
              <Text style={s.foodMetaText}>{'\u2B50'} {item.rating.toFixed(1)}</Text>
              <Text style={s.foodMetaDot}>{'\u00B7'}</Text>
              <Text style={s.foodMetaText}>{item.prepTimeMinutes}min</Text>
            </View>
          </View>
          <Pressable
            style={({ pressed }) => [s.addBtn, pressed && { transform: [{ scale: 0.92 }] }]}
            onPress={() => onAdd(item)}
          >
            <Text style={s.addBtnText}>+</Text>
          </Pressable>
        </View>
      </View>
    </Animated.View>
  );
};

/* ──── Main Screen ──── */
export const CustomerHomeScreen: React.FC = () => {
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const { user, role } = useAuthStore();
  const { menuItems, loadFromSupabase, orders } = useDataStore();
  const { addItem, itemCount, total } = useCartStore();
  const { recentItems } = useRecentlyViewed();
  const [activeMood, setActiveMood] = useState<string | null>(null);

  const headerScale = useRef(new Animated.Value(0.95)).current;
  const headerOp = useRef(new Animated.Value(0)).current;
  const bannerSlide = useRef(new Animated.Value(30)).current;

  useEffect(() => {
    if (user && role) loadFromSupabase(user.id, role);
  }, [user, role, loadFromSupabase]);

  useEffect(() => {
    Animated.stagger(150, [
      Animated.parallel([
        Animated.spring(headerScale, { toValue: 1, friction: 6, tension: 50, useNativeDriver: true }),
        Animated.timing(headerOp, { toValue: 1, duration: 600, useNativeDriver: true }),
      ]),
      Animated.timing(bannerSlide, { toValue: 0, duration: 500, easing: Easing.out(Easing.exp), useNativeDriver: true }),
    ]).start();
  }, []);

  const filteredItems = useMemo(() => {
    const available = menuItems.filter(i => i.isAvailable);
    if (!activeMood) return available.sort((a, b) => b.rating - a.rating).slice(0, 10);
    return available.filter(i => i.tags.some(t => t.toLowerCase().includes(activeMood))).slice(0, 10);
  }, [menuItems, activeMood]);

  const trendingCategories = useMemo(() => {
    const cats = [...new Set(menuItems.filter(i => i.isAvailable).map(i => i.category))];
    return cats.slice(0, 8);
  }, [menuItems]);

  const activeOrders = useMemo(
    () => orders.filter(o => !['DELIVERED', 'CANCELED'].includes(o.status)),
    [orders],
  );

  const lastDelivered = useMemo(
    () => orders.find(o => o.status === 'DELIVERED'),
    [orders],
  );

  const flashDeals = useMemo(() => buildFlashDeals(menuItems), [menuItems]);

  const topPicks = useMemo(() => {
    return menuItems
      .filter(i => i.isAvailable && i.rating >= 4.6)
      .sort((a, b) => b.rating - a.rating)
      .slice(0, 5);
  }, [menuItems]);

  const popularNowMap = useMemo(() => {
    const map = new Map<string, number>();
    popularNowItems.forEach(p => map.set(p.foodId, p.ordersInLastHour));
    return map;
  }, []);

  const firstName = user?.name?.split(' ')[0] ?? '';
  const h = new Date().getHours();
  const greeting = h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening';
  const count = itemCount();

  return (
    <View style={[s.container, { paddingTop: insets.top }]}>
      <FlatList
        data={filteredItems}
        keyExtractor={item => item.id}
        renderItem={({ item, index }) => {
          const popCount = popularNowMap.get(item.id);
          return (
            <View>
              {popCount != null && <PopularNowBadge ordersInLastHour={popCount} />}
              <FoodCard item={item} index={index} onAdd={i => addItem(i, 1)} />
            </View>
          );
        }}
        contentContainerStyle={[s.listContent, { paddingBottom: count > 0 ? 100 : 30 }]}
        showsVerticalScrollIndicator={false}
        ListHeaderComponent={
          <>
            {/* ── Greeting ── */}
            <Animated.View style={[s.greetingSection, { opacity: headerOp, transform: [{ scale: headerScale }] }]}>
              <View style={s.greetingRow}>
                <View style={{ flex: 1 }}>
                  <Text style={s.greetingText}>{greeting}{firstName ? `, ${firstName}` : ''}</Text>
                  <Text style={s.greetingSub}>What are you craving today?</Text>
                </View>
                <Pressable style={s.avatarBtn} onPress={() => router.push('/customer/profile' as any)}>
                  <Text style={s.avatarText}>{firstName?.charAt(0) || 'U'}</Text>
                </Pressable>
              </View>
            </Animated.View>

            {/* ── Delivery Banner ── */}
            <DeliveryBanner onPress={() => console.log('[Home] Address change tapped')} />

            {/* ── Live Activity Banner ── */}
            <LiveActivityBanner />

            {/* ── Active Order Tracker ── */}
            {activeOrders.length > 0 && (
              <Animated.View style={{ transform: [{ translateY: bannerSlide }] }}>
                <Pressable
                  style={s.liveOrderCard}
                  onPress={() => router.push('/customer/orders' as any)}
                >
                  <View style={s.liveOrderPulse} />
                  <View style={{ flex: 1 }}>
                    <Text style={s.liveOrderTitle}>{'\uD83D\uDCE6'} Live Order</Text>
                    <Text style={s.liveOrderStatus}>
                      {activeOrders[0].status.replace(/_/g, ' ')} {'\u00B7'} {activeOrders[0].items.length} item{activeOrders[0].items.length !== 1 ? 's' : ''}
                    </Text>
                  </View>
                  <Text style={s.liveOrderArrow}>{'\u203A'}</Text>
                </Pressable>
              </Animated.View>
            )}

            {/* ── Feature Cards (AI + Voice) ── */}
            <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={s.featureRow}>
              {FEATURE_CARDS.map(f => (
                <Pressable
                  key={f.title}
                  style={({ pressed }) => [s.featureCard, { backgroundColor: f.bg }, pressed && { opacity: 0.85 }]}
                  onPress={() => router.push(f.route as any)}
                >
                  <Text style={s.featureIcon}>{f.icon}</Text>
                  <Text style={s.featureTitle}>{f.title}</Text>
                  <Text style={s.featureDesc}>{f.desc}</Text>
                </Pressable>
              ))}
              <Pressable
                style={({ pressed }) => [s.featureCard, { backgroundColor: colors.accent }, pressed && { opacity: 0.85 }]}
                onPress={() => router.push('/customer/categories' as any)}
              >
                <Text style={s.featureIcon}>{'\uD83C\uDF54'}</Text>
                <Text style={s.featureTitle}>Full Menu</Text>
                <Text style={s.featureDesc}>Browse all items</Text>
              </Pressable>
            </ScrollView>

            {/* ── Flash Deals ── */}
            {flashDeals.length > 0 && (
              <>
                <View style={s.sectionRow}>
                  <Text style={s.sectionTitle}>{'\u26A1'} Flash Deals</Text>
                </View>
                <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={s.flashDealRow}>
                  {flashDeals.map(deal => (
                    <FlashDealCard
                      key={deal.id}
                      deal={deal}
                      onAdd={d => addItem(d.food, 1)}
                    />
                  ))}
                </ScrollView>
              </>
            )}

            {/* ── Quick Reorder ── */}
            {lastDelivered && (
              <>
                <Text style={s.sectionTitle}>{'\uD83D\uDD01'} Order Again</Text>
                <View style={{ height: 8 }} />
                <QuickReorderCard
                  order={lastDelivered}
                  onReorder={o => {
                    o.items.forEach(ci => addItem(ci.menuItem, ci.quantity, ci.selectedModifiers, ci.specialInstructions));
                    router.push('/customer/cart' as any);
                  }}
                />
              </>
            )}

            {/* ── Top Picks Today ── */}
            {topPicks.length > 0 && (
              <>
                <View style={s.sectionRow}>
                  <Text style={s.sectionTitle}>{'\uD83C\uDFC6'} Top Picks Today</Text>
                </View>
                <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={s.topPicksRow}>
                  {topPicks.map(item => (
                    <TopPicksCard
                      key={item.id}
                      item={item}
                      ordersInLastHour={popularNowMap.get(item.id)}
                      onPress={i => router.push(`/customer/menu-item/${i.id}` as any)}
                    />
                  ))}
                </ScrollView>
              </>
            )}

            {/* ── Recently Viewed ── */}
            <RecentlyViewedRow
              items={recentItems}
              onPress={item => router.push(`/customer/menu-item/${item.id}` as any)}
            />

            {/* ── Category Pills ── */}
            <Text style={s.sectionLabel}>Categories</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={s.catRow}>
              {trendingCategories.map(cat => (
                <Pressable
                  key={cat}
                  style={s.catPill}
                  onPress={() => router.push('/customer/categories' as any)}
                >
                  <Text style={s.catEmoji}>{CAT_EMOJI[cat] ?? '\uD83C\uDF7D\uFE0F'}</Text>
                  <Text style={s.catName}>{cat.charAt(0).toUpperCase() + cat.slice(1)}</Text>
                </Pressable>
              ))}
            </ScrollView>

            {/* ── Mood Chips ── */}
            <Text style={s.sectionLabel}>Food Mood</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={s.moodRow}>
              {MOOD_CHIPS.map(m => {
                const active = activeMood === m.filter;
                return (
                  <Pressable
                    key={m.filter}
                    style={[s.moodChip, active && s.moodChipActive]}
                    onPress={() => setActiveMood(active ? null : m.filter)}
                  >
                    <Text style={s.moodIcon}>{m.icon}</Text>
                    <Text style={[s.moodLabel, active && s.moodLabelActive]}>{m.label}</Text>
                  </Pressable>
                );
              })}
            </ScrollView>

            {/* ── Section Header ── */}
            <View style={s.sectionRow}>
              <Text style={s.sectionTitle}>{activeMood ? '\uD83C\uDFAF' : '\uD83D\uDD25'} {activeMood ? `${activeMood.charAt(0).toUpperCase() + activeMood.slice(1)} Picks` : 'Top Rated'}</Text>
              <Pressable onPress={() => router.push('/customer/categories' as any)}>
                <Text style={s.seeAll}>See all</Text>
              </Pressable>
            </View>
          </>
        }
        ListEmptyComponent={
          <View style={s.emptyBox}>
            <Text style={{ fontSize: 48 }}>{'\uD83C\uDF5C'}</Text>
            <Text style={s.emptyText}>{activeMood ? 'No items match this mood' : 'Loading delicious options...'}</Text>
          </View>
        }
      />

      {/* ── Floating Cart Bar ── */}
      {count > 0 && (
        <Pressable
          style={({ pressed }) => [s.cartBar, pressed && { opacity: 0.9 }, { bottom: insets.bottom + 10 }]}
          onPress={() => router.push('/customer/cart' as any)}
        >
          <View style={s.cartBarLeft}>
            <View style={s.cartBadge}><Text style={s.cartBadgeNum}>{count}</Text></View>
            <Text style={s.cartBarTitle}>View Cart</Text>
          </View>
          <Text style={s.cartBarTotal}>${total().toFixed(2)}</Text>
        </Pressable>
      )}
    </View>
  );
};

const s = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#FAFBFE' },
  listContent: { paddingHorizontal: 20, paddingTop: 8 },

  /* Greeting */
  greetingSection: { marginBottom: 16 },
  greetingRow: { flexDirection: 'row', alignItems: 'center' },
  greetingText: { fontSize: 26, fontWeight: '900', color: colors.textPrimary, letterSpacing: -0.5 },
  greetingSub: { fontSize: 14, color: colors.textSecondary, marginTop: 2 },
  avatarBtn: {
    width: 44, height: 44, borderRadius: 22,
    backgroundColor: colors.accent, alignItems: 'center', justifyContent: 'center',
    shadowColor: colors.accent, shadowOpacity: 0.3, shadowRadius: 8, shadowOffset: { width: 0, height: 3 }, elevation: 4,
  },
  avatarText: { fontSize: 18, fontWeight: '800', color: '#FFF' },

  /* Live Order */
  liveOrderCard: {
    flexDirection: 'row', alignItems: 'center',
    backgroundColor: '#EEF8F0', borderRadius: 16, padding: 14,
    marginBottom: 16, borderWidth: 1, borderColor: '#D0F0D8',
  },
  liveOrderPulse: {
    width: 10, height: 10, borderRadius: 5,
    backgroundColor: colors.success, marginRight: 12,
  },
  liveOrderTitle: { fontSize: 14, fontWeight: '800', color: colors.textPrimary },
  liveOrderStatus: { fontSize: 12, color: colors.textSecondary, marginTop: 2 },
  liveOrderArrow: { fontSize: 24, color: colors.success, fontWeight: '300' },

  /* Feature Cards */
  featureRow: { gap: 10, paddingBottom: 16 },
  featureCard: {
    width: SW * 0.38, borderRadius: 20, padding: 16,
    shadowColor: '#000', shadowOpacity: 0.1, shadowRadius: 10, shadowOffset: { width: 0, height: 4 }, elevation: 4,
  },
  featureIcon: { fontSize: 28, marginBottom: 8 },
  featureTitle: { fontSize: 15, fontWeight: '800', color: '#FFF' },
  featureDesc: { fontSize: 11, color: 'rgba(255,255,255,0.8)', marginTop: 2 },

  /* Categories */
  catRow: { gap: 10, paddingBottom: 16 },
  catPill: {
    alignItems: 'center', backgroundColor: '#FFF', borderRadius: 16,
    paddingVertical: 12, paddingHorizontal: 16,
    shadowColor: '#000', shadowOpacity: 0.04, shadowRadius: 6, shadowOffset: { width: 0, height: 2 }, elevation: 2,
    borderWidth: 1, borderColor: '#F0F0F5',
  },
  catEmoji: { fontSize: 24, marginBottom: 4 },
  catName: { fontSize: 11, fontWeight: '700', color: colors.textPrimary },

  /* Mood chips */
  moodRow: { gap: 8, paddingBottom: 16 },
  moodChip: {
    flexDirection: 'row', alignItems: 'center', gap: 5,
    backgroundColor: '#FFF', borderRadius: 24,
    paddingHorizontal: 14, paddingVertical: 9,
    borderWidth: 1.5, borderColor: '#EDEDF3',
  },
  moodChipActive: { borderColor: colors.accent, backgroundColor: colors.accent + '12' },
  moodIcon: { fontSize: 14 },
  moodLabel: { fontSize: 13, fontWeight: '700', color: colors.textSecondary },
  moodLabelActive: { color: colors.accent },

  /* New Section Rows */
  flashDealRow: { gap: 12, paddingBottom: 16 },
  topPicksRow: { gap: 10, paddingBottom: 16 },

  /* Sections */
  sectionLabel: {
    fontSize: 12, fontWeight: '700', color: colors.textSecondary,
    textTransform: 'uppercase', letterSpacing: 1, marginBottom: 10,
  },
  sectionRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 },
  sectionTitle: { fontSize: 18, fontWeight: '800', color: colors.textPrimary },
  seeAll: { fontSize: 14, fontWeight: '600', color: colors.accent },

  /* Food Card */
  foodCard: {
    backgroundColor: '#FFF', borderRadius: 20, marginBottom: 14,
    flexDirection: 'row', overflow: 'hidden',
    shadowColor: '#000', shadowOpacity: 0.06, shadowRadius: 12, shadowOffset: { width: 0, height: 4 }, elevation: 3,
    borderWidth: 1, borderColor: '#F0F0F5',
  },
  foodImg: { width: 110, height: 120 },
  foodImgPlaceholder: {
    width: 110, height: 120, backgroundColor: '#FFF5EB',
    alignItems: 'center', justifyContent: 'center',
  },
  foodInfo: { flex: 1, padding: 12, justifyContent: 'space-between' },
  foodTagRow: { flexDirection: 'row', gap: 4, marginBottom: 4 },
  foodTag: { backgroundColor: '#F5F5FA', paddingHorizontal: 7, paddingVertical: 2, borderRadius: 6 },
  foodTagText: { fontSize: 9, fontWeight: '700', color: colors.textSecondary, textTransform: 'uppercase' },
  foodName: { fontSize: 15, fontWeight: '800', color: colors.textPrimary },
  foodDesc: { fontSize: 12, color: colors.textSecondary, lineHeight: 16, marginTop: 2 },
  foodBottom: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-end', marginTop: 6 },
  foodPrice: { fontSize: 16, fontWeight: '800', color: colors.textPrimary },
  foodMeta: { flexDirection: 'row', alignItems: 'center', gap: 4, marginTop: 2 },
  foodMetaText: { fontSize: 11, color: colors.textSecondary, fontWeight: '600' },
  foodMetaDot: { fontSize: 11, color: colors.textSecondary },
  addBtn: {
    width: 38, height: 38, borderRadius: 19,
    backgroundColor: colors.accent, alignItems: 'center', justifyContent: 'center',
    shadowColor: colors.accent, shadowOpacity: 0.3, shadowRadius: 6, shadowOffset: { width: 0, height: 2 }, elevation: 3,
  },
  addBtnText: { color: '#FFF', fontSize: 20, fontWeight: '600', marginTop: -1 },

  /* Empty */
  emptyBox: { padding: 40, alignItems: 'center' },
  emptyText: { fontSize: 14, color: colors.textSecondary, marginTop: 8 },

  /* Cart Bar */
  cartBar: {
    position: 'absolute', left: 20, right: 20,
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    backgroundColor: colors.accent, paddingHorizontal: 20, paddingVertical: 15,
    borderRadius: 20,
    shadowColor: colors.accent, shadowOpacity: 0.35, shadowRadius: 14, shadowOffset: { width: 0, height: 5 }, elevation: 8,
  },
  cartBarLeft: { flexDirection: 'row', alignItems: 'center' },
  cartBadge: {
    backgroundColor: '#FFF', width: 26, height: 26, borderRadius: 13,
    alignItems: 'center', justifyContent: 'center', marginRight: 10,
  },
  cartBadgeNum: { fontSize: 13, fontWeight: '900', color: colors.accent },
  cartBarTitle: { fontSize: 16, fontWeight: '800', color: '#FFF' },
  cartBarTotal: { fontSize: 16, fontWeight: '800', color: '#FFF' },
});

