import React, { useEffect } from 'react';
import {
  View,
  Text,
  FlatList,
  StyleSheet,
  Linking,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useAuthStore } from '../../state/AuthStore';
import { useDataStore } from '../../state/DataStore';
import { colors, spacing, radii } from '../../theme/theme';
import { Card } from '../../theme/components/Card';
import { Button } from '../../theme/components/Button';
import { EmptyState } from '../../theme/components/EmptyState';
import type { Order } from '../../models/Order';

export const DriverActiveScreen: React.FC = () => {
  const insets = useSafeAreaInsets();
  const { user } = useAuthStore();
  const { ordersForDriver, refreshOrders, updateOrderStatusLocalOrRemote } = useDataStore();

  useEffect(() => {
    if (user) refreshOrders(user.id, 'driver');
  }, [user, refreshOrders]);

  const activeOrders = user
    ? ordersForDriver(user.id).filter(o => o.status === 'OUT_FOR_DELIVERY')
    : [];

  const handleDeliver = (orderId: string) => {
    if (user) {
      updateOrderStatusLocalOrRemote(orderId, 'DELIVERED', user.id);
    }
  };

  const handleCall = () => {
    Linking.openURL('tel:+1234567890');
  };

  const handleNavigate = (order: Order) => {
    const addr = order.deliveryAddress;
    const query = encodeURIComponent(`${addr.street}, ${addr.city}, ${addr.state} ${addr.zip}`);
    Linking.openURL(`https://maps.google.com/?q=${query}`);
  };

  const renderOrder = ({ item: order }: { item: Order }) => (
    <Card style={styles.orderCard}>
      <View style={styles.orderHeader}>
        <Text style={styles.orderId}>Order #{order.id.slice(0, 8)}</Text>
        <View style={styles.activeBadge}>
          <Text style={styles.activeBadgeText}>In Transit</Text>
        </View>
      </View>

      <Text style={styles.customerName}>{order.customerName}</Text>

      <View style={styles.addressSection}>
        <Text style={styles.addressLabel}>Deliver to:</Text>
        <Text style={styles.addressText}>{order.deliveryAddress.street}</Text>
        <Text style={styles.addressText}>
          {order.deliveryAddress.city}, {order.deliveryAddress.state} {order.deliveryAddress.zip}
        </Text>
        {order.deliveryNotes ? (
          <Text style={styles.noteText}>Note: {order.deliveryNotes}</Text>
        ) : null}
      </View>

      <View style={styles.itemsList}>
        <Text style={styles.itemsTitle}>Items ({order.items.length})</Text>
        {order.items.map((ci, idx) => (
          <Text key={idx} style={styles.itemText}>
            {ci.quantity}x {ci.menuItem.name}
          </Text>
        ))}
      </View>

      <View style={styles.actions}>
        <Button
          title="Call Customer"
          onPress={handleCall}
          fullWidth={false}
          style={styles.callButton}
        />
        <Button
          title="Navigate"
          onPress={() => handleNavigate(order)}
          fullWidth={false}
          style={styles.navButton}
        />
      </View>

      <Button
        title="Mark as Delivered"
        onPress={() => handleDeliver(order.id)}
        style={{ marginTop: spacing.sm }}
      />
    </Card>
  );

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      <Text style={styles.title}>Active Deliveries</Text>
      <FlatList
        data={activeOrders}
        keyExtractor={o => o.id}
        renderItem={renderOrder}
        contentContainerStyle={{ paddingBottom: spacing.xl }}
        ListEmptyComponent={
          <EmptyState
            title="No active deliveries"
            message="Accept an order to start delivering"
          />
        }
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  title: { fontSize: 24, fontWeight: '800', color: colors.textPrimary, paddingHorizontal: spacing.lg, paddingTop: spacing.lg, paddingBottom: spacing.md },
  orderCard: { marginHorizontal: spacing.lg, marginBottom: spacing.md, padding: spacing.md },
  orderHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: spacing.sm },
  orderId: { fontSize: 16, fontWeight: '700', color: colors.textPrimary },
  activeBadge: { backgroundColor: colors.accent, paddingHorizontal: spacing.sm, paddingVertical: 4, borderRadius: radii.small },
  activeBadgeText: { fontSize: 11, fontWeight: '600', color: '#FFFFFF' },
  customerName: { fontSize: 15, fontWeight: '600', color: colors.textPrimary, marginBottom: spacing.sm },
  addressSection: { marginBottom: spacing.md },
  addressLabel: { fontSize: 12, fontWeight: '600', color: colors.textSecondary, marginBottom: 4 },
  addressText: { fontSize: 14, color: colors.textPrimary, lineHeight: 20 },
  noteText: { fontSize: 13, color: colors.warning, fontStyle: 'italic', marginTop: 4 },
  itemsList: { marginBottom: spacing.md },
  itemsTitle: { fontSize: 14, fontWeight: '600', color: colors.textPrimary, marginBottom: 4 },
  itemText: { fontSize: 13, color: colors.textSecondary, marginBottom: 2 },
  actions: { flexDirection: 'row', gap: spacing.sm },
  callButton: { flex: 1, backgroundColor: colors.success },
  navButton: { flex: 1, backgroundColor: colors.accent },
});
