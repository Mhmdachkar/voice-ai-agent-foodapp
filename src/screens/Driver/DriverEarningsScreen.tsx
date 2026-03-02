import React, { useEffect } from 'react';
import {
  View,
  Text,
  FlatList,
  StyleSheet,
  ScrollView,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useAuthStore } from '../../state/AuthStore';
import { useDataStore } from '../../state/DataStore';
import { colors, spacing, radii } from '../../theme/theme';
import { Card } from '../../theme/components/Card';
import { SectionHeader } from '../../theme/components/SectionHeader';
import type { Order } from '../../models/Order';

export const DriverEarningsScreen: React.FC = () => {
  const insets = useSafeAreaInsets();
  const { user } = useAuthStore();
  const { ordersForDriver, refreshOrders } = useDataStore();

  useEffect(() => {
    if (user) refreshOrders(user.id, 'driver');
  }, [user, refreshOrders]);

  const driverOrders = user ? ordersForDriver(user.id) : [];
  const deliveredOrders = driverOrders.filter(o => o.status === 'DELIVERED');

  const todayStr = new Date().toDateString();
  const todayDelivered = deliveredOrders.filter(
    o => new Date(o.createdAt).toDateString() === todayStr,
  );

  const todayEarnings = todayDelivered.reduce((sum, o) => sum + o.tip + o.deliveryFee, 0);
  const totalEarnings = deliveredOrders.reduce((sum, o) => sum + o.tip + o.deliveryFee, 0);
  const totalDeliveries = deliveredOrders.length;
  const acceptanceRate = driverOrders.length > 0
    ? Math.round((deliveredOrders.length / driverOrders.length) * 100)
    : 100;

  const renderDelivery = ({ item: order }: { item: Order }) => {
    const earning = order.tip + order.deliveryFee;
    return (
      <Card style={styles.deliveryCard}>
        <View style={styles.deliveryRow}>
          <View style={{ flex: 1 }}>
            <Text style={styles.orderId}>#{order.id.slice(0, 8)}</Text>
            <Text style={styles.orderDate}>
              {new Date(order.createdAt).toLocaleDateString([], { month: 'short', day: 'numeric' })}
            </Text>
          </View>
          <Text style={styles.earning}>+${earning.toFixed(2)}</Text>
        </View>
        <Text style={styles.orderMeta}>
          {order.items.length} item(s) · Tip: ${order.tip.toFixed(2)} · Fee: ${order.deliveryFee.toFixed(2)}
        </Text>
      </Card>
    );
  };

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      <Text style={styles.title}>Earnings</Text>

      {/* Stats Cards */}
      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.statsRow}>
        <Card style={styles.statCard}>
          <Text style={styles.statValue}>${todayEarnings.toFixed(2)}</Text>
          <Text style={styles.statLabel}>Today</Text>
        </Card>
        <Card style={styles.statCard}>
          <Text style={styles.statValue}>${totalEarnings.toFixed(2)}</Text>
          <Text style={styles.statLabel}>Total Earnings</Text>
        </Card>
        <Card style={styles.statCard}>
          <Text style={styles.statValue}>{totalDeliveries}</Text>
          <Text style={styles.statLabel}>Deliveries</Text>
        </Card>
        <Card style={styles.statCard}>
          <Text style={styles.statValue}>{acceptanceRate}%</Text>
          <Text style={styles.statLabel}>Acceptance</Text>
        </Card>
      </ScrollView>

      {/* Recent deliveries */}
      <View style={{ paddingHorizontal: spacing.lg }}>
        <SectionHeader title="Recent Deliveries" />
      </View>
      <FlatList
        data={deliveredOrders.slice(0, 20)}
        keyExtractor={o => o.id}
        renderItem={renderDelivery}
        contentContainerStyle={{ paddingBottom: spacing.xl }}
        ListEmptyComponent={
          <Text style={styles.emptyText}>No deliveries yet</Text>
        }
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  title: { fontSize: 24, fontWeight: '800', color: colors.textPrimary, paddingHorizontal: spacing.lg, paddingTop: spacing.lg, paddingBottom: spacing.md },
  statsRow: { paddingHorizontal: spacing.lg, gap: spacing.sm, marginBottom: spacing.md },
  statCard: { padding: spacing.md, minWidth: 100, alignItems: 'center' },
  statValue: { fontSize: 22, fontWeight: '800', color: colors.accent },
  statLabel: { fontSize: 12, color: colors.textSecondary, marginTop: 4 },
  deliveryCard: { marginHorizontal: spacing.lg, marginBottom: spacing.sm, padding: spacing.md },
  deliveryRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  orderId: { fontSize: 15, fontWeight: '700', color: colors.textPrimary },
  orderDate: { fontSize: 12, color: colors.textSecondary, marginTop: 2 },
  earning: { fontSize: 18, fontWeight: '700', color: colors.success },
  orderMeta: { fontSize: 12, color: colors.textSecondary, marginTop: spacing.xs },
  emptyText: { textAlign: 'center', color: colors.textSecondary, padding: spacing.xl },
});
