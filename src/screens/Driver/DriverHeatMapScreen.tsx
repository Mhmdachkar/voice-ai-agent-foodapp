import React, { useState, useRef, useEffect } from 'react';
import {
  View, Text, StyleSheet, ScrollView, Pressable, Animated, Easing,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useDataStore } from '../../state/DataStore';
import { colors, spacing, radii } from '../../theme/theme';

const ZONES = [
  { id: 'downtown', name: 'Downtown', demand: 'high', orders: 12, icon: '\uD83C\uDFD9\uFE0F', color: '#FF3B30' },
  { id: 'midtown', name: 'Midtown', demand: 'medium', orders: 7, icon: '\uD83C\uDFE2', color: '#FF9500' },
  { id: 'uptown', name: 'Uptown', demand: 'low', orders: 3, icon: '\uD83C\uDFE1', color: '#34C759' },
  { id: 'suburbs', name: 'Suburbs', demand: 'low', orders: 2, icon: '\uD83C\uDF33', color: '#34C759' },
  { id: 'university', name: 'University Area', demand: 'high', orders: 15, icon: '\uD83C\uDFEB', color: '#FF3B30' },
  { id: 'business', name: 'Business District', demand: 'medium', orders: 8, icon: '\uD83D\uDCBC', color: '#FF9500' },
];

const DEMAND_LABELS = { high: 'High Demand', medium: 'Moderate', low: 'Low' };

const ZoneCard: React.FC<{ zone: typeof ZONES[0]; index: number }> = ({ zone, index }) => {
  const slideIn = useRef(new Animated.Value(30)).current;
  const fadeIn = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    Animated.parallel([
      Animated.timing(slideIn, { toValue: 0, duration: 400, delay: index * 80, easing: Easing.out(Easing.exp), useNativeDriver: true }),
      Animated.timing(fadeIn, { toValue: 1, duration: 400, delay: index * 80, useNativeDriver: true }),
    ]).start();
  }, []);

  const barWidth = Math.min(100, (zone.orders / 15) * 100);

  return (
    <Animated.View style={[s.zoneCard, { opacity: fadeIn, transform: [{ translateY: slideIn }] }]}>
      <View style={s.zoneHeader}>
        <Text style={s.zoneIcon}>{zone.icon}</Text>
        <View style={{ flex: 1 }}>
          <Text style={s.zoneName}>{zone.name}</Text>
          <View style={s.demandRow}>
            <View style={[s.demandDot, { backgroundColor: zone.color }]} />
            <Text style={[s.demandText, { color: zone.color }]}>
              {DEMAND_LABELS[zone.demand as keyof typeof DEMAND_LABELS]}
            </Text>
          </View>
        </View>
        <View style={s.ordersBadge}>
          <Text style={s.ordersCount}>{zone.orders}</Text>
          <Text style={s.ordersLabel}>orders</Text>
        </View>
      </View>
      <View style={s.barTrack}>
        <View style={[s.barFill, { width: `${barWidth}%`, backgroundColor: zone.color }]} />
      </View>
    </Animated.View>
  );
};

export const DriverHeatMapScreen: React.FC = () => {
  const insets = useSafeAreaInsets();
  const { orders } = useDataStore();
  const [timeFilter, setTimeFilter] = useState<'now' | 'today' | 'week'>('now');
  const pulseAnim = useRef(new Animated.Value(1)).current;

  useEffect(() => {
    const pulse = Animated.loop(
      Animated.sequence([
        Animated.timing(pulseAnim, { toValue: 1.02, duration: 2000, useNativeDriver: true }),
        Animated.timing(pulseAnim, { toValue: 1, duration: 2000, useNativeDriver: true }),
      ]),
    );
    pulse.start();
    return () => pulse.stop();
  }, []);

  const activeOrders = orders.filter(o => !['DELIVERED', 'CANCELED'].includes(o.status));
  const sortedZones = [...ZONES].sort((a, b) => b.orders - a.orders);

  return (
    <ScrollView style={[s.container, { paddingTop: insets.top }]} contentContainerStyle={s.content}>
      <Text style={s.title}>{'\uD83D\uDDFA\uFE0F'} Demand Map</Text>
      <Text style={s.subtitle}>Find the busiest zones for more deliveries</Text>

      {/* Time Filter */}
      <View style={s.filterRow}>
        {(['now', 'today', 'week'] as const).map(f => (
          <Pressable key={f} style={[s.filterChip, timeFilter === f && s.filterChipActive]} onPress={() => setTimeFilter(f)}>
            <Text style={[s.filterText, timeFilter === f && s.filterTextActive]}>
              {f === 'now' ? 'Right Now' : f === 'today' ? 'Today' : 'This Week'}
            </Text>
          </Pressable>
        ))}
      </View>

      {/* Summary */}
      <Animated.View style={[s.summaryCard, { transform: [{ scale: pulseAnim }] }]}>
        <View style={s.summaryItem}>
          <Text style={s.summaryValue}>{activeOrders.length}</Text>
          <Text style={s.summaryLabel}>Active Orders</Text>
        </View>
        <View style={s.summaryDivider} />
        <View style={s.summaryItem}>
          <Text style={s.summaryValue}>{ZONES.filter(z => z.demand === 'high').length}</Text>
          <Text style={s.summaryLabel}>Hot Zones</Text>
        </View>
        <View style={s.summaryDivider} />
        <View style={s.summaryItem}>
          <Text style={s.summaryValue}>$4.50</Text>
          <Text style={s.summaryLabel}>Avg Tip</Text>
        </View>
      </Animated.View>

      {/* Surge Indicator */}
      {ZONES.some(z => z.demand === 'high') && (
        <View style={s.surgeBanner}>
          <Text style={s.surgeIcon}>{'\u26A1'}</Text>
          <View style={{ flex: 1 }}>
            <Text style={s.surgeTitle}>High Demand Active</Text>
            <Text style={s.surgeDesc}>Head to Downtown or University Area for more orders</Text>
          </View>
        </View>
      )}

      {/* Zone List */}
      <Text style={s.sectionTitle}>Zones by Demand</Text>
      {sortedZones.map((zone, i) => (
        <ZoneCard key={zone.id} zone={zone} index={i} />
      ))}

      {/* Tips */}
      <View style={s.tipCard}>
        <Text style={s.tipIcon}>{'\uD83D\uDCA1'}</Text>
        <Text style={s.tipText}>
          Pro tip: Position yourself between high-demand zones during peak hours (11:30-13:30 & 17:30-20:00) for fastest order assignment.
        </Text>
      </View>
    </ScrollView>
  );
};

