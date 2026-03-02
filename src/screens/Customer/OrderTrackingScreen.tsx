import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
} from 'react-native';
import { colors, spacing, radii } from '../../theme/theme';
import { Card } from '../../theme/components/Card';
import { Button } from '../../theme/components/Button';
import { KitchenQueueView } from './KitchenQueueScreen';
import type { Order, OrderStatus } from '../../models/Order';

const STATUS_LABELS: Record<OrderStatus, string> = {
  PLACED: 'Placed',
  ACCEPTED: 'Accepted',
  PREPARING: 'Preparing',
  READY: 'Ready for Pickup',
  OUT_FOR_DELIVERY: 'Out for Delivery',
  DELIVERED: 'Delivered',
  CANCELED: 'Canceled',
};

const STATUS_COLORS: Record<OrderStatus, string> = {
  PLACED: colors.accent,
  ACCEPTED: colors.success,
  PREPARING: colors.warning,
  READY: colors.success,
  OUT_FOR_DELIVERY: colors.accent,
  DELIVERED: colors.success,
  CANCELED: colors.danger,
};

interface Props {
  order: Order;
  onClose: () => void;
  onReorder?: () => void;
}

export const OrderTrackingScreen: React.FC<Props> = ({ order, onClose, onReorder }) => {
  const sortedTimeline = [...order.timeline].sort(
    (a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime(),
  );

  const isActive = order.status !== 'DELIVERED' && order.status !== 'CANCELED';

  return (
    <ScrollView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.title}>Order #{order.id.slice(0, 8)}</Text>
        <View style={[styles.statusBadge, { backgroundColor: STATUS_COLORS[order.status] }]}>
          <Text style={styles.statusText}>{STATUS_LABELS[order.status]}</Text>
        </View>
      </View>

      {/* Kitchen Queue (for active orders) */}
      {isActive && (
        <View style={{ paddingHorizontal: spacing.lg }}>
          <KitchenQueueView orderId={order.id} />
        </View>
      )}

      {/* Driver Info */}
      {order.driverName && (
        <Card style={styles.driverCard}>
          <View style={styles.driverAvatar}>
            <Text style={styles.driverAvatarText}>{order.driverName.charAt(0)}</Text>
          </View>
          <View style={styles.driverInfo}>
            <Text style={styles.driverName}>{order.driverName}</Text>
            <Text style={styles.driverLabel}>Your Driver</Text>
          </View>
        </Card>
      )}

      {/* Timeline */}
      <Card style={styles.timelineCard}>
        <Text style={styles.sectionTitle}>Order Timeline</Text>
        {sortedTimeline.map((event, index) => {
          const isLast = index === sortedTimeline.length - 1;
          const date = new Date(event.timestamp);
          const timeStr = date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

          return (
            <View key={event.id} style={styles.timelineEvent}>
              <View style={styles.timelineLeft}>
                <View style={[styles.timelineDot, { backgroundColor: STATUS_COLORS[event.status] }]} />
                {!isLast && <View style={styles.timelineLine} />}
              </View>
              <View style={styles.timelineContent}>
                <Text style={styles.timelineStatus}>{STATUS_LABELS[event.status]}</Text>
                <Text style={styles.timelineTime}>{timeStr}</Text>
                {event.note && <Text style={styles.timelineNote}>{event.note}</Text>}
              </View>
            </View>
          );
        })}
      </Card>

      {/* Order Items */}
      <Card style={styles.itemsCard}>
        <Text style={styles.sectionTitle}>Items</Text>
        {order.items.map((ci, idx) => (
          <View key={idx} style={styles.itemRow}>
            <Text style={styles.itemQty}>{ci.quantity}x</Text>
            <Text style={styles.itemName}>{ci.menuItem.name}</Text>
            <Text style={styles.itemPrice}>${(ci.menuItem.price * ci.quantity).toFixed(2)}</Text>
          </View>
        ))}
        <View style={styles.totalRow}>
          <Text style={styles.totalLabel}>Total</Text>
          <Text style={styles.totalValue}>${order.total.toFixed(2)}</Text>
        </View>
      </Card>

      {/* Delivery Address */}
      <Card style={styles.addressCard}>
        <Text style={styles.sectionTitle}>Delivery Address</Text>
        <Text style={styles.addressText}>{order.deliveryAddress.street}</Text>
        <Text style={styles.addressText}>
          {order.deliveryAddress.city}, {order.deliveryAddress.state} {order.deliveryAddress.zip}
        </Text>
        {order.deliveryNotes ? (
          <Text style={styles.noteText}>Note: {order.deliveryNotes}</Text>
        ) : null}
      </Card>

      {/* Actions */}
      {order.status === 'DELIVERED' && onReorder && (
        <Button
          title="Reorder"
          onPress={onReorder}
          style={{ marginHorizontal: spacing.lg, marginTop: spacing.md }}
        />
      )}

      <Button
        title="Close"
        onPress={onClose}
        style={{ marginHorizontal: spacing.lg, marginTop: spacing.sm, marginBottom: spacing.xl, backgroundColor: colors.textSecondary }}
      />
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: spacing.lg, paddingTop: spacing.lg, paddingBottom: spacing.md },
  title: { fontSize: 22, fontWeight: '800', color: colors.textPrimary },
  statusBadge: { paddingHorizontal: spacing.md, paddingVertical: spacing.xs, borderRadius: radii.button },
  statusText: { fontSize: 13, fontWeight: '600', color: '#FFFFFF' },
  driverCard: { marginHorizontal: spacing.lg, marginBottom: spacing.md, padding: spacing.md, flexDirection: 'row', alignItems: 'center' },
  driverAvatar: { width: 44, height: 44, borderRadius: 22, backgroundColor: colors.accent, justifyContent: 'center', alignItems: 'center', marginRight: spacing.md },
  driverAvatarText: { fontSize: 18, fontWeight: '700', color: '#FFFFFF' },
  driverInfo: { flex: 1 },
  driverName: { fontSize: 16, fontWeight: '700', color: colors.textPrimary },
  driverLabel: { fontSize: 12, color: colors.textSecondary },
  timelineCard: { marginHorizontal: spacing.lg, marginBottom: spacing.md, padding: spacing.md },
  sectionTitle: { fontSize: 16, fontWeight: '700', color: colors.textPrimary, marginBottom: spacing.md },
  timelineEvent: { flexDirection: 'row', marginBottom: spacing.sm },
  timelineLeft: { width: 20, alignItems: 'center', marginRight: spacing.sm },
  timelineDot: { width: 12, height: 12, borderRadius: 6 },
  timelineLine: { width: 2, flex: 1, backgroundColor: colors.border, marginTop: 4 },
  timelineContent: { flex: 1, paddingBottom: spacing.xs },
  timelineStatus: { fontSize: 14, fontWeight: '600', color: colors.textPrimary },
  timelineTime: { fontSize: 12, color: colors.textSecondary, marginTop: 2 },
  timelineNote: { fontSize: 12, color: colors.textSecondary, fontStyle: 'italic', marginTop: 2 },
  itemsCard: { marginHorizontal: spacing.lg, marginBottom: spacing.md, padding: spacing.md },
  itemRow: { flexDirection: 'row', alignItems: 'center', paddingVertical: spacing.xs },
  itemQty: { fontSize: 14, fontWeight: '600', color: colors.textSecondary, width: 30 },
  itemName: { flex: 1, fontSize: 14, color: colors.textPrimary },
  itemPrice: { fontSize: 14, fontWeight: '600', color: colors.textPrimary },
  totalRow: { flexDirection: 'row', justifyContent: 'space-between', borderTopWidth: 1, borderTopColor: colors.border, paddingTop: spacing.sm, marginTop: spacing.sm },
  totalLabel: { fontSize: 16, fontWeight: '700', color: colors.textPrimary },
  totalValue: { fontSize: 16, fontWeight: '700', color: colors.accent },
  addressCard: { marginHorizontal: spacing.lg, marginBottom: spacing.md, padding: spacing.md },
  addressText: { fontSize: 14, color: colors.textSecondary, lineHeight: 20 },
  noteText: { fontSize: 13, color: colors.textSecondary, fontStyle: 'italic', marginTop: spacing.xs },
});
