import type { SupabaseClient, RealtimeChannel } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';
import type { DBOrder, DBOrderStatusEvent } from '../models/SupabaseModels';

export type OrderUpdateHandler = (order: DBOrder) => void;

/**
 * React Native / TypeScript equivalent of the Swift `RealtimeService`.
 * Handles Supabase realtime subscriptions for orders and order status events.
 */
export class RealtimeService {
  private client: SupabaseClient;
  private ordersChannel: RealtimeChannel | null = null;
  private statusEventsChannel: RealtimeChannel | null = null;

  lastOrderUpdate: DBOrder | null = null;
  lastStatusEvent: DBOrderStatusEvent | null = null;

  constructor(client: SupabaseClient = supabase) {
    this.client = client;
  }

  /**
   * Subscribe to order changes.
   * Currently listens to all changes on the `orders` table and invokes the callback
   * with the latest row; you can later refine this with filters (e.g. by role/user).
   */
  subscribeToOrders(onUpdate: OrderUpdateHandler): void {
    this.unsubscribeFromOrders();

    this.ordersChannel = this.client
      .channel('orders-changes')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'orders',
        },
        payload => {
          const next = payload.new as DBOrder | null;
          if (!next) return;
          this.lastOrderUpdate = next;
          onUpdate(next);
        },
      )
      .subscribe();
  }

  /**
   * Subscribe to new order status events to drive live timelines.
   */
  subscribeToStatusEvents(onEvent: (event: DBOrderStatusEvent) => void): void {
    this.unsubscribeFromStatusEvents();

    this.statusEventsChannel = this.client
      .channel('order-status-events')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'order_status_events',
        },
        payload => {
          const evt = payload.new as DBOrderStatusEvent | null;
          if (!evt) return;
          this.lastStatusEvent = evt;
          onEvent(evt);
        },
      )
      .subscribe();
  }

  unsubscribeFromOrders(): void {
    if (this.ordersChannel) {
      this.ordersChannel.unsubscribe();
      this.ordersChannel = null;
    }
  }

  unsubscribeFromStatusEvents(): void {
    if (this.statusEventsChannel) {
      this.statusEventsChannel.unsubscribe();
      this.statusEventsChannel = null;
    }
  }

  /**
   * Convenience to fully tear down realtime when user logs out, etc.
   */
  unsubscribeAll(): void {
    this.unsubscribeFromOrders();
    this.unsubscribeFromStatusEvents();
  }
}

// Singleton instance to import elsewhere
export const realtimeService = new RealtimeService();