const s = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.md, paddingBottom: 100 },
  title: { fontSize: 26, fontWeight: '800', color: colors.textPrimary },
  subtitle: { fontSize: 14, color: colors.textSecondary, marginTop: 4, marginBottom: spacing.md },
  filterRow: { flexDirection: 'row', gap: spacing.sm, marginBottom: spacing.md },
  filterChip: { flex: 1, backgroundColor: colors.cardBackground, borderRadius: 20, paddingVertical: 10, alignItems: 'center' },
  filterChipActive: { backgroundColor: colors.accent },
  filterText: { fontSize: 13, fontWeight: '600', color: colors.textSecondary },
  filterTextActive: { color: '#FFF' },
  summaryCard: { flexDirection: 'row', backgroundColor: colors.cardBackground, borderRadius: radii.large, padding: spacing.md, marginBottom: spacing.md },
  summaryItem: { flex: 1, alignItems: 'center' },
  summaryValue: { fontSize: 24, fontWeight: '900', color: colors.textPrimary },
  summaryLabel: { fontSize: 11, color: colors.textSecondary, fontWeight: '600', marginTop: 4 },
  summaryDivider: { width: 1, backgroundColor: colors.border, marginVertical: 4 },
  surgeBanner: { flexDirection: 'row', backgroundColor: '#FFF3E0', borderRadius: radii.medium, padding: spacing.md, marginBottom: spacing.md, alignItems: 'center' },
  surgeIcon: { fontSize: 24, marginRight: spacing.sm },
  surgeTitle: { fontSize: 15, fontWeight: '700', color: '#E65100' },
  surgeDesc: { fontSize: 12, color: '#FF6D00', marginTop: 2 },
  sectionTitle: { fontSize: 16, fontWeight: '700', color: colors.textPrimary, marginBottom: spacing.sm },
  zoneCard: { backgroundColor: colors.cardBackground, borderRadius: radii.medium, padding: spacing.md, marginBottom: spacing.sm },
  zoneHeader: { flexDirection: 'row', alignItems: 'center', marginBottom: spacing.sm },
  zoneIcon: { fontSize: 28, marginRight: spacing.sm },
  zoneName: { fontSize: 15, fontWeight: '700', color: colors.textPrimary },
  demandRow: { flexDirection: 'row', alignItems: 'center', marginTop: 2 },
  demandDot: { width: 8, height: 8, borderRadius: 4, marginRight: 6 },
  demandText: { fontSize: 12, fontWeight: '600' },
  ordersBadge: { alignItems: 'center' },
  ordersCount: { fontSize: 20, fontWeight: '900', color: colors.textPrimary },
  ordersLabel: { fontSize: 10, color: colors.textSecondary, fontWeight: '600' },
  barTrack: { height: 4, backgroundColor: colors.border, borderRadius: 2, overflow: 'hidden' },
  barFill: { height: '100%', borderRadius: 2 },
  tipCard: { flexDirection: 'row', backgroundColor: '#E8F5E9', borderRadius: radii.medium, padding: spacing.md, marginTop: spacing.lg, alignItems: 'flex-start' },
  tipIcon: { fontSize: 18, marginRight: spacing.sm },
  tipText: { fontSize: 13, color: '#2E7D32', flex: 1, lineHeight: 19 },
});
