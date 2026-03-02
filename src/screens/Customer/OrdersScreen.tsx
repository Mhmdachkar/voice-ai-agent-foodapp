import React, { useEffect } from 'react';
import {
  View,
  Text,
  FlatList,
  StyleSheet,
  ActivityIndicator,
  Pressable,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { useDataStore } from '../../state/DataStore';
import { useAuthStore } from '../../state/AuthStore';
import { useFeedbackStore } from '../../state/FeedbackStore';
import { colors, spacing, radii } from '../../theme/theme';
import { Card } from '../../theme/components/Card';
import { EmptyState } from '../../theme/components/EmptyState';
import type { Order, OrderStatus } from '../../models/Order';

const STATUS_COLORS: Record<OrderStatus, string> = {
  PLACED: colors.accent,
  ACCEPTED: colors.success,
  PREPARING: colors.warning,
  READY: colors.success,
  OUT_FOR_DELIVERY: colors.accent,
  DELIVERED: colors.success,
  CANCELED: colors.danger,
};

const STATUS_LABELS: Record<OrderStatus, string> = {
  PLACED: 'Placed',
  ACCEPTED: 'Accepted',
  PREPARING: 'Preparing',
  READY: 'Ready',
  OUT_FOR_DELIVERY: 'Out for Delivery',
  DELIVERED: 'Delivered',
  CANCELED: 'Canceled',
};

export const OrdersScreen: React.FC = () => {
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const { user, role } = useAuthStore();
  const { orders, isLoading, ordersForCustomer, refreshOrders } =
    useDataStore();
  const { getFeedbackForOrder, load: loadFeedback, isLoaded: feedbackLoaded } = useFeedbackStore();

  useEffect(() => {
    if (user && role) {
      refreshOrders(user.id, role);
    }
  }, [user, role, refreshOrders]);

  useEffect(() => {
    if (!feedbackLoaded) loadFeedback();
  }, [feedbackLoaded, loadFeedback]);

  const customerOrders =
    user && role === 'customer' ? ordersForCustomer(user.id) : orders;

  const renderTimeline = (order: Order) => {
    const sortedTimeline = [...order.timeline].sort(
      (a, b) =>
        new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime(),
    );

    return (
      <View style={styles.timeline}>
        {sortedTimeline.map((event, index) => {
          const isLast = index === sortedTimeline.length - 1;
          const date = new Date(event.timestamp);
          const timeStr = date.toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit',
          });

          return (
            <View key={event.id} style={styles.timelineEvent}>
              <View style={styles.timelineLeft}>
                <View
                  style={[
                    styles.timelineDot,
                    { backgroundColor: STATUS_COLORS[event.status] },
                  ]}
                />
                {!isLast && <View style={styles.timelineLine} />}
              </View>
              <View style={styles.timelineContent}>
                <Text style={styles.timelineStatus}>
                  {STATUS_LABELS[event.status]}
                </Text>
                <Text style={styles.timelineTime}>{timeStr}</Text>
                {event.note && (
                  <Text style={styles.timelineNote}>{event.note}</Text>
                )}
              </View>
            </View>
          );
        })}
      </View>
    );
  };

  const renderOrder = ({ item: order }: { item: Order }) => {
    const [expanded, setExpanded] = React.useState(false);

    return (
      <Card style={styles.orderCard}>
        <Pressable onPress={() => setExpanded(!expanded)}>
          <View style={styles.orderHeader}>
            <View>
              <Text style={styles.orderId}>Order #{order.id.slice(0, 8)}</Text>
              <Text style={styles.orderDate}>
                {new Date(order.createdAt).toLocaleDateString('en-US', {
                  month: 'short',
                  day: 'numeric',
                  year: 'numeric',
                })}
              </Text>
            </View>
            <View style={styles.orderHeaderRight}>
              <View
                style={[
                  styles.statusBadge,
                  { backgroundColor: STATUS_COLORS[order.status] },
                ]}
              >
                <Text style={styles.statusBadgeText}>
                  {STATUS_LABELS[order.status]}
                </Text>
              </View>
              <Text style={styles.orderTotal}>${order.total.toFixed(2)}</Text>
            </View>
          </View>

          {/* Item count */}
          <Text style={styles.itemCount}>
            {order.items.length} item{order.items.length !== 1 ? 's' : ''}
          </Text>

          {/* Driver info */}
          {order.driverName && (
            <Text style={styles.driverInfo}>Driver: {order.driverName}</Text>
          )}

          {/* Expand indicator */}
          <Text style={styles.expandText}>
            {expanded ? '▼ Hide Details' : '▶ Show Details'}
          </Text>
        </Pressable>

        {/* Expanded section */}
        {expanded && (
          <View style={styles.expandedSection}>
            {/* Order items */}
            <View style={styles.itemsSection}>
              <Text style={styles.sectionTitle}>Items</Text>
              {order.items.map((item, idx) => (
                <View key={idx} style={styles.orderItem}>
                  <Text style={styles.orderItemName}>
                    {item.quantity}x {item.menuItem.name}
                  </Text>
                  <Text style={styles.orderItemPrice}>
                    ${(item.menuItem.price * item.quantity).toFixed(2)}
                  </Text>
                </View>
              ))}
            </View>

            {/* Delivery address */}
            <View style={styles.addressSection}>
              <Text style={styles.sectionTitle}>Delivery Address</Text>
              <Text style={styles.addressText}>
                {order.deliveryAddress.street}
              </Text>
              <Text style={styles.addressText}>
                {order.deliveryAddress.city}, {order.deliveryAddress.state}{' '}
                {order.deliveryAddress.zip}
              </Text>
              {order.deliveryNotes && (
                <Text style={styles.deliveryNotes}>
                  Note: {order.deliveryNotes}
                </Text>
              )}
            </View>

            {/* Timeline */}
            <View style={styles.timelineSection}>
              <Text style={styles.sectionTitle}>Order Timeline</Text>
              {renderTimeline(order)}
            </View>

            {/* Feedback & Report buttons for delivered orders */}
            {order.status === 'DELIVERED' && (
              <View style={styles.feedbackRow}>
                {getFeedbackForOrder(order.id) ? (
                  <View style={styles.feedbackDone}>
                    <Text style={styles.feedbackDoneIcon}>{"\u2705"}</Text>
                    <Text style={styles.feedbackDoneText}>Feedback submitted</Text>
                  </View>
                ) : (
                  <Pressable
                    style={styles.feedbackBtn}
                    onPress={() => router.push({ pathname: '/customer/feedback' as any, params: { orderId: order.id } })}
                  >
                    <Text style={styles.feedbackBtnIcon}>{"\u2B50"}</Text>
                    <Text style={styles.feedbackBtnText}>Rate Order</Text>
                  </Pressable>
                )}
                <Pressable
                  style={styles.reportBtn}
                  onPress={() => router.push({ pathname: '/customer/report' as any, params: { orderId: order.id } })}
                >
                  <Text style={styles.reportBtnIcon}>{"\u26A0\uFE0F"}</Text>
                  <Text style={styles.reportBtnText}>Report Issue</Text>
                </Pressable>
              </View>
            )}
          </View>
        )}
      </Card>
    );
  };

  if (isLoading) {
    return (
      <View style={[styles.loadingContainer, { paddingTop: insets.top }]}>
        <ActivityIndicator size="large" color={colors.accent} />
      </View>
    );
  }

  if (customerOrders.length === 0) {
    return (
      <View style={[styles.container, { paddingTop: insets.top }]}>
        <EmptyState
          title="No orders yet"
          message="Your order history will appear here"
        />
      </View>
    );
  }

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      <Text style={styles.title}>Your Orders</Text>
      <FlatList
        data={customerOrders}
        keyExtractor={order => order.id}
        renderItem={renderOrder}
        contentContainerStyle={{ paddingBottom: spacing.xl }}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.background,
  },
  title: {
    fontSize: 24,
    fontWeight: '800',
    color: colors.textPrimary,
    paddingHorizontal: spacing.lg,
    paddingTop: spacing.lg,
    paddingBottom: spacing.md,
  },
  orderCard: {
    marginHorizontal: spacing.lg,
    marginBottom: spacing.md,
    padding: spacing.md,
  },
  orderHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: spacing.sm,
  },
  orderId: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.textPrimary,
  },
  orderDate: {
    fontSize: 13,
    color: colors.textSecondary,
    marginTop: 2,
  },
  orderHeaderRight: {
    alignItems: 'flex-end',
  },
  statusBadge: {
    paddingHorizontal: spacing.sm,
    paddingVertical: 4,
    borderRadius: radii.small,
  },
  statusBadgeText: {
    fontSize: 11,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  orderTotal: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.textPrimary,
    marginTop: spacing.xs,
  },
  itemCount: {
    fontSize: 13,
    color: colors.textSecondary,
    marginBottom: 4,
  },
  driverInfo: {
    fontSize: 13,
    color: colors.textSecondary,
    marginBottom: 4,
  },
  expandText: {
    fontSize: 12,
    fontWeight: '600',
    color: colors.accent,
    marginTop: spacing.sm,
  },
  expandedSection: {
    marginTop: spacing.md,
    paddingTop: spacing.md,
    borderTopWidth: 1,
    borderColor: colors.border,
  },
  sectionTitle: {
    fontSize: 14,
    fontWeight: '700',
    color: colors.textPrimary,
    marginBottom: spacing.sm,
  },
  itemsSection: {
    marginBottom: spacing.md,
  },
  orderItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 6,
  },
  orderItemName: {
    fontSize: 13,
    color: colors.textPrimary,
    flex: 1,
  },
  orderItemPrice: {
    fontSize: 13,
    fontWeight: '600',
    color: colors.textPrimary,
  },
  addressSection: {
    marginBottom: spacing.md,
  },
  addressText: {
    fontSize: 13,
    color: colors.textSecondary,
    lineHeight: 18,
  },
  deliveryNotes: {
    fontSize: 12,
    color: colors.textSecondary,
    fontStyle: 'italic',
    marginTop: 4,
  },
  timelineSection: {
    marginBottom: spacing.sm,
  },
  timeline: {
    marginLeft: spacing.xs,
  },
  timelineEvent: {
    flexDirection: 'row',
    marginBottom: spacing.sm,
  },
  timelineLeft: {
    width: 20,
    alignItems: 'center',
    marginRight: spacing.sm,
  },
  timelineDot: {
    width: 12,
    height: 12,
    borderRadius: 6,
  },
  timelineLine: {
    width: 2,
    flex: 1,
    backgroundColor: colors.border,
    marginTop: 4,
  },
  timelineContent: {
    flex: 1,
    paddingBottom: spacing.xs,
  },
  timelineStatus: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.textPrimary,
  },
  timelineTime: {
    fontSize: 12,
    color: colors.textSecondary,
    marginTop: 2,
  },
  timelineNote: {
    fontSize: 12,
    color: colors.textSecondary,
    fontStyle: 'italic',
    marginTop: 4,
  },
  feedbackRow: {
    flexDirection: 'row',
    gap: spacing.sm,
    marginTop: spacing.md,
    paddingTop: spacing.md,
    borderTopWidth: 1,
    borderTopColor: colors.border,
  },
  feedbackDone: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.success + '10',
    borderRadius: radii.small,
    paddingVertical: 10,
  },
  feedbackDoneIcon: {
    fontSize: 14,
    marginRight: spacing.xs,
  },
  feedbackDoneText: {
    fontSize: 13,
    fontWeight: '600',
    color: colors.success,
  },
  feedbackBtn: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.accent,
    borderRadius: radii.small,
    paddingVertical: 10,
  },
  feedbackBtnIcon: {
    fontSize: 14,
    marginRight: spacing.xs,
  },
  feedbackBtnText: {
    fontSize: 13,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  reportBtn: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.danger + '10',
    borderRadius: radii.small,
    paddingVertical: 10,
    borderWidth: 1,
    borderColor: colors.danger + '30',
  },
  reportBtnIcon: {
    fontSize: 14,
    marginRight: spacing.xs,
  },
  reportBtnText: {
    fontSize: 13,
    fontWeight: '700',
    color: colors.danger,
  },
});
